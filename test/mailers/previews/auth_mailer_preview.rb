# test/mailers/previews/auth_mailer_preview.rb
class AuthMailerPreview < ActionMailer::Preview
    def verify_email
      # Criamos um usuário falso na memória apenas para visualizar
      user = User.new(
        name: "Gabriel Preview", 
        email: "gabriel@teste.com", 
        verification_token: "TOKEN-DE-EXEMPLO-123"
      )
      
      # Chamamos o mailer passando esse usuário
      AuthMailer.verify_email(user)
    end
  end