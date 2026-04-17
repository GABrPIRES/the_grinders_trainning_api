# app/controllers/api/v1/coach/sections_controller.rb
class Api::V1::Coach::SectionsController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_admin_or_coach!
  before_action :set_and_authorize_section

  # POST /api/v1/coach/sections/:id/approve
  # Aprova a sugestão da IA para esta section.
  # Aceita `override_load` opcional: coach pode ajustar o valor antes de aprovar.
  # Quando a última suggestion pending do treino é resolvida, o treino é publicado
  # automaticamente pelo callback no model AiLoadSuggestion.
  def approve
    suggestion = @section.ai_load_suggestions.pending.order(created_at: :desc).first

    unless suggestion
      return render json: { error: "Não há sugestão pendente para esta seção." }, status: :unprocessable_entity
    end

    final_load = params.dig(:section, :override_load)&.to_f || suggestion.suggested_load

    ActiveRecord::Base.transaction do
      @section.update!(carga: final_load)
      suggestion.approved!
    end

    render json: {
      message: "Sugestão aprovada.",
      section_id: @section.id,
      final_load: final_load,
      treino_status: @section.exercicio.treino.reload.status
    }
  end

  # POST /api/v1/coach/sections/:id/reject
  # Rejeita a sugestão da IA. A carga permanece como estava (herdada da semana anterior).
  # Coach pode opcionalmente passar `override_load` para definir um valor manual.
  def reject
    suggestion = @section.ai_load_suggestions.pending.order(created_at: :desc).first

    unless suggestion
      return render json: { error: "Não há sugestão pendente para esta seção." }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      if (override_load = params.dig(:section, :override_load)&.to_f)
        @section.update!(carga: override_load)
      end
      suggestion.rejected!
    end

    render json: {
      message: "Sugestão rejeitada.",
      section_id: @section.id,
      final_load: @section.reload.carga,
      treino_status: @section.exercicio.treino.reload.status
    }
  end

  private

  def set_and_authorize_section
    @section = Section.joins(exercicio: { treino: { week: { training_block: :personal } } })
                      .where(training_blocks: { personal_id: @current_user.personal.id })
                      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Seção não encontrada ou acesso negado." }, status: :not_found
  end
end
