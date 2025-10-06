# app/controllers/api/v1/pagamentos_controller.rb
class Api::V1::PagamentosController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_coach!
    before_action :set_pagamento, only: [:show, :update, :destroy]
  
    # GET /api/v1/pagamentos?aluno_id=:id
    def index
      base_scope = Pagamento.where(aluno_id: @current_user.personal.alunos.ids)
  
      if params[:aluno_id].present?
        @pagamentos = base_scope.where(aluno_id: params[:aluno_id]).order(due_date: :desc)
      else
        # Atualiza o status de todos os pagamentos pendentes antes de exibi-los
        base_scope.where(status: :pendente).where("due_date < ?", Date.today).update_all(status: :atrasado)
        @pagamentos = base_scope.where.not(status: :pago).order(:due_date).includes(aluno: :user)
      end
  
      render json: @pagamentos, include: { aluno: { include: :user } }
    end
    
    # GET /api/v1/pagamentos/:id
    def show
      render json: @pagamento, include: { aluno: { include: :user } }
    end
  
    # POST /api/v1/pagamentos
    def create
      @pagamento = @current_user.personal.pagamentos.new(pagamento_params)
      if @pagamento.save
        render json: @pagamento, status: :created
      else
        render json: @pagamento.errors, status: :unprocessable_entity
      end
    end
  
   # PATCH/PUT /api/v1/pagamentos/:id
    def update
        # Cria uma cópia dos parâmetros para poder modificá-los
        updated_params = pagamento_params.to_h

        # CORREÇÃO 1: Lógica de data de pagamento
        # Se o status está sendo mudado para 'pago', o servidor define a data atual.
        if updated_params[:status] == 'pago'
        updated_params[:paid_at] = Time.current
        end

        ActiveRecord::Base.transaction do
        @pagamento.update!(updated_params)

        # CORREÇÃO 2: Lógica de recorrência
        # Verifica o parâmetro da URL como string 'true'.
        if updated_params[:status] == 'pago' && params[:create_next] == 'true'
            @pagamento.personal.pagamentos.create!(
            aluno: @pagamento.aluno,
            amount: @pagamento.amount,
            due_date: @pagamento.due_date + 1.month,
            status: :pendente
            )
        end
        end
        render json: @pagamento
    rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end
  
    # DELETE /api/v1/pagamentos/:id
    def destroy
      if @pagamento.pago? && params[:force] != 'true'
        return render json: { error: 'Pagamento já conciliado. Para excluir, é preciso desconciliar primeiro.' }, status: :forbidden
      end
      @pagamento.destroy
      render json: { message: 'Pagamento removido com sucesso.' }, status: :ok
    end
  
    private
  
    def set_pagamento
      @pagamento = @current_user.personal.pagamentos.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Pagamento não encontrado.' }, status: :not_found
    end
  
    def pagamento_params
      params.require(:pagamento).permit(:aluno_id, :amount, :due_date, :status)
    end
    
    def authorize_coach!
      return if @current_user.personal?
      render json: { error: 'Acesso restrito a coaches.' }, status: :forbidden
    end
  end