# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_admin!, only: [:create, :destroy, :index]
    before_action :set_user, only: [:show, :update, :destroy]

     # GET /api/v1/users
    def index
        scope = User.all
        scope = scope.where(role: params[:role]) if params[:role].present?
        if params[:search].present?
        scope = scope.where("name ILIKE ? OR email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
        end
        @users = scope.order(:name)
        render json: @users, except: :password_digest
    end

    # GET /api/v1/users/:id
    def show
        render json: @user, except: :password_digest
    end

    # Action para criar um novo usuário (POST /api/v1/users)
    def create
        user = User.new(user_params)
    
        if user.save
          # Após salvar o usuário, cria o perfil correspondente.
          if user.personal?
            user.create_personal! # O '!' causa um erro se a criação falhar
          elsif user.aluno?
            user.create_aluno!(phone_number: params[:user][:phone_number] || 'N/A')
          end
    
          render json: { status: 'SUCCESS', message: 'Usuário criado com sucesso', data: user.as_json(except: :password_digest) }, status: :created
        else
          render json: { status: 'ERROR', message: 'Não foi possível criar o usuário', errors: user.errors.full_messages }, status: :unprocessable_entity
        end
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
        user = User.find(params[:id])
        user.destroy
        render json: { message: 'Usuário deletado com sucesso.' }, status: :ok
    rescue ActiveRecord::RecordNotFound
        render json: { error: 'Usuário não encontrado.' }, status: :not_found
    end
    
    private
    
    def set_user
        @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
        render json: { error: 'Usuário não encontrado' }, status: :not_found
    end

    def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
    end

  end