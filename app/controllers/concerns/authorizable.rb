# app/controllers/concerns/authorizable.rb
module Authorizable
    extend ActiveSupport::Concern
  
    private
  
    # Apenas Admins podem passar
    def authorize_admin!
      return if @current_user.admin?
      render json: { error: 'Acesso restrito a administradores.' }, status: :forbidden
    end
  
    # Apenas Coaches (Personal) podem passar
    def authorize_coach!
      return if @current_user.personal?
      render json: { error: 'Acesso restrito a coaches.' }, status: :forbidden
    end
  
    # Admins ou Coaches podem passar
    def authorize_admin_or_coach!
      return if @current_user.admin? || @current_user.personal?
      render json: { error: 'Acesso restrito a administradores ou coaches.' }, status: :forbidden
    end
  end