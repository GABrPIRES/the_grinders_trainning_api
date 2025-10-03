# app/controllers/api/v1/admin/coaches_controller.rb
class Api::V1::Admin::CoachesController < ApplicationController
    before_action :authenticate_request
    before_action :check_if_admin
  
    # GET /api/v1/admin/coaches
    def index
      # Busca todos os perfis de Personal e já inclui os dados do User associado
      @coaches = Personal.includes(:user).all.map do |personal|
        {
          id: personal.id, # Este é o ID correto (da tabela personals)
          user_id: personal.user.id,
          name: personal.user.name,
          email: personal.user.email
        }
      end
      render json: @coaches
    end
  
    private
  
    def check_if_admin
      unless @current_user.admin?
        render json: { error: 'Acesso não autorizado' }, status: :forbidden
      end
    end
  end