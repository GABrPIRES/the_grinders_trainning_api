# app/controllers/api/v1/admin/alunos_controller.rb
class Api::V1::Admin::AlunosController < ApplicationController
    before_action :authenticate_request
    before_action :check_if_admin
    # CORREÇÃO: Adicionando o before_action para as actions que precisam de um aluno específico.
    before_action :set_aluno, only: [:update, :destroy, :show]
  
    # GET /api/v1/admin/alunos
    def index
      base_scope = Aluno.joins(:user)
      if params[:personal_id]
        @alunos = base_scope.where(personal_id: params[:personal_id]).order('users.name')
      else
        @alunos = base_scope.all.order('users.name')
      end
      render json: @alunos, include: :user
    end
  
    # GET /api/v1/admin/alunos/:id
    def show
      render json: @aluno, include: :user
    end
  
    # POST /api/v1/admin/alunos
    def create
        all_params = params.require(:aluno).permit(
          :name, :email, :password, :password_confirmation,
          :phone_number, :personal_id
        )
        
        user_params = all_params.slice(:name, :email, :password, :password_confirmation)
        aluno_params = all_params.slice(:phone_number, :personal_id)
      
        @user = User.new(user_params)
        @user.role = :aluno
      
        # PASSO 1: Verificamos se o User é válido antes de salvar.
        unless @user.valid?
          render json: { model: 'User', errors: @user.errors.full_messages }, status: :unprocessable_entity
          return
        end
        
        @user.save!
      
        # PASSO 2: Construímos o Aluno, mas ainda não salvamos.
        @aluno = @user.build_aluno(aluno_params)
      
        # PASSO 3 (O MAIS IMPORTANTE): Verificamos se o Aluno é válido.
        # Se não for, retornamos a mensagem de erro exata.
        unless @aluno.valid?
          @user.destroy # Limpamos o usuário órfão que acabamos de criar.
          render json: { model: 'Aluno', errors: @aluno.errors.full_messages }, status: :unprocessable_entity
          return
        end
      
        # Se ambos forem válidos, finalmente salvamos o aluno.
        @aluno.save!
        
        render json: @aluno, include: :user, status: :created
      end
  
    # PATCH/PUT /api/v1/admin/alunos/:id
    def update
      user_params = aluno_user_params_for_update.delete_if { |k, v| k.include?('password') && v.blank? }
      
      if @aluno.user.update(user_params) && @aluno.update(aluno_profile_params)
        render json: @aluno, include: :user
      else
        render json: { errors: @aluno.user.errors.full_messages + @aluno.errors.full_messages }, status: :unprocessable_entity
      end
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