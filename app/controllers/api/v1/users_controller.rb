# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_admin!, only: [:create, :destroy]

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

    # DELETE /api/v1/users/:id
    def destroy
        user = User.find(params[:id])
        user.destroy
        render json: { message: 'Usuário deletado com sucesso.' }, status: :ok
    rescue ActiveRecord::RecordNotFound
        render json: { error: 'Usuário não encontrado.' }, status: :not_found
    end
    
    private
    
    def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
    end

  end