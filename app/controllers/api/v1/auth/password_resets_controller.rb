# app/controllers/api/v1/auth/password_resets_controller.rb
class Api::V1::Auth::PasswordResetsController < ApplicationController
  # POST /api/v1/auth/forgot_password
  # Sempre retorna 200 para não revelar se o e-mail existe.
  def create
    user = User.find_by(email: params[:email].to_s.downcase.strip)
    AuthMailer.reset_password(user).deliver_later if user
    render json: { message: "Se o e-mail estiver cadastrado, você receberá um link para redefinir sua senha." }
  end

  # POST /api/v1/auth/reset_password
  # O token é gerado por generates_token_for :password_reset (has_secure_password Rails 8),
  # portanto deve ser validado com find_by_token_for, não find_by(password_reset_token:).
  def update
    user = User.find_by_token_for(:password_reset, params[:token].to_s.strip)

    if user.nil?
      return render json: { error: "Link inválido ou já utilizado." }, status: :unprocessable_entity
    end

    unless params[:password].present? && params[:password].length >= 6
      return render json: { error: "A senha deve ter pelo menos 6 caracteres." }, status: :unprocessable_entity
    end

    unless params[:password] == params[:password_confirmation]
      return render json: { error: "As senhas não conferem." }, status: :unprocessable_entity
    end

    user.password = params[:password]
    if user.save(validate: false)
      render json: { message: "Senha redefinida com sucesso! Você já pode fazer login." }
    else
      render json: { error: "Erro ao redefinir senha." }, status: :unprocessable_entity
    end
  end
end
