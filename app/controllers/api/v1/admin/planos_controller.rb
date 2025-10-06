# app/controllers/api/v1/admin/planos_controller.rb
class Api::V1::Admin::PlanosController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_admin!
  
    # GET /api/v1/admin/planos
    def index
        if params[:personal_id].present?
          @planos = Plano.where(personal_id: params[:personal_id]).order(:name)
        else
          @planos = Plano.all.order(:name)
        end
        render json: @planos
      end
  
    private
  
    # Reutilizando o concern de autorização
    def authorize_admin!
      return if @current_user.admin?
      render json: { error: 'Acesso restrito a administradores.' }, status: :forbidden
    end
  end