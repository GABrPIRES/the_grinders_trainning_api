# app/services/ai_config_resolver.rb
#
# Resolve a configuração efetiva da IA para um Personal, em 3 camadas:
#
#   personal.X (override do coach)
#     ↳ se nil → AdminSetting.instance.X (default global do admin)
#         ↳ se nil → constante hard-coded em GeminiClient / AiSuggestionPersister
#
# Também interpola placeholders no system prompt (`{{max_load_increase_pct}}`,
# `{{critical_delta_pct}}`, `{{sleep_threshold}}`, `{{stress_threshold}}`)
# antes de enviar ao Gemini.
#
# Sprint 012.
class AiConfigResolver
  KEYS = [
    :ai_system_prompt,
    :ai_max_load_increase_pct,
    :ai_critical_delta_pct,
    :ai_sleep_threshold,
    :ai_stress_threshold
  ].freeze

  # Retorna um hash com os 5 valores efetivos para este personal.
  # Chaves do hash são sem o prefixo `ai_` para uso direto no consumidor.
  def self.for(personal)
    admin = AdminSetting.instance
    {
      system_prompt:         coalesce(personal.ai_system_prompt,         admin.ai_system_prompt,         GeminiClient::DEFAULT_SYSTEM_PROMPT),
      max_load_increase_pct: coalesce_numeric(personal.ai_max_load_increase_pct, admin.ai_max_load_increase_pct, GeminiClient::DEFAULT_MAX_LOAD_INCREASE_PCT),
      critical_delta_pct:    coalesce_numeric(personal.ai_critical_delta_pct,    admin.ai_critical_delta_pct,    AiSuggestionPersister::DEFAULT_CRITICAL_DELTA_PCT),
      sleep_threshold:       coalesce_numeric(personal.ai_sleep_threshold,       admin.ai_sleep_threshold,       GeminiClient::DEFAULT_SLEEP_THRESHOLD),
      stress_threshold:      coalesce_numeric(personal.ai_stress_threshold,      admin.ai_stress_threshold,      GeminiClient::DEFAULT_STRESS_THRESHOLD)
    }
  end

  # Substitui placeholders do template pelo valor efetivo. Se o template
  # não tem placeholders, é no-op. Os parâmetros numéricos continuam
  # tendo efeito server-side mesmo sem placeholder (via AiSuggestionPersister).
  def self.interpolate(template, config)
    template.to_s
            .gsub("{{max_load_increase_pct}}", config[:max_load_increase_pct].to_s)
            .gsub("{{critical_delta_pct}}",    config[:critical_delta_pct].to_s)
            .gsub("{{sleep_threshold}}",       config[:sleep_threshold].to_s)
            .gsub("{{stress_threshold}}",      config[:stress_threshold].to_s)
  end

  def self.coalesce(*values)
    values.find { |v| v.respond_to?(:present?) ? v.present? : !v.nil? }
  end

  def self.coalesce_numeric(*values)
    values.find { |v| !v.nil? }
  end
end
