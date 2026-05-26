# app/jobs/weekly_ai_duplication_job.rb
#
# Orquestra a clonagem da semana e a chamada ao Gemini.
# Deve ser enfileirado após a submissão do weekly_feedback.
#
# Defesa em profundidade contra double-runs:
#   1. WeeklyFeedback#ai_status (sprint 010) — guard de re-entrância entre tentativas.
#   2. Rails.cache lock (SolidCache) — defesa curta dentro da mesma janela de 1h.
#   3. WeeklyDuplicationService.duplicate! — idempotência verdadeira (reconstrói
#      maps a partir dos treinos existentes em retry).
class WeeklyAiDuplicationJob < ApplicationJob
  queue_as :ai_processing

  retry_on GeminiClient::GeminiError, wait: :polynomially_longer, attempts: 3

  def perform(source_week_id, weekly_feedback_id)
    source_week = Week.includes(treinos: { exercicios: :sections }).find(source_week_id)
    personal = source_week.training_block.personal
    feedback = WeeklyFeedback.find(weekly_feedback_id)

    # Guard de permissões: respeita os 3 flags (admin global + admin per-coach + coach self-opt-out).
    unless personal.ai_runs?
      Rails.logger.info "[WeeklyAiDuplicationJob] skipping for week ##{source_week_id} — AI disabled for personal ##{personal.id}"
      return
    end

    # Guard de re-entrância via ai_status: previne 2º run cobrir o trabalho do 1º.
    # :failed continua passando (caso retry_on do ActiveJob ou retry manual da
    # sprint 011 — neste caso a idempotência do service garante que nenhum treino
    # duplicado é criado).
    if feedback.ai_processing? || feedback.ai_completed?
      Rails.logger.info "[WeeklyAiDuplicationJob] skipping — feedback ##{feedback.id} already #{feedback.ai_status}"
      return
    end

    lock_key = "weekly_ai_dup:#{source_week_id}"

    # Lock de curto prazo: protege contra reenfileiramentos do mesmo job dentro
    # de 1h (race de concorrência). Liberado em rescue para permitir retry.
    acquired = Rails.cache.write(lock_key, true, expires_in: 1.hour, unless_exist: true)
    return unless acquired

    feedback.update!(ai_status: :processing, ai_error_message: nil)

    # 1. Clonar a semana (idempotente: reusa se já há treinos created_by_ai).
    result = WeeklyDuplicationService.new(source_week).duplicate!
    new_week = result[:new_week]
    section_id_map = result[:section_id_map]
    treino_id_map = result[:treino_id_map]

    # Sprint 012: resolve prompt + 4 parâmetros guardrail (personal → admin → default).
    config = AiConfigResolver.for(personal)
    prompt = AiConfigResolver.interpolate(config[:system_prompt], config)

    # 2. Construir payload otimizado para o Gemini.
    payload_json = AiLoadPayloadBuilder.new(
      source_week, feedback, treino_id_map,
      target_goal: new_week.periodization_goal
    ).build

    # 3. Chamar o Gemini com o prompt resolvido.
    suggestions = GeminiClient.generate_load_suggestions(payload_json, system_prompt: prompt)

    # 4. Persistir sugestões com guardrail configurável (default 20%).
    AiSuggestionPersister.new(
      suggestions, section_id_map, treino_id_map,
      critical_threshold: config[:critical_delta_pct]
    ).persist!

    # 5. Marcar como completed e notificar o coach.
    feedback.update!(ai_status: :completed)
    notify_coach(source_week, new_week)
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "[WeeklyAiDuplicationJob] Record not found: #{e.message}"
    Rails.cache.delete(lock_key) if defined?(lock_key)
  rescue => e
    Rails.cache.delete(lock_key) if defined?(lock_key)
    # update_columns para evitar callbacks/validações em meio a rescue.
    if defined?(feedback) && feedback.present?
      feedback.update_columns(
        ai_status: WeeklyFeedback.ai_statuses[:failed],
        ai_error_message: e.message.to_s.first(500),
        updated_at: Time.current
      )
    end
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
