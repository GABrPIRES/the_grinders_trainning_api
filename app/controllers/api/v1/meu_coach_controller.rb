# app/controllers/api/v1/meu_coach_controller.rb
class Api::V1::MeuCoachController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_aluno!
  
    # GET /api/v1/meu_coach
    def show
      coach_profile = @current_user.aluno.personal
      
      if coach_profile
        render json: coach_profile, include: [:user, :payment_methods]
      else
        render json: { error: 'Nenhum coach associado a este aluno.' }, status: :not_found
      end
    end
  
    private
  
    def authorize_aluno!
      return if @current_user.aluno?
      render json: { error: 'Acesso restrito a alunos.' }, status: :forbidden
    end
  end