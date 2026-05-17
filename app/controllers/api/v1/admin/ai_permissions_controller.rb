class Api::V1::Admin::AiPermissionsController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_admin!

  # GET /api/v1/admin/ai_permissions
  # Retorna a flag global + a lista de coaches com status atual de IA.
  def index
    personals = Personal.includes(:user).joins(:user).order("users.name")
    render json: {
      ai_enabled_global: AdminSetting.ai_enabled_global?,
      personals: personals.map { |p| serialize(p) }
    }
  end

  # PATCH /api/v1/admin/ai_permissions/:personal_id
  # Toggle ai_enabled_by_admin para um coach específico.
  def update
    personal = Personal.find(params[:personal_id])
    if personal.update(ai_enabled_by_admin: ai_param)
      render json: serialize(personal)
    else
      render json: { errors: personal.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Coach não encontrado." }, status: :not_found
  end

  private

  def ai_param
    ActiveModel::Type::Boolean.new.cast(params.require(:ai_enabled_by_admin))
  end

  def serialize(personal)
    {
      personal_id:         personal.id,
      user_id:             personal.user.id,
      name:                personal.user.name,
      email:               personal.user.email,
      ai_enabled_by_admin: personal.ai_enabled_by_admin,
      ai_enabled:          personal.ai_enabled
    }
  end

  def authorize_admin!
    return if @current_user.admin?
    render json: { error: "Acesso restrito a administradores." }, status: :forbidden
  end
end
