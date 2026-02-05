class AuthMailer < ApplicationMailer
    def verify_email(user)
      @user = user
      # URL do frontend
      base_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3001') 
      @url = "#{base_url}/verify-email?token=#{@user.verification_token}"
  
      # LÓGICA DA LOGO:
      # 1. Em Produção: Use a URL real do seu site/bucket
      # 2. Em Dev (Preview): Use localhost
      # 3. Em Dev (Gmail): Precisa de uma URL pública (Imgur, S3) ou vai quebrar
      
      # Exemplo: Vamos tentar pegar do localhost por enquanto para você ver no Preview
      # Certifique-se de ter a imagem em public/images/logo-email.png
      api_host = Rails.env.production? ? "https://api.thegrinderspowerlifting.com.br" : "http://localhost:3000"

      # Ajuste o nome do arquivo aqui para o nome exato da sua imagem na pasta public/images/
      image_name_1 = "logo_the_grinders_dark-removebg-preview.png"
      image_name_2 = "logo-the-grinders-2.png"
      # ou o nome que você tiver lá
      @logo_url = "#{api_host}/images/#{image_name_1}"
  
      # Destinatário
      destinatario = Rails.env.development? ? "gabriellaeon@gmail.com" : @user.email

      mail(
        to: destinatario,
        subject: 'Bem-vindo ao The Grinders Team! Verifique seu e-mail para acessar o app.'
      )
    end
  end