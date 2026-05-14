class Api::V1::Coach::SettingsController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_coach!

  # GET /api/v1/coach/settings
  # Retorna o estado atual das flags de IA visíveis para o coach.
  # ai_enabled_by_admin é informativo (read-only para o coach) — controla se
  # a seção de IA aparece no settings do front.
  def show
    render json: settings_json
  end

  # PATCH /api/v1/coach/settings/ai_enabled
  # Coach habilita/desabilita IA para si próprio. Só tem efeito real se o
  # admin tiver habilitado IA para este coach (ai_enabled_by_admin == true).
  def update_ai_enabled
    if @current_user.personal.update(ai_enabled: ai_param)
      render json: settings_json
    else
      render json: { errors: @current_user.personal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def ai_param
    ActiveModel::Type::Boolean.new.cast(params.require(:ai_enabled))
  end

  def settings_json
    personal = @current_user.personal
    {
      ai_enabled_by_admin: personal.ai_enabled_by_admin,
      ai_enabled:          personal.ai_enabled,
      ai_runs:             personal.ai_runs?
    }
  end

  def authorize_coach!
    return if @current_user.personal?
    render json: { error: "Acesso restrito a coaches." }, status: :forbidden
  end
end
