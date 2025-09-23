# app/controllers/api/v1/meus_treinos_controller.rb
class Api::V1::MeusTreinosController < ApplicationController
    before_action :authenticate_request
  
    # GET /api/v1/meus_treinos
    def index
      # Garante que temos um perfil de aluno para o usuário logado
      aluno_profile = @current_user.aluno
      if aluno_profile.nil?
        render json: { error: 'Perfil de aluno não encontrado para este usuário.' }, status: :not_found
        return
      end
  
      # Busca os treinos associados a este aluno, ordenados pelo mais recente
      @treinos = aluno_profile.treinos.order(day: :desc)
  
      # Retorna os treinos com todos os detalhes (exercícios e séries)
      render json: @treinos, include: { exercicios: { include: :sections } }
    end
  end