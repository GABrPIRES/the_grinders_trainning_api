# app/controllers/api/v1/admin/alunos_controller.rb
class Api::V1::Admin::AlunosController < ApplicationController
    before_action :authenticate_request
    before_action :check_if_admin
    # CORREÇÃO: Adicionando o before_action para as actions que precisam de um aluno específico.
    before_action :set_aluno, only: [:update, :destroy, :show]
  
    # GET /api/v1/admin/alunos
    def index
      # 1. Busca inicial com includes essenciais para performance e dados
      scope = Aluno.includes(:user, :personal => :user, :assinaturas => :plano, :pagamentos => [])

      # 2. Filtro de Busca (Nome ou Email)
      if params[:search].present?
        term = "%#{params[:search].downcase}%"
        scope = scope.joins(:user).where("lower(users.name) LIKE ? OR lower(users.email) LIKE ?", term, term)
      end

      # 3. Paginação
      page = (params[:page] || 1).to_i
      limit = (params[:limit] || 10).to_i
      offset = (page - 1) * limit

      total_alunos = scope.count
      alunos = scope.order(created_at: :desc).limit(limit).offset(offset)

      # 4. Montagem do JSON com TODOS os dados necessários
      alunos_data = alunos.map do |aluno|
        assinatura_ativa = aluno.assinaturas.find(&:ativo?)
        ultimo_pagamento = aluno.pagamentos.order(due_date: :desc).first

        {
          id: aluno.id,
          created_at: aluno.created_at,
          user: {
            name: aluno.user.name,
            email: aluno.user.email
          },
          personal: {
            user: {
              name: aluno.personal&.user&.name || "Sem Coach"
            }
          },
          pagamento: {
            status: ultimo_pagamento&.status || "pendente"
          },
          plano: {
            nome: assinatura_ativa&.plano&.name || "Sem Plano"
          }
        }
      end

      # Retorna lista + total para paginação correta
      render json: { alunos: alunos_data, total: total_alunos }
    end
  
    # GET /api/v1/admin/alunos/:id
    def show
        render json: @aluno, include: [:user, :assinaturas]
    end
  
    # POST /api/v1/admin/alunos
    def create
        all_params = params.require(:aluno).permit(
          :name, :email, :password, :password_confirmation,
          :phone_number, :personal_id, :plano_id # 1. Permitimos o novo parâmetro
        )
      
        ActiveRecord::Base.transaction do
          user_params = all_params.slice(:name, :email, :password, :password_confirmation)
          aluno_params = all_params.slice(:phone_number, :personal_id)
          plano_id = all_params[:plano_id]
      
          @user = User.new(user_params)
          @user.role = :aluno
          @user.save!
      
          @aluno = @user.create_aluno!(aluno_params)
      
          # 2. Lógica para criar a assinatura se um plano for selecionado
          if plano_id.present?
            plano = Plano.find(plano_id)
            start_date = Date.today
            end_date = start_date + plano.duration.days
      
            @aluno.assinaturas.create!(
              plano: plano,
              start_date: start_date,
              end_date: end_date,
              status: :ativo
            )
          end
        end
      
        render json: @aluno, include: :user, status: :created
    rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end
  
    # PATCH/PUT /api/v1/admin/alunos/:id
    def update
        # Permite todos os parâmetros de uma vez
        all_params = params.require(:aluno).permit(
          :name, :email, :password, :password_confirmation, :status, # Adiciona status
          :phone_number, :personal_id, :plano_id # Adiciona plano_id
        )
    
        ActiveRecord::Base.transaction do
          user_params = all_params.slice(:name, :email, :password, :password_confirmation, :status)
          aluno_params = all_params.slice(:phone_number, :personal_id)
          plano_id = all_params[:plano_id]
    
          # Remove a senha se estiver em branco
          user_params.delete_if { |k, v| k.include?('password') && v.blank? }
    
          @aluno.user.update!(user_params)
          @aluno.update!(aluno_params)
    
          # Lógica para gerenciar a assinatura
          if plano_id.present?
            plano = Plano.find(plano_id)
            assinatura = @aluno.assinaturas.order(created_at: :desc).first
    
            # Se não há assinatura ou a assinatura atual é para um plano diferente
            if assinatura.nil? || assinatura.plano_id.to_s != plano_id
              start_date = Date.today
              end_date = start_date + plano.duration.days
              @aluno.assinaturas.create!(plano: plano, start_date: start_date, end_date: end_date, status: :ativo)
            end
          else
            # Se "Nenhum plano" for selecionado, cancela a assinatura ativa
            @aluno.assinaturas.ativo.update_all(status: :cancelado)
          end
        end
    
        render json: @aluno, include: :user
    rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end
  
    # DELETE /api/v1/admin/alunos/:id
    def destroy
      @aluno.user.destroy
      render json: { message: 'Aluno deletado com sucesso.' }, status: :ok
    end
  
    private
  
    # CORREÇÃO: Lógica de busca correta para o admin.
    def set_aluno
      @aluno = Aluno.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Aluno não encontrado' }, status: :not_found
    end
  
    def check_if_admin
      unless @current_user.admin?
        render json: { error: 'Acesso não autorizado' }, status: :forbidden
      end
    end
    
    # Renomeado para clareza
    def aluno_user_params_for_create
      params.require(:aluno).permit(:name, :email, :password, :password_confirmation)
    end
    
    # Renomeado para clareza
    def aluno_user_params_for_update
       params.require(:aluno).permit(:name, :email, :password, :password_confirmation)
    end
  
    def aluno_profile_params
      params.require(:aluno).permit(
        :personal_id, :phone_number, :birth_date, :weight, :height, :lesao,
        :restricao_medica, :objetivo, :treinos_semana, :tempo_treino,
        :horario_treino, :pr_supino, :pr_terra, :pr_agachamento,
        :new_pr_supino, :new_pr_terra, :new_pr_agachamento
      )
    end
  end