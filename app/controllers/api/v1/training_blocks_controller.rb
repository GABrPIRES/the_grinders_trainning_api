# app/controllers/api/v1/training_blocks_controller.rb
class Api::V1::TrainingBlocksController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_coach!
  before_action :set_aluno, only: [:index, :create]
  before_action :set_training_block, only: [:show, :update, :destroy]

  # ... (actions index, show, destroy permanecem iguais) ...
  def index
    @aluno = @current_user.personal.alunos.find(params[:aluno_id])
    @training_blocks = @aluno.training_blocks.order(start_date: :desc, created_at: :desc)
    render json: @training_blocks
  end

  def show
    render json: @training_block, include: { weeks: { include: :treinos } }
  end

  def destroy
    @training_block.destroy
    render json: { message: 'Bloco de treino deletado com sucesso.' }, status: :ok
  end


  # POST /api/v1/alunos/:aluno_id/training_blocks
  def create
    @training_block = @aluno.training_blocks.build(training_block_params)
    @training_block.personal = @current_user.personal

    if @training_block.save
      create_weeks_for_block(@training_block)
      calculate_and_save_week_dates(@training_block) # <-- NOVA LÓGICA
      render json: @training_block, status: :created
    else
      render json: @training_block.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/training_blocks/:id
  def update
    # Atribui os novos parâmetros
    @training_block.assign_attributes(training_block_params)

    # Verifica se houve mudança na duração ou na data de início
    # (Ou simplesmente forçamos o recálculo sempre, que é mais seguro)
    
    if @training_block.save
      # 1. Cria ou remove semanas conforme a nova duração
      update_weeks_for_block(@training_block)
      
      # 2. [CORREÇÃO] Recalcula as datas de TODAS as semanas (garante que as novas tenham data)
      calculate_and_save_week_dates(@training_block)
      
      render json: @training_block
    else
      render json: @training_block.errors, status: :unprocessable_entity
    end
  end

  private

  # ... (set_aluno, set_training_block, training_block_params, create_weeks_for_block, update_weeks_for_block permanecem iguais) ...
  def set_aluno
    @aluno = @current_user.personal.alunos.find(params[:aluno_id])
  rescue ActiveRecord::RecordNotFound
     render json: { error: 'Aluno não encontrado.' }, status: :not_found
  end

  def set_training_block
    @training_block = TrainingBlock.joins(:aluno)
                                   .where(alunos: { personal_id: @current_user.personal.id })
                                   .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Bloco de treino não encontrado ou não pertence a um de seus alunos.' }, status: :not_found
  end

  def training_block_params
    params.require(:training_block).permit(:title, :weeks_duration, :start_date, :end_date)
  end

  def create_weeks_for_block(block)
    duration = block.weeks_duration || 5
    duration.times do |i|
      block.weeks.create!(week_number: i + 1)
    end
  end

  def update_weeks_for_block(block)
    block.reload
    current_weeks_count = block.weeks.count
    new_duration = block.weeks_duration.to_i

    if new_duration > current_weeks_count
      (new_duration - current_weeks_count).times do |i|
        block.weeks.create!(week_number: current_weeks_count + i + 1)
      end
    elsif new_duration < current_weeks_count
      block.weeks.where("week_number > ?", new_duration).destroy_all
    end
  end

  # NOVA FUNÇÃO PARA CALCULAR AS DATAS
  def calculate_and_save_week_dates(block)
    return unless block.start_date.present?

    next_week_start_date = block.start_date
    weeks = block.weeks.order(week_number: :asc)

    weeks.each_with_index do |week, index|
      current_week_start_date = next_week_start_date
      
      # Lógica para calcular o fim da semana (domingo)
      # wday: 0=Dom, 1=Seg, ..., 6=Sáb
      days_until_sunday = (7 - current_week_start_date.wday) % 7
      week_end_date = current_week_start_date + days_until_sunday.days

      # SEGUNDO PONTO: VERIFICA SE ESTA É A ÚLTIMA SEMANA
      is_last_week = (index == weeks.length - 1)
      if is_last_week && block.end_date.present?
        # Se a data final do bloco for ANTES do domingo calculado para esta semana,
        # use a data final do bloco como o fim da semana.
        if block.end_date < week_end_date
          week_end_date = block.end_date
        end
      end

      week.update_columns(start_date: current_week_start_date, end_date: week_end_date)
      
      # Prepara a data de início para a PRÓXIMA iteração (sempre o dia seguinte ao fim da semana atual)
      next_week_start_date = week_end_date + 1.day
    end
  end

  def authorize_coach!
    return if @current_user.personal?
    render json: { error: 'Acesso restrito a coaches.' }, status: :forbidden
  end
end