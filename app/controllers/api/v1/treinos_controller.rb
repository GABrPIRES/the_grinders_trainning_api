class Api::V1::TreinosController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_admin_or_coach!, except: [ :show, :start, :finish, :pause ]
  before_action :set_week, only: [ :index, :create ]
  before_action :set_treino, only: [ :show, :update, :destroy, :duplicate ]
  before_action :set_treino_public, only: [ :start, :finish, :pause ]
  before_action :authorize_treino_access!, only: [ :start, :finish, :pause ]

  # GET /api/v1/weeks/:week_id/treinos
  def index
    @treinos = @week.treinos.order(day: :asc)
    render json: @treinos.as_json(include: :exercicios)
  end

  # GET /api/v1/treinos/:id
  def show
    # FORÇA o envio dos IDs e dados aninhados ignorando serializers parciais
    render json: @treino.as_json(
      include: {
        exercicios: {
          include: :sections
        }
      }
    )
  end

  # POST /api/v1/weeks/:week_id/treinos
  def create
    @treino = @week.treinos.build(treino_params)
    # Se o treino pertence a uma week, e a week a um bloco, e o bloco ao personal...
    # Ajuste aqui se sua associação for diferente. Geralmente @week.training_block.personal_id
    @treino.personal_id = @current_user.personal.id

    # Validação de data
    if @week.start_date.present? && @week.end_date.present? && @treino.day.present?
      treino_day = @treino.day.to_date
      unless treino_day.between?(@week.start_date, @week.end_date)
        return render json: { errors: [ "A data está fora da semana." ] }, status: :unprocessable_entity
      end
    end

    if @treino.save
      render json: @treino, include: { exercicios: { include: :sections } }, status: :created
    else
      render json: @treino.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/treinos/:id
  def update
    if @treino.update(treino_params)
      # Retorna o treino atualizado com os IDs corretos para o frontend sincronizar
      render json: @treino.as_json(include: { exercicios: { include: :sections } })
    else
      render json: @treino.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/treinos/:id
  def destroy
    @treino.destroy
    render json: { message: "Treino deletado com sucesso" }, status: :ok
  end

  # POST /api/v1/treinos/:id/duplicate
  def duplicate
    # Busca a semana de destino (garantindo que pertence ao coach logado)
    destination_week = Week.joins(training_block: :personal)
                           .where(training_blocks: { personal_id: @current_user.personal.id })
                           .find(duplication_params[:week_id])

    new_treino = nil

    Treino.transaction do
      # 1. Duplica o objeto treino base (ignora ID, created_at, etc)
      new_treino = @treino.dup

      # 2. Atualiza com os novos dados
      new_treino.week = destination_week
      new_treino.name = duplication_params[:name]
      new_treino.day = duplication_params[:day]

      # Garante que copia a descrição SE ela existir, senão ignora
      if @treino.respond_to?(:description)
        new_treino.description = @treino.description
      end

      # Validação de data (opcional, mas bom ter)
      if destination_week.start_date.present? && destination_week.end_date.present?
        target_date = new_treino.day.to_date
        # Permite salvar mesmo fora da data, mas poderia lançar erro aqui se quisesse ser rígido
      end

      new_treino.save!

      # 3. Copia Exercícios e Sections
      @treino.exercicios.includes(:sections).each do |source_exercicio|
        new_exercicio = new_treino.exercicios.create!(name: source_exercicio.name)

        source_exercicio.sections.each do |source_section|
          # Copia atributos da section ignorando IDs
          sec_attrs = source_section.attributes.except("id", "exercicio_id", "created_at", "updated_at")
          sec_attrs["feito"] = false # Reseta o status de feito
          # Limpa o PR copiado para recalcular ou manter histórico limpo (opcional, aqui mantivemos a cópia)

          new_exercicio.sections.create!(sec_attrs)
        end
      end
    end

    render json: new_treino, include: { exercicios: { include: :sections } }, status: :created

  rescue ActiveRecord::RecordNotFound
    render json: { error: "Semana de destino não encontrada ou acesso negado." }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_week
    @week = Week.joins(training_block: :personal)
                .where(training_blocks: { personal_id: @current_user.personal.id })
                .find(params[:week_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Semana não encontrada." }, status: :not_found
  end

  # Usado por ações exclusivas do coach (update, destroy, duplicate).
  def set_treino
    @treino = @current_user.personal.treinos.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Treino não encontrado" }, status: :not_found
  end

  # Usado por start/finish — acessíveis pelo aluno.
  # A autorização real é feita por authorize_treino_access!.
  def set_treino_public
    @treino = Treino.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Treino não encontrado" }, status: :not_found
  end

  def treino_params
    params.require(:treino).permit(
      :name,
      :day,
      exercicios_attributes: [
        :id,
        :name,
        :_destroy, # <--- ESSENCIAL PARA DELETAR
        sections_attributes: [
          :id,
          :carga,
          :series,
          :reps,
          :equip,
          :rpe,
          :pr,
          :feito,
          :load_unit,
          :_destroy # <--- ESSENCIAL PARA DELETAR
        ]
      ]
    )
  end

  def duplication_params
    params.require(:duplication).permit(:week_id, :name, :day)
  end

  public

  # POST /api/v1/treinos/:id/start
  # Aluno inicia o treino. Só funciona se o treino está published.
  def start
    unless @treino.published?
      return render json: { error: "Este treino não está disponível para início." }, status: :unprocessable_entity
    end

    @treino.update!(started_at: Time.current, status: :in_progress)
    render json: { message: "Treino iniciado.", started_at: @treino.started_at }
  end

  # POST /api/v1/treinos/:id/pause
  # Aluno cancela o início do treino e volta para published.
  # Se houver dados registrados nas sections, exige confirmação (force: true).
  def pause
    unless @treino.in_progress?
      return render json: { error: "Este treino não está em andamento." }, status: :unprocessable_entity
    end

    has_data = Section.joins(exercicio: :treino)
                      .where(treinos: { id: @treino.id })
                      .where("sections.feito = TRUE OR sections.actual_load IS NOT NULL OR sections.actual_rpe IS NOT NULL")
                      .exists?

    force = ActiveModel::Type::Boolean.new.cast(params[:force])

    if has_data && !force
      return render json: {
        has_data: true,
        message: "Você registrou dados neste treino. Ao cancelar, eles serão perdidos."
      }, status: :conflict
    end

    ActiveRecord::Base.transaction do
      Section.joins(exercicio: :treino)
             .where(treinos: { id: @treino.id })
             .update_all(feito: false, actual_load: nil, actual_rpe: nil)

      @treino.update!(status: :published, started_at: nil)
    end

    render json: { message: "Treino cancelado. Você pode iniciá-lo novamente quando quiser." }
  end

  # POST /api/v1/treinos/:id/finish
  # Aluno finaliza o treino. Só funciona se está in_progress.
  # Dispara verificação de formulário semanal caso seja o último treino da semana.
  def finish
    unless @treino.in_progress?
      return render json: { error: "Este treino não está em andamento." }, status: :unprocessable_entity
    end

    @treino.update!(finished_at: Time.current, status: :completed)

    NotificationService.on_workout_completed(treino: @treino, aluno_user: @current_user)

    week = @treino.week
    feedback_payload = if week.feedback_available?(@current_user.aluno)
      {
        feedback_form_available: true,
        week_id: week.id,
        deadline_at: WeekFeedbackAvailabilityService.new(@current_user.aluno).pending_week&.dig(:deadline_at)
      }
    else
      { feedback_form_available: false }
    end

    render json: {
      message: "Treino finalizado.",
      finished_at: @treino.finished_at,
      duration_seconds: @treino.duration_seconds
    }.merge(feedback_payload)
  end

  private

  # Verifica que o usuário logado é o aluno dono deste treino.
  def authorize_treino_access!
    aluno = @treino.week&.training_block&.aluno

    unless @current_user.aluno? && @current_user.aluno&.id == aluno&.id
      render json: { error: "Não autorizado." }, status: :unauthorized
    end
  end
end
