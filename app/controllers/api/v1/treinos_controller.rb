# app/controllers/api/v1/treinos_controller.rb
class Api::V1::TreinosController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_admin_or_coach!
    before_action :set_treino, only: [:show, :update, :destroy]
  
    # GET /api/v1/treinos
    def index
        # Segurança: Garante que estamos buscando treinos apenas de um aluno específico do coach logado
        aluno = @current_user.personal.alunos.find(params[:aluno_id])
        scope = aluno.treinos
    
        # 1. Filtro por nome do treino (search)
        if params[:search].present?
          scope = scope.where("name ILIKE ?", "%#{params[:search]}%")
        end
    
        # 2. Filtro por data inicial
        if params[:start_date].present?
          scope = scope.where("day >= ?", params[:start_date])
        end
    
        # 3. Filtro por data final
        if params[:end_date].present?
          scope = scope.where("day <= ?", params[:end_date])
        end
    
        # 4. Ordenação (padrão: data mais recente primeiro)
        order_direction = params[:sort_order] == 'asc' ? :asc : :desc
        scope = scope.order(day: order_direction)
        
        @treinos = scope.includes(:exercicios) # Usamos includes para otimização
    
        render json: @treinos.as_json(include: :exercicios)
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