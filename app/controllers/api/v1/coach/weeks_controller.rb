# app/controllers/api/v1/coach/weeks_controller.rb
class Api::V1::Coach::WeeksController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_admin_or_coach!
  before_action :set_and_authorize_week

  # GET /api/v1/coach/weeks/:id/review
  # Retorna a semana em draft com sugestões da IA agrupadas por treino.
  def review
    treinos_data = @week.treinos.draft.includes(exercicios: { sections: :ai_load_suggestions }).map do |treino|
      {
        treino_id: treino.id,
        treino_name: treino.name,
        treino_day: treino.day,
        ai_observation: treino.ai_observation,
        pending_count: treino.ai_load_suggestions.pending.count,
        exercicios: build_exercicios_diff(treino)
      }
    end

    render json: {
      week_id: @week.id,
      week_number: @week.week_number,
      periodization_goal: @week.periodization_goal,
      treinos: treinos_data
    }
  end

  # POST /api/v1/coach/weeks/:id/approve_all
  # Aprova todos os treinos draft da semana, aplicando overrides por section se enviados.
  # Params: { treinos: [{ treino_id:, sections: [{id:, load:}] }] }
  def approve_all
    overrides_by_treino = build_overrides_by_treino

    approved_ids = []
    ActiveRecord::Base.transaction do
      @week.treinos.draft.includes(exercicios: { sections: :ai_load_suggestions }).each do |treino|
        section_overrides = overrides_by_treino[treino.id.to_s] || {}

        treino.exercicios.each do |exercicio|
          exercicio.sections.each do |section|
            suggestion = section.ai_load_suggestions.pending.order(created_at: :desc).first
            next unless suggestion

            final_load = section_overrides[section.id.to_s] || suggestion.suggested_load
            section.update!(carga: final_load)
            suggestion.approved!
          end
        end

        treino.published!
        AiLoadSuggestion.for_treino(treino.id).destroy_all
        approved_ids << treino.id
      end
    end

    # Notifica aluno se todos os treinos da semana foram publicados (incluindo os que já estavam)
    if approved_ids.any? && @week.treinos.draft.none?
      WeekPublishHandler.expire_prior_weeks(@week)
      NotificationService.on_week_published(week: @week, coach_user: @current_user)
    end

    render json: { message: "#{approved_ids.size} treinos aprovados e publicados.", approved_treino_ids: approved_ids }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_and_authorize_week
    @week = Week.joins(training_block: :personal)
                .where(training_blocks: { personal_id: @current_user.personal.id })
                .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Semana não encontrada." }, status: :not_found
  end

  def build_exercicios_diff(treino)
    treino.exercicios.map do |exercicio|
      {
        exercicio_id: exercicio.id,
        exercicio_name: exercicio.name,
        sections: build_sections_diff(exercicio)
      }
    end
  end

  def build_overrides_by_treino
    # Params: { treinos: [{ treino_id: "uuid", sections: [{id: "uuid", load: 100.0}] }] }
    (params[:treinos] || []).each_with_object({}) do |t, map|
      treino_id = t[:treino_id].to_s
      map[treino_id] = (t[:sections] || []).each_with_object({}) do |s, smap|
        smap[s[:id].to_s] = s[:load].to_f if s[:id].present? && s[:load].present?
      end
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
