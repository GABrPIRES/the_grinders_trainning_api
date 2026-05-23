class Api::V1::Coach::WeeklyFeedbacksController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_coach!

  # GET /api/v1/coach/weeks/:week_id/weekly_feedback
  # Retorna o feedback respondido pelo aluno desta semana (ou 404 se ainda não respondido).
  # Authorize: coach precisa ser o personal do training_block dessa week.
  def show
    week = Week.joins(training_block: :personal)
               .where(training_blocks: { personal_id: @current_user.personal.id })
               .find(params[:week_id])

    feedback = WeeklyFeedback.find_by(week: week, aluno: week.training_block.aluno)
    if feedback
      render json: serialize(feedback)
    else
      render json: { error: "Formulário ainda não respondido." }, status: :not_found
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Semana não encontrada ou acesso negado." }, status: :not_found
  end

  # DELETE /api/v1/coach/weekly_feedbacks/:id
  # Hard delete. Coach só pode deletar feedback de aluno seu (verificado via join no
  # personal_id). Não toca em weeks.expired_at — regra da sprint 004 preservada: semana
  # já expirada continua expirada (aluno não volta a ver formulário).
  #
  # Cleanup associado (extensão sprint 006, refinado na sprint 010):
  #   - Remove os treinos created_by_ai:true que ainda estão em :draft na new_week
  #     (target_week_of). Treinos que o coach já promoveu para published/in_progress/
  #     completed ficam intactos — coach considerou-os "seus".
  #   - Libera o lock cache do WeeklyAiDuplicationJob para permitir nova rodada
  #     quando o aluno responder de novo (defesa em profundidade, ai_status já
  #     garante isso).
  #   - Tudo em transação: se cleanup falha, feedback não é deletado.
  def destroy
    feedback = WeeklyFeedback.joins(week: { training_block: :personal })
                             .where(training_blocks: { personal_id: @current_user.personal.id })
                             .find(params[:id])

    source_week = feedback.week
    ActiveRecord::Base.transaction do
      feedback.destroy!
      cleanup_ai_artifacts(source_week)
    end

    render json: { message: "Formulário removido." }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Formulário não encontrado ou acesso negado." }, status: :not_found
  end

  private

  def cleanup_ai_artifacts(source_week)
    target_week = WeeklyDuplicationService.target_week_of(source_week)
    target_week&.treinos&.where(created_by_ai: true, status: :draft)&.destroy_all
    Rails.cache.delete("weekly_ai_dup:#{source_week.id}")
  end

  def serialize(feedback)
    {
      id: feedback.id,
      week_id: feedback.week_id,
      aluno_id: feedback.aluno_id,
      sleep_level: feedback.sleep_level,
      stress_level: feedback.stress_level,
      diet_level: feedback.diet_level,
      body_weight: feedback.body_weight,
      training_desire: feedback.training_desire,
      general_evaluation: feedback.general_evaluation,
      created_at: feedback.created_at
    }
  end

  def authorize_coach!
    return if @current_user.personal?
    render json: { error: "Acesso restrito a coaches." }, status: :forbidden
  end
end
