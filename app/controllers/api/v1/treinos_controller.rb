# app/controllers/api/v1/treinos_controller.rb
class Api::V1::TreinosController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_admin_or_coach!
    
    # ATUALIZAÇÃO: Carrega a semana correta para index e create
    before_action :set_week, only: [:index, :create]
    # ATUALIZAÇÃO: Mantém o set_treino para as outras ações
    before_action :set_treino, only: [:show, :update, :destroy]
  
    # GET /api/v1/weeks/:week_id/treinos
    def index
        # ATUALIZAÇÃO: Busca treinos aninhados na semana
        @treinos = @week.treinos.order(day: :asc)
        render json: @treinos.as_json(include: :exercicios)
    end
  
    # GET /api/v1/treinos/:id
    def show
      render json: @treino, include: { exercicios: { include: :sections } }
    end
  
    # POST /api/v1/weeks/:week_id/treinos
    def create
      # ATUALIZAÇÃO: Cria o treino a partir da semana
      @treino = @week.treinos.build(treino_params)
      
      # ATUALIZAÇÃO: Associa o personal_id do bloco ao treino
      @treino.personal_id = @week.training_block.personal_id

      if @treino.save
        render json: @treino, include: { exercicios: { include: :sections } }, status: :created
      else
        render json: @treino.errors, status: :unprocessable_entity
      end
    end
  
    # PATCH/PUT /api/v1/treinos/:id
    def update
      if @treino.update(treino_params)
        render json: @treino
      else
        render json: @treino.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /api/v1/treinos/:id
    def destroy
      @treino.destroy
      render json: { message: 'Treino deletado com sucesso' }, status: :ok
    end
  
    private

    def set_week
      # Garante que o coach possa acessar a semana
      @week = Week.joins(training_block: :personal)
                  .where(training_blocks: { personal_id: @current_user.personal.id })
                  .find(params[:week_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Semana não encontrada.' }, status: :not_found
    end
  
    def set_treino
      # Esta lógica continua a mesma, pois o treino ainda tem um personal_id
      @treino = @current_user.personal.treinos.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Treino não encontrado' }, status: :not_found
    end
  
    def treino_params
      # ATUALIZAÇÃO: Removemos aluno_id, pois ele não existe mais no treino
      params.require(:treino).permit(
        :name, 
        :duration_time, 
        :day,
        # :aluno_id, <-- REMOVIDO
        exercicios_attributes: [
          :id, 
          :name, 
          :_destroy, 
          sections_attributes: [
            :id, 
            :carga, 
            :series, 
            :reps, 
            :equip, 
            :rpe, 
            :pr, 
            :feito, 
            :_destroy
          ]
        ]
      )
    end
  end