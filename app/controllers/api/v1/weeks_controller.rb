class Api::V1::WeeksController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_coach!
  before_action :set_week, only: [ :show, :update, :duplicate, :toggle_feedback ]

  # POST /api/v1/training_blocks/:training_block_id/weeks
  def create
    block = TrainingBlock.joins(:personal)
                         .where(personals: { id: @current_user.personal.id })
                         .find(params[:training_block_id])

    last_number = block.weeks.maximum(:week_number) || 0
    last_end_date = block.weeks.order(:week_number).last&.end_date

    week = block.weeks.create!(
      week_number: last_number + 1,
      start_date: last_end_date ? last_end_date + 1 : nil,
      end_date: last_end_date ? last_end_date + 7 : nil
    )

    render json: week, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Bloco não encontrado." }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # GET /api/v1/weeks/:id
  def show
    treinos_data = @week.treinos.order(:day).map do |treino|
      treino.as_json.merge(
        has_pending_ai_suggestions: AiLoadSuggestion.for_treino(treino.id).pending.exists?,
        has_ai_observation: treino.ai_observation.present?
      )
    end

    # Status da IA que rodou para gerar esta semana (sprint 011).
    # Lê o feedback da semana ANTERIOR, que é o gatilho da duplicação.
    prev_feedback = previous_week_feedback_for(@week)

    render json: @week.as_json.merge(
      treinos: treinos_data,
      feedback_enabled: @week.feedback_enabled,
      previous_week_feedback: prev_feedback && {
        id: prev_feedback.id,
        ai_status: prev_feedback.ai_status,
        ai_error_message: prev_feedback.ai_error_message
      }
    )
  end

  # POST /api/v1/weeks/:id/duplicate
  def duplicate
    # O frontend envia { target_week_id: "uuid..." }
    target_week_id = params[:target_week_id]

    if target_week_id.blank?
      return render json: { error: "ID da semana de destino é obrigatório." }, status: :unprocessable_entity
    end

    # Busca a semana de destino garantindo que pertence a um aluno deste coach (segurança)
    # Isso permite copiar para QUALQUER aluno do mesmo coach
    target_week = Week.joins(training_block: { aluno: :personal })
                      .where(personals: { id: @current_user.personal.id })
                      .find_by(id: target_week_id)

    if target_week.nil?
      return render json: { error: "Semana de destino não encontrada ou sem permissão." }, status: :not_found
    end

    ActiveRecord::Base.transaction do
      # Lógica de Datas:
      # Calculamos o "offset" (deslocamento) da semana de destino em relação à origem
      # Se a semana destino não tiver data definida, usamos hoje como base.
      base_date_source = @week.start_date || Date.today
      base_date_target = target_week.start_date || Date.today

      # Itera sobre os treinos da semana original
      @week.treinos.includes(exercicios: :sections).each do |source_treino|
        # Calcula quantos dias após o início da semana o treino original ocorreu
        days_diff = (source_treino.day.to_date - base_date_source).to_i

        # Aplica esse deslocamento na semana de destino
        new_date = base_date_target + days_diff.days

        # Cria o treino na semana nova
        new_treino = target_week.treinos.create!(
          name: source_treino.name,
          day: new_date,
          personal_id: @current_user.personal.id # Se sua tabela ainda usa isso
        )

        # Copia Exercícios e Séries (preserva position, coach_comment e video_link do source).
        # observation NÃO é copiada (campo do aluno — começa nil na nova semana).
        source_treino.exercicios.order(:position, :created_at).each do |source_ex|
          new_ex = new_treino.exercicios.create!(
            name: source_ex.name,
            position: source_ex.position,
            coach_comment: source_ex.coach_comment,
            video_link: source_ex.video_link
          )

          source_ex.sections.order(:created_at).each do |sec|
            new_ex.sections.create!(
              carga: sec.carga,
              load_unit: sec.load_unit,
              series: sec.series,
              reps: sec.reps,
              equip: sec.equip,
              rpe: sec.rpe,
              pr: sec.pr,
              feito: false # Importante: reseta o status
            )
          end
        end
      end
    end

    render json: { message: "Semana duplicada com sucesso!", target_week_id: target_week.id }, status: :ok

  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # PATCH /api/v1/weeks/:id
  # Coach define o objetivo de periodização da semana.
  def update
    if @week.update(week_update_params)
      render json: {
        periodization_goal: @week.periodization_goal,
        week_number: @week.week_number,
        start_date: @week.start_date,
        end_date: @week.end_date
      }
    else
      render json: @week.errors, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/weeks/:id/toggle_feedback
  # Coach ativa ou desativa o formulário semanal para esta semana.
  def toggle_feedback
    @week.update!(feedback_enabled: !@week.feedback_enabled)
    render json: { feedback_enabled: @week.feedback_enabled }
  end

  private

  def week_update_params
    params.require(:week).permit(:periodization_goal, :week_number, :start_date, :end_date)
  end

  def set_week
    @week = Week.joins(training_block: :personal)
                .where(training_blocks: { personal_id: @current_user.personal.id })
                .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Semana não encontrada." }, status: :not_found
  end

  def authorize_coach!
    return if @current_user.personal?
    render json: { error: "Acesso restrito a coaches." }, status: :forbidden
  end

  # Feedback da semana anterior do mesmo bloco (gatilho da duplicação que
  # produziu esta semana). Pode ser nil se for week_number 1 ou se o aluno
  # ainda não respondeu.
  def previous_week_feedback_for(week)
    block = week.training_block
    prev_week = block.weeks.find_by(week_number: week.week_number - 1)
    return nil unless prev_week
    WeeklyFeedback.find_by(week_id: prev_week.id, aluno_id: block.aluno_id)
  end
end
