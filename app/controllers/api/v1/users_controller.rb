# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < ApplicationController
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
    
    private
    
    def user_params
        # Adicionamos 'phone_number' para a criação do aluno
        params.require(:user).permit(:name, :email, :password, :password_confirmation, :role, :phone_number)
    end
  end