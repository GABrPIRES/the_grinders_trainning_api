# app/controllers/api/v1/training_blocks_controller.rb
class Api::V1::TrainingBlocksController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_coach!
    before_action :set_aluno, only: [:index, :create]
    before_action :set_training_block, only: [:show, :update, :destroy]
  
    # GET /api/v1/alunos/:aluno_id/training_blocks
    def index
      @training_blocks = @aluno.training_blocks.order(start_date: :desc, created_at: :desc)
      render json: @training_blocks
    end
  
    # GET /api/v1/training_blocks/:id
    def show
      render json: @training_block, include: { weeks: { include: :treinos } }
    end
  
    # POST /api/v1/alunos/:aluno_id/training_blocks
    def create
      @training_block = @aluno.training_blocks.build(training_block_params)
      @training_block.personal = @current_user.personal
  
      if @training_block.save
        create_weeks_for_block(@training_block)
        render json: @training_block, status: :created
      else
        render json: @training_block.errors, status: :unprocessable_entity
      end
    end
  
    # PATCH/PUT /api/v1/training_blocks/:id
    def update
      if @training_block.update(training_block_params)
        update_weeks_for_block(@training_block)
        render json: @training_block
      else
        render json: @training_block.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /api/v1/training_blocks/:id
    def destroy
      @training_block.destroy
      render json: { message: 'Bloco de treino deletado com sucesso.' }, status: :ok
    end
  
    private
  
    def set_aluno
      # Garante que o coach só acesse alunos que pertencem a ele
      @aluno = @current_user.personal.alunos.find(params[:aluno_id])
    end
  
    def set_training_block
      # Garante que o coach só acesse blocos de seus próprios alunos
      @training_block = TrainingBlock.joins(:aluno)
                                     .where(alunos: { personal_id: @current_user.personal.id })
                                     .find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Bloco de treino não encontrado ou não pertence a um de seus alunos.' }, status: :not_found
    end
  
    def training_block_params
      # O :aluno_id não é mais necessário aqui, pois pegamos da URL
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
  
    def authorize_coach!
      return if @current_user.personal?
      render json: { error: 'Acesso restrito a coaches.' }, status: :forbidden
    end
  end