# lib/json_web_token.rb
# Não há 'require' no topo do arquivo.

module JsonWebToken
    SECRET_KEY = Rails.application.credentials.jwt_secret_key
  
    def self.encode(payload, exp = 30.days.from_now)
      # Carrega a gem JWT no momento exato do uso.
      require 'jwt'
      payload[:exp] = exp.to_i
      payload[:jti] ||= SecureRandom.uuid
      JWT.encode(payload, SECRET_KEY)
    end
  
    def self.decode(token)
      # Carrega a gem JWT no momento exato do uso.
      require 'jwt'
      decoded = JWT.decode(token, SECRET_KEY)[0]
      HashWithIndifferentAccess.new decoded
    end
  end