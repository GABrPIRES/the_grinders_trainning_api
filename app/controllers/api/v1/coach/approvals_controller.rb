class Api::V1::Coach::ApprovalsController < ApplicationController
    before_action :authenticate_request
    
    def index
      return render json: { error: 'Acesso negado' }, status: :forbidden unless @current_user.personal?

      # Lista usuários pendentes que pertencem a este personal
      pending_users = User.joins(:aluno)
                          .where(alunos: { personal_id: @current_user.personal.id })
                          .where(status: :pending)
                          .select(:id, :name, :email, :created_at)

      render json: pending_users
    end

    def update
      return render json: { error: 'Acesso negado' }, status: :forbidden unless @current_user.personal?

      # Busca o aluno pelo ID do USER, garantindo que ele é aluno deste personal
      target_user = User.joins(:aluno)
                        .where(alunos: { personal_id: @current_user.personal.id })
                        .find(params[:id])

      case params[:action_type] # Usando action_type para evitar conflito com 'action' do Rails
      when 'approve'
        target_user.update!(status: :ativo)
        render json: { message: 'Aluno aprovado com sucesso' }
      when 'reject'
        target_user.update!(status: :rejected)
        render json: { message: 'Aluno rejeitado' }
      else
        render json: { error: 'Ação inválida' }, status: :bad_request
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Aluno não encontrado' }, status: :not_found
    end
  end