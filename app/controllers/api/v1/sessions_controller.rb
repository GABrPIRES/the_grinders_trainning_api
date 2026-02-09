# app/controllers/api/v1/sessions_controller.rb
class Api::V1::SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])

    if user && !user.ativo?
      message = case user.status
                when 'pending' then 'Sua conta aguarda aprovação do coach.'
                when 'unverified' then 'Verifique seu e-mail antes de entrar.'
                when 'rejected' then 'Sua solicitação de cadastro foi recusada.'
                else 'Sua conta está desativada.'
                end
      
      return render json: { error: message }, status: :unauthorized
    end

    if user&.authenticate(params[:password])
      payload = { user_id: user.id, role: user.role }
      token = JsonWebToken.encode(payload)

      # Configuração dinâmica do cookie
      cookie_options = {
        value: token,
        httponly: true,
        secure: Rails.env.production?, # HTTPS apenas em produção
        same_site: :lax,
        expires: 30.days.from_now
      }

      # [CORREÇÃO] Só define domain: :all se estiver em produção.
      # No localhost, isso quebra o login, então deixamos sem (padrão).
      if Rails.env.production?
        cookie_options[:domain] = :all
      end

      cookies[:jwt] = cookie_options

      render json: { 
        message: 'Login realizado com sucesso',
        user: { id: user.id, name: user.name, role: user.role } 
      }, status: :ok
    else
      render json: { error: 'Email ou senha inválidos' }, status: :unauthorized
    end
  end

  def destroy
    # [CORREÇÃO] Para deletar o cookie, precisamos passar as MESMAS opções de domínio
    delete_options = {}
    if Rails.env.production?
      delete_options[:domain] = :all
    end

    cookies.delete(:jwt, **delete_options)
    render json: { message: 'Deslogado com sucesso' }, status: :ok
  end
end