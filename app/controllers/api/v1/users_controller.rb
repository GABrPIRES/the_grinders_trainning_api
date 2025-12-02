# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_admin!, only: [:create, :destroy, :index]
  before_action :set_user, only: [:show, :update, :destroy]

  # GET /api/v1/users
  def index
    page = params.fetch(:page, 1).to_i
    limit = params.fetch(:limit, 10).to_i

    scope = User.all
    scope = scope.where(role: params[:role]) if params[:role].present?
    if params[:search].present?
      scope = scope.where("name ILIKE ? OR email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    total = scope.count
    @users = scope.order(created_at: :desc).limit(limit).offset(offset(page, limit))
    
    render json: { users: @users.as_json(except: :password_digest), total: total }
  end

  # GET /api/v1/users/:id
  def show
    render json: @user, except: :password_digest
  end

  # POST /api/v1/users
  def create
    # Usamos transação para garantir que User e Perfil (Aluno/Personal) sejam criados juntos ou nenhum
    ActiveRecord::Base.transaction do
      @user = User.new(user_params)
      
      # Definição segura da Role
      role_param = params[:user][:role]
      if role_param.present? && User.roles.keys.include?(role_param)
         @user.role = role_param
      else
         @user.role = :aluno # Fallback
      end

      @user.save! # Lança erro se falhar (name/email/senha), abortando a transação

      # Criação dos Perfis Específicos
      if @user.personal?
        # Cria perfil de Coach
        @user.create_personal!
      
      elsif @user.aluno?
        # Cria perfil de Aluno (EXIGE um Personal/Coach)
        personal_id = params[:user][:personal_id]
        
        unless personal_id.present?
          # Retorna erro amigável se o Admin esqueceu de selecionar o Coach
          raise ActiveRecord::RecordInvalid.new(@user), "É obrigatório selecionar um Coach (Personal) para o aluno."
        end

        # Verifica se o Personal existe
        unless Personal.exists?(id: personal_id)
           raise ActiveRecord::RecordNotFound, "O Coach selecionado não existe."
        end

        @user.create_aluno!(
          phone_number: params[:user][:phone_number] || 'N/A',
          personal_id: personal_id
        )
      end
    end

    # Sucesso
    render json: { 
      status: 'SUCCESS', 
      message: 'Usuário criado com sucesso', 
      data: @user.as_json(except: :password_digest) 
    }, status: :created

  rescue ActiveRecord::RecordInvalid => e
    # Captura erros de validação (User ou Perfil)
    render json: { status: 'ERROR', message: e.message, errors: e.record&.errors&.full_messages }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound => e
    render json: { status: 'ERROR', message: e.message }, status: :bad_request
  rescue StandardError => e
    render json: { status: 'ERROR', message: "Erro inesperado: #{e.message}" }, status: :internal_server_error
  end

  # PATCH/PUT /api/v1/users/:id
  def update
    user_params_for_update = user_params.delete_if { |k, v| k.include?('password') && v.blank? }
    
    if @user.update(user_params_for_update)
      render json: @user, except: :password_digest
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/users/:id
  def destroy
    @user.destroy
    render json: { message: 'Usuário deletado com sucesso.' }, status: :ok
  end

  private

  def offset(page, limit)
    (page - 1) * limit
  end

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Usuário não encontrado' }, status: :not_found
  end

  def user_params
    # Proteção contra Mass Assignment: Role removida daqui
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end