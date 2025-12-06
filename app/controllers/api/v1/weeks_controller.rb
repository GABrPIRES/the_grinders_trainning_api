class Api::V1::WeeksController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_coach!
  before_action :set_week, only: [:show, :duplicate]

  # GET /api/v1/weeks/:id
  def show
    render json: @week, include: { treinos: { include: :exercicios } }
  end

  # POST /api/v1/weeks/:id/duplicate
  def duplicate
    # O frontend envia { target_week_id: "uuid..." }
    target_week_id = params[:target_week_id]

    if target_week_id.blank?
      return render json: { error: 'ID da semana de destino é obrigatório.' }, status: :unprocessable_entity
    end

    # Busca a semana de destino garantindo que pertence a um aluno deste coach (segurança)
    # Isso permite copiar para QUALQUER aluno do mesmo coach
    target_week = Week.joins(training_block: { aluno: :personal })
                      .where(personals: { id: @current_user.personal.id })
                      .find_by(id: target_week_id)

    if target_week.nil?
      return render json: { error: 'Semana de destino não encontrada ou sem permissão.' }, status: :not_found
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
          description: source_treino.description,
          personal_id: @current_user.personal.id # Se sua tabela ainda usa isso
        )

        # Copia Exercícios e Séries
        source_treino.exercicios.order(:created_at).each do |source_ex|
          new_ex = new_treino.exercicios.create!(name: source_ex.name)

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

    render json: { message: 'Semana duplicada com sucesso!', target_week_id: target_week.id }, status: :ok

  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def set_week
    @week = Week.joins(training_block: :personal)
                .where(training_blocks: { personal_id: @current_user.personal.id })
                .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Semana não encontrada.' }, status: :not_found
  end

  def authorize_coach!
    return if @current_user.personal?
    render json: { error: 'Acesso restrito a coaches.' }, status: :forbidden
  end
end