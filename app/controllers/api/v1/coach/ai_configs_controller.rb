# app/controllers/api/v1/coach/ai_configs_controller.rb
#
# Coach customiza prompt + 4 parâmetros guardrail dentro de ranges
# conservadores (Personal::COACH_AI_RANGES — mais restritivos que admin).
# Quando os 5 campos do personal são nil, usa admin default.
class Api::V1::Coach::AiConfigsController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_coach!

  ALLOWED_PARAMS = %i[
    ai_system_prompt
    ai_max_load_increase_pct
    ai_critical_delta_pct
    ai_sleep_threshold
    ai_stress_threshold
  ].freeze

  # GET /api/v1/coach/ai_config
  def show
    personal = @current_user.personal
    admin = AdminSetting.instance

    render json: {
      defaults: ALLOWED_PARAMS.index_with { |k| admin[k] || hardcoded_default(k) },
      current:  ALLOWED_PARAMS.index_with { |k| personal[k] },
      is_using_default: ALLOWED_PARAMS.all? { |k| personal[k].nil? },
      ranges: Personal::COACH_AI_RANGES.transform_values { |r| { min: r.min, max: r.max } }
    }
  end

  # PATCH /api/v1/coach/ai_config
  # Coach pode mandar update parcial. Validações de range são feitas no
  # Personal#validate_ai_config_ranges (cap conservador).
  def update
    personal = @current_user.personal
    perm = params.permit(ALLOWED_PARAMS)
    if personal.update(perm)
      render json: ALLOWED_PARAMS.index_with { |k| personal[k] }
    else
      render json: { errors: personal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/coach/ai_config/reset_to_default
  def reset_to_default
    personal = @current_user.personal
    personal.update!(ALLOWED_PARAMS.index_with { nil })
    render json: ALLOWED_PARAMS.index_with { |k| personal[k] }
  end

  private

  def authorize_coach!
    return if @current_user.personal?
    render json: { error: "Acesso restrito a coaches." }, status: :forbidden
  end

  def hardcoded_default(key)
    case key
    when :ai_system_prompt          then GeminiClient::DEFAULT_SYSTEM_PROMPT
    when :ai_max_load_increase_pct  then GeminiClient::DEFAULT_MAX_LOAD_INCREASE_PCT
    when :ai_critical_delta_pct     then AiSuggestionPersister::DEFAULT_CRITICAL_DELTA_PCT
    when :ai_sleep_threshold        then GeminiClient::DEFAULT_SLEEP_THRESHOLD
    when :ai_stress_threshold       then GeminiClient::DEFAULT_STRESS_THRESHOLD
    end
  end
end
