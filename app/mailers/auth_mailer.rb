class AuthMailer < ApplicationMailer
    def reset_password(user)
      @user = user
      base_url = frontend_url
      @url = "#{base_url}/reset-password?token=#{@user.password_reset_token}"
      @logo_url = "#{base_url}/images/logo_the_grinders_dark-removebg-preview.png"

      destinatario = Rails.env.development? ? "gabriellaeon@gmail.com" : @user.email

      mail(
        to: destinatario,
        subject: 'Redefinição de senha — The Grinders Training'
      )
    end

    def verify_email(user)
      @user = user
      base_url = frontend_url
      @url = "#{base_url}/verify-email?token=#{@user.verification_token}"
      @logo_url = "#{base_url}/images/logo_the_grinders_dark-removebg-preview.png"

      destinatario = Rails.env.development? ? "gabriellaeon@gmail.com" : @user.email

      mail(
        to: destinatario,
        subject: 'Bem-vindo ao The Grinders Team! Verifique seu e-mail para acessar o app.'
      )
    end

    private

    def frontend_url
      Rails.env.development? ? 'http://localhost:3001' : ENV.fetch('FRONTEND_URL', 'https://thegrinderspowerlifting.com.br')
    end
  end