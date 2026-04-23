# app/controllers/api/v1/coach/treinos_controller.rb
class Api::V1::Coach::TreinosController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_admin_or_coach!
  before_action :set_and_authorize_treino

  # POST /api/v1/coach/treinos/:id/publish
  # Alterna o status do treino entre draft e published.
  # Usado quando o coach quer publicar manualmente (sem fluxo de IA).
  def publish
    case @treino.status
    when "draft"
      @treino.published!
      render json: { status: "published" }
    when "published"
      @treino.draft!
      render json: { status: "draft" }
    when "in_progress", "completed"
      # Coach despublica um treino em andamento/concluído: apaga dados do aluno e volta para draft
      ActiveRecord::Base.transaction do
        Section.joins(exercicio: :treino)
               .where(treinos: { id: @treino.id })
               .update_all(feito: false, actual_load: nil, actual_rpe: nil)
        @treino.update!(status: :draft, started_at: nil, finished_at: nil)
      end
      render json: { status: "draft" }
    else
      render json: { error: "Não é possível alterar o status de um treino #{@treino.status}." },
             status: :unprocessable_entity
    end
  end

  # GET /api/v1/coach/treinos/:id/review
  # Retorna o treino em draft com sugestões da IA por section e a observação geral.
  def review
    render json: {
      treino_id: @treino.id,
      treino_name: @treino.name,
      treino_day: @treino.day,
      status: @treino.status,
      ai_observation: @treino.ai_observation,
      exercicios: build_exercicios_diff
    }
  end

  # POST /api/v1/coach/treinos/:id/approve
  # Aprova as sugestões da IA para o treino inteiro.
  # Aceita `sections` array com overrides opcionais por section.
  # Após aprovação, o treino é publicado e as sugestões destruídas.
  def approve
    overrides = build_overrides_map

    ActiveRecord::Base.transaction do
      @treino.exercicios.includes(sections: :ai_load_suggestions).each do |exercicio|
        exercicio.sections.each do |section|
          suggestion = section.ai_load_suggestions.pending.order(created_at: :desc).first
          next unless suggestion

          final_load = overrides[section.id.to_s] || suggestion.suggested_load
          section.update!(carga: final_load)
          suggestion.approved!
        end
      end

      @treino.published!
      AiLoadSuggestion.for_treino(@treino.id).destroy_all
    end

    render json: {
      message: "Treino aprovado e publicado.",
      treino_id: @treino.id,
      status: "published"
    }
  end

  private

  def set_and_authorize_treino
    @treino = Treino.joins(week: { training_block: :personal })
                    .where(training_blocks: { personal_id: @current_user.personal.id })
                    .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Treino não encontrado ou acesso negado." }, status: :not_found
  end

  def build_overrides_map
    # Params: { sections: [{id: "uuid", load: 100.0}, ...] }
    (params[:sections] || []).each_with_object({}) do |s, map|
      map[s[:id].to_s] = s[:load].to_f if s[:id].present? && s[:load].present?
    end
  end

  def build_exercicios_diff
    @treino.exercicios.includes(sections: :ai_load_suggestions).map do |exercicio|
      {
        exercicio_id: exercicio.id,
        exercicio_name: exercicio.name,
        sections: build_sections_diff(exercicio)
      }
    end
  end

  def build_sections_diff(exercicio)
    exercicio.sections.map do |section|
      suggestion = section.ai_load_suggestions.order(created_at: :desc).first
      {
        section_id: section.id,
        reps: section.reps,
        series: section.series,
        load_unit: section.load_unit,
        prescribed_load: section.carga,
        suggested_load: suggestion&.suggested_load,
        suggestion_id: suggestion&.id,
        suggestion_status: suggestion&.status,
        critical: suggestion&.critical || false
      }
    end
  end
end
