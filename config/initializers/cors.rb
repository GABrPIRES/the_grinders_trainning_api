# # config/initializers/cors.rb

# # Garante que a gem rack-cors seja carregada
# require 'rack/cors'

# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     # Permite requisições do seu frontend Next.js em desenvolvimento
#     origins 'http://localhost:3000'

#     resource '*',
#       headers: :any,
#       methods: [:get, :post, :put, :patch, :delete, :options, :head],
#       credentials: true # Essencial para autenticação baseada em cookies/tokens
#   end
# end