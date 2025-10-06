# app/controllers/api/v1/payment_methods_controller.rb
class Api::V1::PaymentMethodsController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_coach!
  
    # GET /api/v1/payment_methods
    def index
      @payment_methods = @current_user.personal.payment_methods.order(:method_type)
      render json: @payment_methods
    end
  
    # POST /api/v1/payment_methods
    def create
      method_type = payment_method_params[:method_type]
      personal = @current_user.personal
  
      # Aplica as regras de negócio
      if method_type == 'pix' && personal.payment_methods.pix.count >= 2
        return render json: { error: 'Você pode cadastrar no máximo 2 chaves PIX.' }, status: :unprocessable_entity
      end
  
      if method_type == 'bank_account' && personal.payment_methods.bank_account.exists?
        return render json: { error: 'Você só pode cadastrar uma conta bancária.' }, status: :unprocessable_entity
      end
  
      @payment_method = personal.payment_methods.new(payment_method_params)
  
      if @payment_method.save
        render json: @payment_method, status: :created
      else
        render json: @payment_method.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /api/v1/payment_methods/:id
    def destroy
      @payment_method = @current_user.personal.payment_methods.find(params[:id])
      @payment_method.destroy
      render json: { message: 'Forma de pagamento removida com sucesso.' }, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Forma de pagamento não encontrada.' }, status: :not_found
    end
  
    private
  
    def payment_method_params
      # Usamos permit! para permitir uma estrutura de JSON flexível no campo 'details'
      params.require(:payment_method).permit(:method_type, details: {})
    end
  
    def authorize_coach!
      return if @current_user.personal?
      render json: { error: 'Acesso restrito a coaches.' }, status: :forbidden
    end
  end