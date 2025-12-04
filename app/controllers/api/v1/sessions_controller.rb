# app/controllers/api/v1/sessions_controller.rb
class Api::V1::SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])

    if user&.inativo?
      return render json: { error: 'Sua conta está desativada.' }, status: :unauthorized
    end

    if user&.authenticate(params[:password])
      payload = { user_id: user.id, role: user.role }
      token = JsonWebToken.encode(payload)

      cookies[:jwt] = {
        value: token,
        httponly: true,
        secure: Rails.env.production?, 
        same_site: :lax, 
        domain: :all, # <--- ADICIONE ISSO! Permite compartilhar entre subdomínios
        expires: 24.hours.from_now
      }

      render json: { 
        message: 'Login realizado com sucesso',
        user: { id: user.id, name: user.name, role: user.role } 
        # Note que não enviamos mais o token aqui, e isso está correto.
      }, status: :ok
    else
      render json: { error: 'Email ou senha inválidos' }, status: :unauthorized
    end
  end

  def destroy
    cookies.delete(:jwt) # Isso manda o navegador apagar o cookie
    render json: { message: 'Deslogado com sucesso' }, status: :ok
  end
end