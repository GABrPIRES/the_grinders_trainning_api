# app/controllers/api/v1/sessions_controller.rb
class Api::V1::SessionsController < ApplicationController
    def create
      user = User.find_by(email: params[:email])

      if user&.inativo?
        return render json: { error: 'Sua conta está desativada.' }, status: :unauthorized
      end
  
      if user&.authenticate(params[:password])
        payload = { user_id: user.id, role: user.role }
        
        # AQUI ESTÁ A MUDANÇA!
        token = JsonWebToken.encode(payload)
  
        render json: { token: token, user: { id: user.id, name: user.name, role: user.role } }, status: :ok
      else
        render json: { error: 'Email ou senha inválidos' }, status: :unauthorized
      end
    end
  end