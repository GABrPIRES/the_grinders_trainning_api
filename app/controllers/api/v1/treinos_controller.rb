# app/controllers/api/v1/treinos_controller.rb
class Api::V1::TreinosController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_admin_or_coach!
    before_action :set_treino, only: [:show, :update, :destroy]
  
    # GET /api/v1/treinos
    def index
      # CORREÇÃO AQUI
      treinos_scope = @current_user.personal.treinos
  
      if params[:aluno_id]
        @treinos = treinos_scope.where(aluno_id: params[:aluno_id]).order(day: :desc)
      else
        @treinos = treinos_scope.order(day: :desc)
      end
      render json: @treinos, include: { exercicios: { include: :sections } }
    end
  
    # GET /api/v1/treinos/:id
    def show
      render json: @treino, include: { exercicios: { include: :sections } }
    end
  
    # POST /api/v1/treinos
    def create
      # CORREÇÃO AQUI
      @treino = @current_user.personal.treinos.build(treino_params)
  
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
  
    def set_treino
      # CORREÇÃO AQUI
      @treino = @current_user.personal.treinos.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Treino não encontrado' }, status: :not_found
    end
  
    def treino_params
      params.require(:treino).permit(
        :name, 
        :duration_time, 
        :day, 
        :aluno_id,
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