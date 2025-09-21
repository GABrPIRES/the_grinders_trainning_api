# app/controllers/concerns/authenticable.rb
module Authenticable
    extend ActiveSupport::Concern
  
    private
  
    def authenticate_request
      header = request.headers['Authorization']
      token = header.split(' ').last if header
      begin
        decoded = JsonWebToken.decode(token)
        @current_user = User.find(decoded[:user_id])
      rescue ActiveRecord::RecordNotFound, JWT::DecodeError
        render json: { error: 'Não autorizado' }, status: :unauthorized
      end
    end
  end