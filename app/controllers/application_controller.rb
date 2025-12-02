# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
    # [FIX] Inclui o suporte a cookies nos controllers da API
    include ActionController::Cookies 
    
    include Authenticable
    include Authorizable
end