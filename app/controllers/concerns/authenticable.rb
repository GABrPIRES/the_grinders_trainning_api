# app/controllers/concerns/authenticable.rb
module Authenticable
  extend ActiveSupport::Concern

  private

  def authenticate_request
    # [SEGURANÇA] 1. Tenta ler do Cookie HttpOnly (Prioridade máxima)
    token = cookies[:jwt]
    
    # [LEGADO] 2. Fallback para Header Authorization (caso tenha apps mobile nativos no futuro)
    if token.nil?
      header = request.headers['Authorization']
      token = header.split(' ').last if header
    end

    begin
      return render_unauthorized if token.nil?

      decoded = JsonWebToken.decode(token)
      @current_user = User.find(decoded[:user_id])
    rescue ActiveRecord::RecordNotFound, JWT::DecodeError
      render_unauthorized
    end
  end

  def render_unauthorized
    render json: { error: 'Não autorizado' }, status: :unauthorized
  end
end