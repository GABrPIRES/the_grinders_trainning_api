# app/controllers/api/v1/alunos_controller.rb
class Api::V1::AlunosController < ApplicationController
    before_action :authenticate_request
    before_action :check_if_personal
    before_action :set_aluno, only: [:show, :update, :destroy]

    # GET /api/v1/alunos
    def index
        # Carregamos previamente todas as associações para evitar N+1 queries
        base_scope = @current_user.personal.alunos.includes(:user, :assinaturas, :treinos)
    
        if params[:search].present?
          base_scope = base_scope.where("users.name ILIKE ? OR users.email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
        end
    
        # A paginação será adicionada aqui no futuro
        @alunos = base_scope.order('users.name')
        
        # Construímos uma resposta JSON customizada
        alunos_com_detalhes = @alunos.map do |aluno|
          assinatura_ativa = aluno.assinaturas.find(&:ativo?)
          proximo_treino = aluno.treinos.where('day >= ?', Date.today).order(day: :asc).first
          ultimo_treino_atualizado = aluno.treinos.order(updated_at: :desc).first
    
          aluno.as_json(include: :user).merge(
            pagamento: {
              vencimento: assinatura_ativa&.end_date,
              status: assinatura_ativa&.status
            },
            plano: {
              nome: assinatura_ativa&.plano&.name
            },
            treino_info: {
              proximo_treino: proximo_treino&.day,
              ultima_atualizacao: ultimo_treino_atualizado&.updated_at
            }
          )
        end
    
        # A resposta da API agora é um objeto com 'alunos' (com os detalhes) e 'total'
        render json: { alunos: alunos_com_detalhes, total: alunos_com_detalhes.size }
    end
    
  
    # GET /api/v1/alunos/:id
    def show
        # A busca do aluno já é feita pelo before_action :set_aluno
        
        # Construímos a resposta JSON customizada, assim como no 'index'
        assinatura_ativa = @aluno.assinaturas.find(&:ativo?)
        proximo_treino = @aluno.treinos.where('day >= ?', Date.today).order(day: :asc).first
        ultimo_treino_atualizado = @aluno.treinos.order(updated_at: :desc).first
    
        aluno_com_detalhes = @aluno.as_json(include: :user).merge(
          pagamento: {
            vencimento: assinatura_ativa&.end_date,
            status: assinatura_ativa&.status
          },
          plano: {
            nome: assinatura_ativa&.plano&.name
          },
          treino_info: {
            proximo_treino: proximo_treino&.day,
            ultima_atualizacao: ultimo_treino_atualizado&.updated_at
          }
        )
        
        render json: aluno_com_detalhes
      end

    # POST /api/v1/alunos
    def create
        all_params = params.require(:aluno).permit(
          :name, :email, :password, :password_confirmation,
          :phone_number, :plano_id # Permitimos o novo parâmetro
        )
      
        ActiveRecord::Base.transaction do
          user_params = all_params.slice(:name, :email, :password, :password_confirmation)
          aluno_profile_params = all_params.slice(:phone_number)
          plano_id = all_params[:plano_id]
      
          @user = User.new(user_params)
          @user.role = :aluno
          @user.save!
      
          @aluno = @user.create_aluno!(aluno_profile_params.merge(personal: @current_user.personal))
      
          if plano_id.present?
            # Garante que o coach só pode usar seus próprios planos
            plano = @current_user.personal.planos.find(plano_id)
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

    # PATCH/PUT /api/v1/alunos/:id
    def update
        all_params = params.require(:aluno).permit(
          :name, :email, :password, :password_confirmation, :status,
          :phone_number, :weight, :objetivo, :plano_id
        )
    
        ActiveRecord::Base.transaction do
          user_params = all_params.slice(:name, :email, :password, :password_confirmation, :status)
          aluno_params = all_params.slice(:phone_number, :weight, :objetivo)
          plano_id = all_params[:plano_id]
    
          user_params.delete_if { |k, v| k.include?('password') && v.blank? }
    
          @aluno.user.update!(user_params)
          @aluno.update!(aluno_params)
    
          # Lógica para gerenciar a assinatura
          if plano_id.present?
            plano = @current_user.personal.planos.find(plano_id) # Garante que o plano é do coach
            assinatura = @aluno.assinaturas.ativo.first
    
            if assinatura.nil? || assinatura.plano_id.to_s != plano_id
              assinatura&.update(status: :cancelado) # Cancela a antiga se for diferente
              start_date = Date.today
              end_date = start_date + plano.duration.days
              @aluno.assinaturas.create!(plano: plano, start_date: start_date, end_date: end_date, status: :ativo)
            end
          else
            @aluno.assinaturas.ativo.update_all(status: :cancelado)
          end
        end
    
        render json: @aluno, include: :user
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

    # DELETE /api/v1/alunos/:id
    def destroy
        # Deleta o User associado, o que, por causa do 'dependent: :destroy',
        # também deletará o perfil Aluno e todos os seus treinos, etc.
        @aluno.user.destroy
        render json: { message: 'Aluno deletado com sucesso.' }, status: :ok
    end
  
    private

    def set_aluno
        # Garante que o coach só encontre alunos que pertencem a ele
        @aluno = @current_user.personal.alunos.find(params[:id])
    rescue ActiveRecord::RecordNotFound
        render json: { error: 'Aluno não encontrado ou não pertence a este coach' }, status: :not_found
    end
  
    def check_if_personal
      unless @current_user.personal?
        render json: { error: 'Acesso não autorizado' }, status: :forbidden
      end
    end

    # Parâmetros para CRIAR o User do aluno (senha obrigatória)
    def aluno_user_params
        params.require(:aluno).permit(:name, :email, :password, :password_confirmation)
    end

    # Novo: Parâmetros para ATUALIZAR o User do aluno (senha opcional)
    def aluno_user_params_for_update
        params.require(:aluno).permit(:name, :email, :password, :password_confirmation)
    end

    def aluno_profile_params
        params.require(:aluno).permit(
          :phone_number,
          :birth_date,
          :weight,
          :height,
          :lesao,
          :restricao_medica,
          :objetivo,
          :treinos_semana,
          :tempo_treino,
          :horario_treino,
          :pr_supino,
          :pr_terra,
          :pr_agachamento,
          :new_pr_supino,
          :new_pr_terra,
          :new_pr_agachamento
        )
      end
end