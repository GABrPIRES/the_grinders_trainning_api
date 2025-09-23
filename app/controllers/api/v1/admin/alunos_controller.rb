# app/controllers/api/v1/admin/alunos_controller.rb
class Api::V1::Admin::AlunosController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_admin!
  
    # POST /api/v1/admin/alunos
    def create
      ActiveRecord::Base.transaction do
        @user = User.new(aluno_user_params)
        @user.role = :aluno
        @user.save!
  
        # A grande diferença: o personal_id vem dos parâmetros!
        @aluno = @user.create_aluno!(aluno_profile_params)
      end
  
      render json: @aluno, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    def index
        base_scope = Aluno.joins(:user)
    
        if params[:personal_id]
          @alunos = base_scope.where(personal_id: params[:personal_id]).order('users.name')
        else
          @alunos = base_scope.all.order('users.name')
        end
        
        render json: @alunos, include: :user
    end

    def show
        base_scope = Aluno.joins(:user)

        @aluno = base_scope.find(params[:id])
        render json: @aluno, include: :user
    rescue ActiveRecord::RecordNotFound
        render json: { error: 'Aluno não encontrado ou não pertence a este coach' }, status: :not_found
    end
  
    private
    
    def aluno_user_params
      params.require(:aluno).permit(:name, :email, :password, :password_confirmation)
    end
  
    # Agora, este método permite o personal_id
    def aluno_profile_params
      params.require(:aluno).permit(:phone_number, :personal_id) # Adicione outros campos se necessário
    end
  end