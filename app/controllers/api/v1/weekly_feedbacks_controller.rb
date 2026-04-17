# app/controllers/api/v1/weekly_feedbacks_controller.rb
class Api::V1::WeeklyFeedbacksController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_aluno!

  # GET /api/v1/weekly_feedbacks/pending
  # Retorna se o aluno logado tem formulário semanal pendente.
  def pending
    result = WeekFeedbackAvailabilityService.new(@current_user.aluno).pending_week

    if result
      render json: {
        pending: true,
        week_id: result[:week_id],
        deadline_at: result[:deadline_at],
        incomplete_treinos: result[:incomplete_treinos]
      }
    else
      render json: { pending: false }
    end
  end

  # POST /api/v1/weekly_feedbacks
  # Cria o feedback da semana. Dispara o job de duplicação + IA se todos os treinos estão completed.
  def create
    week = Week.joins(training_block: :aluno)
               .where(training_blocks: { aluno_id: @current_user.aluno.id })
               .find(feedback_params[:week_id])

    unless week.feedback_enabled?
      return render json: { error: "O formulário semanal está desativado para esta semana." },
                    status: :unprocessable_entity
    end

    # Permite envio se o último treino foi concluído OU se é domingo >= 12h (SP).
    last_treino = week.treinos.order(day: :desc, created_at: :desc).first
    sp_now = ActiveSupport::TimeZone["America/Sao_Paulo"].now
    sunday_noon = sp_now.sunday? && sp_now.hour >= 12
    unless last_treino&.completed? || sunday_noon
      return render json: { error: "Finalize o último treino da semana antes de enviar o formulário." },
                    status: :unprocessable_entity
    end

    if WeeklyFeedback.exists?(week: week, aluno: @current_user.aluno)
      return render json: { error: "Formulário desta semana já foi enviado." }, status: :unprocessable_entity
    end

    feedback = WeeklyFeedback.new(
      feedback_params.except(:week_id).merge(week: week, aluno: @current_user.aluno)
    )

    if feedback.save
      WeeklyAiDuplicationJob.perform_later(week.id, feedback.id)
      render json: { message: "Formulário enviado! A próxima semana será gerada em breve.", id: feedback.id },
             status: :created
    else
      render json: feedback.errors, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Semana não encontrada." }, status: :not_found
  end

  # POST /api/v1/weekly_feedbacks/:week_id/snooze
  # Aluno escolheu "responder depois". Registra snooze e agenda lembrete.
  def snooze
    week = Week.joins(training_block: :aluno)
               .where(training_blocks: { aluno_id: @current_user.aluno.id })
               .find(params[:week_id])

    if WeeklyFeedback.exists?(week: week, aluno: @current_user.aluno)
      return render json: { error: "Formulário desta semana já foi enviado." }, status: :unprocessable_entity
    end

    week.update!(snoozed_at: Time.current)

    @current_user.notifications.create!(
      notification_type: :feedback_form_reminder,
      payload: {
        week_id: week.id,
        message: "Não esqueça de preencher o formulário semanal!",
        snoozed: true
      }
    )

    render json: { message: "Anotado! Te lembraremos mais tarde." }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Semana não encontrada." }, status: :not_found
  end

  private

  def feedback_params
    params.require(:weekly_feedback).permit(
      :week_id, :sleep_level, :stress_level, :diet_level,
      :body_weight, :training_desire, :general_evaluation
    )
  end
end
