# app/jobs/weekly_ai_duplication_job.rb
#
# Orquestra a clonagem da semana e a chamada ao Gemini.
# Deve ser enfileirado após a submissão do weekly_feedback.
# Protegido contra double-run via Rails.cache lock (SolidCache).
class WeeklyAiDuplicationJob < ApplicationJob
  queue_as :ai_processing

  retry_on GeminiClient::GeminiError, wait: :polynomially_longer, attempts: 3

  def perform(source_week_id, weekly_feedback_id)
    lock_key = "weekly_ai_dup:#{source_week_id}"

    # Idempotency guard: se o job já está rodando ou rodou com sucesso, para.
    acquired = Rails.cache.write(lock_key, true, expires_in: 1.hour, unless_exist: true)
    return unless acquired

    source_week = Week.includes(treinos: { exercicios: :sections }).find(source_week_id)
    weekly_feedback = WeeklyFeedback.find(weekly_feedback_id)

    # 1. Clonar a semana.
    result = WeeklyDuplicationService.new(source_week).duplicate!
    new_week = result[:new_week]
    section_id_map = result[:section_id_map]

    # 2. Construir payload otimizado para o Gemini.
    # Usa o periodization_goal da NOVA semana (objetivo definido pelo coach para a próxima semana),
    # não da semana concluída. Fallback para "maintenance" se não definido.
    treino_id_map = result[:treino_id_map]
    payload_json = AiLoadPayloadBuilder.new(
      source_week, weekly_feedback, treino_id_map,
      target_goal: new_week.periodization_goal
    ).build

    # 3. Chamar o Gemini.
    suggestions = GeminiClient.generate_load_suggestions(payload_json)

    # 4. Persistir sugestões com guardrail de 20%.
    AiSuggestionPersister.new(suggestions, section_id_map, treino_id_map).persist!

    # 5. Notificar o coach que há uma semana aguardando revisão.
    notify_coach(source_week, new_week)
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "[WeeklyAiDuplicationJob] Record not found: #{e.message}"
    Rails.cache.delete(lock_key) # libera lock se o registro não existe
  rescue => e
    Rails.cache.delete(lock_key) # libera lock para permitir retry
    raise
  end

  private

  def notify_coach(source_week, new_week)
    personal = source_week.training_block.personal
    aluno = source_week.training_block.aluno

    personal.user.notifications.create!(
      notification_type: :coach_review_pending,
      payload: {
        week_id: new_week.id,
        aluno_id: aluno.id,
        aluno_name: aluno.user.name,
        message: "A semana #{new_week.week_number} de #{aluno.user.name} está aguardando sua revisão."
      }
    )
  end
end
