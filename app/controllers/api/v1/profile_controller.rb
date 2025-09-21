# app/controllers/api/v1/profile_controller.rb
class Api::V1::ProfileController < ApplicationController
    # Esta é a linha mágica! Ela diz ao Rails para rodar nosso método
    # 'authenticate_request' antes de executar qualquer action neste controller.
    before_action :authenticate_request
  
    # GET /api/v1/profile
    def show
      render json: @current_user.as_json(except: :password_digest)
    end
  end