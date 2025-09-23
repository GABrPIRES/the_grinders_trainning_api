# app/controllers/api/v1/alunos_controller.rb
class Api::V1::AlunosController < ApplicationController
    before_action :authenticate_request
    before_action :check_if_personal
    before_action :set_aluno, only: [:show, :update, :destroy]

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

    # POST /api/v1/alunos
    def create
        ActiveRecord::Base.transaction do
        # CORREÇÃO: Agora o 'aluno_user_params' inclui a senha
        @user = User.new(aluno_user_params)
        @user.role = :aluno
        @user.save!

        @aluno = @user.create_aluno!(aluno_profile_params.merge(personal: @current_user.personal))
        end

        render json: @aluno, include: :user, status: :created
    rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    # PATCH/PUT /api/v1/alunos/:id
    def update
        # Filtra os parâmetros do usuário. Se a senha estiver em branco, remove para não apagar a senha existente.
        user_params_for_update = aluno_user_params_for_update
        user_params_for_update.delete_if { |key, value| key.include?('password') && value.blank? }

        if @aluno.user.update(user_params_for_update) && @aluno.update(aluno_profile_params)
        render json: @aluno, include: :user
        else
        render json: { errors: @aluno.user.errors.full_messages + @aluno.errors.full_messages }, status: :unprocessable_entity
        end
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