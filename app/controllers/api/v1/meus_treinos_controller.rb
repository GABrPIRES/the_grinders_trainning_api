# app/controllers/api/v1/meus_treinos_controller.rb
class Api::V1::MeusTreinosController < ApplicationController
    before_action :authenticate_request
    before_action :set_aluno_profile # Adicionamos um before_action para evitar repetição
  
    # GET /api/v1/meus_treinos
    def index
      @treinos = @aluno_profile.treinos.order(day: :desc)
      render json: @treinos, include: { exercicios: { include: :sections } }
    end
  
    # GET /api/v1/meus_treinos/:id
    def show
      # A busca começa a partir dos treinos do aluno, garantindo a segurança.
      @treino = @aluno_profile.treinos.find(params[:id])
      render json: @treino, include: { exercicios: { include: :sections } }
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Treino não encontrado ou não pertence a este aluno.' }, status: :not_found
    end
  
    private
  
    def set_aluno_profile
      @aluno_profile = @current_user.aluno
      if @aluno_profile.nil?
        render json: { error: 'Perfil de aluno não encontrado para este usuário.' }, status: :not_found
      end
    end
  end