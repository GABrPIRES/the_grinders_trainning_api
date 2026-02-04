class Api::V1::Auth::VerificationsController < ApplicationController
    # skip_before_action :authenticate_request, only: [:verify]

    def verify
      user = User.find_by(verification_token: params[:token])
      return render json: { error: 'Token inválido' }, status: :not_found unless user

      personal = user.aluno&.personal
      
      # Lógica de Auto-Aprovação
      if personal&.auto_approve_students
        user.status = :ativo
        message = "E-mail verificado e conta ativada!"
      else
        user.status = :pending
        message = "E-mail verificado! Aguardando aprovação do seu coach."
      end

      user.verification_token = nil
      user.email_verified_at = Time.current
      user.save!

      render json: { message: message, status: user.status }, status: :ok
    end
  end