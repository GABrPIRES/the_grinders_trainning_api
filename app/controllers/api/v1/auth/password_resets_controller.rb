# app/controllers/api/v1/auth/password_resets_controller.rb
class Api::V1::Auth::PasswordResetsController < ApplicationController
  # POST /api/v1/auth/forgot_password
  # Sempre retorna 200 para não revelar se o e-mail existe.
  def create
    user = User.find_by(email: params[:email].to_s.downcase.strip)

    if user
      token = user.generate_password_reset_token!
      AuthMailer.reset_password(user).deliver_later
    end

    render json: { message: "Se o e-mail estiver cadastrado, você receberá um link para redefinir sua senha." }
  end

  # POST /api/v1/auth/reset_password
  def update
    user = User.find_by(password_reset_token: params[:token].to_s.strip)

    if user.nil?
      return render json: { error: "Link inválido ou já utilizado." }, status: :unprocessable_entity
    end

    if user.password_reset_expired?
      user.clear_password_reset_token!
      return render json: { error: "Este link expirou. Solicite um novo." }, status: :unprocessable_entity
    end

    unless params[:password].present? && params[:password].length >= 6
      return render json: { error: "A senha deve ter pelo menos 6 caracteres." }, status: :unprocessable_entity
    end

    unless params[:password] == params[:password_confirmation]
      return render json: { error: "As senhas não conferem." }, status: :unprocessable_entity
    end

    user.password = params[:password]
    if user.save(validate: false)
      user.clear_password_reset_token!
      render json: { message: "Senha redefinida com sucesso! Você já pode fazer login." }
    else
      render json: { error: "Erro ao redefinir senha." }, status: :unprocessable_entity
    end
  end
end
