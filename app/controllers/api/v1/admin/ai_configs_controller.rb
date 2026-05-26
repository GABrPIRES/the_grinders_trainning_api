# app/controllers/api/v1/admin/ai_configs_controller.rb
#
# Admin gerencia o prompt + 4 parâmetros guardrail da IA. Os valores
# ficam em AdminSetting (singleton) e funcionam como default global.
# Coach pode override individualmente via /coach/ai_config (sprint 012).
class Api::V1::Admin::AiConfigsController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_admin!

  # Ranges admin (mais largos que os do coach em Personal::COACH_AI_RANGES).
  ADMIN_RANGES = {
    ai_max_load_increase_pct: 0..30,
    ai_critical_delta_pct:    0..30,
    ai_sleep_threshold:       1..10,
    ai_stress_threshold:      1..10
  }.freeze

  ALLOWED_PARAMS = %i[
    ai_system_prompt
    ai_max_load_increase_pct
    ai_critical_delta_pct
    ai_sleep_threshold
    ai_stress_threshold
  ].freeze

  # GET /api/v1/admin/ai_config
  def show
    settings = AdminSetting.instance
    render json: {
      current: serialize(settings),
      defaults: hardcoded_defaults,
      ranges: ADMIN_RANGES.transform_values { |r| { min: r.min, max: r.max } },
      is_using_default: ALLOWED_PARAMS.all? { |k| settings[k].nil? }
    }
  end

  # PATCH /api/v1/admin/ai_config
  def update
    settings = AdminSetting.instance
    perm = params.permit(ALLOWED_PARAMS)
    error = validate_ranges(perm)
    return render(json: { error: error }, status: :unprocessable_entity) if error

    if settings.update(perm)
      render json: serialize(settings)
    else
      render json: { errors: settings.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/admin/ai_config/reset_to_default
  def reset_to_default
    settings = AdminSetting.instance
    settings.update!(ALLOWED_PARAMS.index_with { nil })
    render json: serialize(settings)
  end

  private

  def authorize_admin!
    return if @current_user.admin?
    render json: { error: "Acesso restrito a administradores." }, status: :forbidden
  end

  def serialize(settings)
    ALLOWED_PARAMS.index_with { |k| settings[k] }
  end

  def hardcoded_defaults
    {
      ai_system_prompt:         GeminiClient::DEFAULT_SYSTEM_PROMPT,
      ai_max_load_increase_pct: GeminiClient::DEFAULT_MAX_LOAD_INCREASE_PCT,
      ai_critical_delta_pct:    AiSuggestionPersister::DEFAULT_CRITICAL_DELTA_PCT,
      ai_sleep_threshold:       GeminiClient::DEFAULT_SLEEP_THRESHOLD,
      ai_stress_threshold:      GeminiClient::DEFAULT_STRESS_THRESHOLD
    }
  end

  def validate_ranges(params_hash)
    ADMIN_RANGES.each do |attr, range|
      val = params_hash[attr]
      next if val.nil? || val == ""
      return "#{attr} fora do range admin (#{range.min}-#{range.max})" unless range.cover?(val.to_f)
    end
    nil
  end
end
