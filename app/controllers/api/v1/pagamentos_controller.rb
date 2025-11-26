# app/controllers/api/v1/pagamentos_controller.rb
class Api::V1::PagamentosController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_coach!, except: [:index]
    before_action :set_pagamento, only: [:show, :update, :destroy]
  
    # GET /api/v1/pagamentos?aluno_id=:id
    def index
      if @current_user.aluno?
        # Se for aluno, retorna APENAS os pagamentos dele
        @pagamentos = @current_user.aluno.pagamentos.order(due_date: :desc)
      
      elsif @current_user.personal?
        # Se for coach, começa com TODOS os pagamentos dele
        scope = @current_user.personal.pagamentos
  
        # CORREÇÃO: Se um aluno_id foi passado na URL, filtra por ele
        if params[:aluno_id].present?
          scope = scope.where(aluno_id: params[:aluno_id])
        end
  
        @pagamentos = scope.order(due_date: :desc)
      
      else
        return render json: { error: 'Acesso não autorizado.' }, status: :forbidden
      end
  
      render json: @pagamentos
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
      updated_params = pagamento_params.to_h

      # CORREÇÃO: Lógica de data de pagamento
      # Se o status é 'pago', usamos a data enviada OU a data atual como fallback.
      if updated_params[:status] == 'pago'
          # Se o frontend mandou paid_at, usa ele; senão, usa Time.current
          updated_params[:paid_at] = updated_params[:paid_at].presence || Time.current
      elsif updated_params[:status] == 'pendente'
          # Se voltou para pendente, limpa a data
          updated_params[:paid_at] = nil
      end

      ActiveRecord::Base.transaction do
          @pagamento.update!(updated_params)

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
      params.require(:pagamento).permit(:aluno_id, :amount, :due_date, :status, :paid_at)
    end
    
    def authorize_coach!
      return if @current_user.personal?
      render json: { error: 'Acesso restrito a coaches.' }, status: :forbidden
    end
  end