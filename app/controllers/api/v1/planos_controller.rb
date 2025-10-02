# app/controllers/api/v1/planos_controller.rb
class Api::V1::PlanosController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_coach!
    before_action :set_plano, only: [:show, :update, :destroy]
  
    # GET /api/v1/planos
    def index
      @planos = @current_user.personal.planos.order(:name)
      render json: @planos
    end
  
    # GET /api/v1/planos/:id
    def show
      render json: @plano
    end
  
    # POST /api/v1/planos
    def create
      @plano = @current_user.personal.planos.build(plano_params)
      if @plano.save
        render json: @plano, status: :created
      else
        render json: @plano.errors, status: :unprocessable_entity
      end
    end
  
    # PATCH/PUT /api/v1/planos/:id
    def update
      if @plano.update(plano_params)
        render json: @plano
      else
        render json: @plano.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /api/v1/planos/:id
    def destroy
      @plano.destroy
      render json: { message: 'Plano deletado com sucesso.' }, status: :ok
    end
  
    private
  
    def set_plano
      @plano = @current_user.personal.planos.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Plano não encontrado ou não pertence a este coach.' }, status: :not_found
    end
  
    def plano_params
      params.require(:plano).permit(:name, :description, :price, :duration)
    end
    
    # Sobrescrevemos o método de autorização para ser mais específico
    def authorize_coach!
      return if @current_user.personal?
      render json: { error: 'Acesso restrito a coaches.' }, status: :forbidden
    end
  end