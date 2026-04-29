class Api::V1::Admin::SettingsController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_admin!

  # GET /api/v1/admin/settings
  def show
    render json: settings_json
  end

  # PATCH /api/v1/admin/settings
  def update
    setting = AdminSetting.instance
    if setting.update(allowed_params)
      render json: settings_json
    else
      render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def allowed_params
    params.require(:settings).permit(:emails_enabled)
  end

  def settings_json
    { emails_enabled: AdminSetting.emails_enabled? }
  end

  def authorize_admin!
    unless @current_user.admin?
      render json: { error: "Acesso restrito a administradores." }, status: :forbidden
    end
  end
end
