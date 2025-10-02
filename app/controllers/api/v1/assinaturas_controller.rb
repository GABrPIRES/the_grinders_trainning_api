# app/controllers/api/v1/assinaturas_controller.rb
class Api::V1::AssinaturasController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_coach! # Apenas coaches podem gerenciar assinaturas por aqui
    before_action :set_assinatura, only: [:show, :destroy]
  
    # GET /api/v1/assinaturas?aluno_id=...
    def index
      if params[:aluno_id]
        aluno = @current_user.personal.alunos.find(params[:aluno_id])
        @assinaturas = aluno.assinaturas.order(start_date: :desc)
      else
        # Se nenhum aluno for especificado, mostra todas as assinaturas dos alunos do coach
        @assinaturas = Assinatura.where(aluno_id: @current_user.personal.alunos.ids)
      end
      render json: @assinaturas, include: [:plano, :aluno]
    end
  
    # GET /api/v1/assinaturas/:id
    def show
      render json: @assinatura, include: [:plano, :aluno]
    end
  
    # POST /api/v1/assinaturas
    def create
      plano = @current_user.personal.planos.find(assinatura_params[:plano_id])
      aluno = @current_user.personal.alunos.find(assinatura_params[:aluno_id])
  
      start_date = Date.today
      end_date = start_date + plano.duration.days
  
      @assinatura = Assinatura.new(
        plano: plano,
        aluno: aluno,
        start_date: start_date,
        end_date: end_date,
        status: :ativo # Usando o enum
      )
  
      if @assinatura.save
        render json: @assinatura, status: :created
      else
        render json: @assinatura.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /api/v1/assinaturas/:id (Cancelar Assinatura)
    def destroy
      @assinatura.update(status: :cancelado)
      render json: @assinatura
    end
  
    private
  
    def set_assinatura
      # Garante que o coach só possa acessar assinaturas de seus próprios alunos
      @assinatura = Assinatura.where(aluno_id: @current_user.personal.alunos.ids).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Assinatura não encontrada ou não pertence a um de seus alunos.' }, status: :not_found
    end
  
    def assinatura_params
      params.require(:assinatura).permit(:plano_id, :aluno_id)
    end
  
    def authorize_coach!
      return if @current_user.personal?
      render json: { error: 'Acesso restrito a coaches.' }, status: :forbidden
    end
  end