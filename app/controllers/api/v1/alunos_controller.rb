# app/controllers/api/v1/alunos_controller.rb
class Api::V1::AlunosController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_admin_or_coach!
  
    # GET /api/v1/alunos
    def index
        @alunos = @current_user.personal.alunos.joins(:user).order('users.name')
        render json: @alunos, include: :user     
    end
  
    # GET /api/v1/alunos/:id
    def show
      @aluno = @current_user.personal.alunos.find(params[:id])
      render json: @aluno, include: :user
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Aluno não encontrado ou não pertence a este coach' }, status: :not_found
    end

    def create
        # Transaction garante que ou tudo é criado com sucesso, ou nada é.
        ActiveRecord::Base.transaction do
          @user = User.new(aluno_user_params)
          @user.role = :aluno # Garante que a role seja 'aluno'
          @user.save!
    
          # Cria o perfil do aluno já associado ao personal logado
          @aluno = @user.create_aluno!(aluno_profile_params.merge(personal: @current_user.personal))
        end
    
        render json: @aluno, status: :created
      rescue ActiveRecord::RecordInvalid => e
        # Se algo falhar (ex: e-mail já existe), retorna o erro
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end
  
    private
  
    def check_if_personal
      unless @current_user.personal?
        render json: { error: 'Acesso não autorizado' }, status: :forbidden
      end
    end

    def aluno_user_params
        params.require(:aluno).permit(:name, :email, :password, :password_confirmation)
    end
    
    def aluno_profile_params
        params.require(:aluno).permit(:phone_number, :birth_date, :weight, :height, :objetivo) # Adicione outros campos se necessário
    end
  end