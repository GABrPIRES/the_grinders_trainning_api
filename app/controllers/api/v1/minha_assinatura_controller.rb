# app/controllers/api/v1/minha_assinatura_controller.rb
class Api::V1::MinhaAssinaturaController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_aluno!
  
    # GET /api/v1/minha_assinatura
    def show
      # Busca a assinatura mais recente (ativa ou não) do aluno logado
      @assinatura = @current_user.aluno&.assinaturas&.order(created_at: :desc)&.first
      
      if @assinatura
        render json: @assinatura, include: :plano
      else
        render json: { error: 'Nenhuma assinatura encontrada.' }, status: :not_found
      end
    end
  
    private
  
    def authorize_aluno!
      return if @current_user.aluno?
      render json: { error: 'Acesso restrito a alunos.' }, status: :forbidden
    end
  end