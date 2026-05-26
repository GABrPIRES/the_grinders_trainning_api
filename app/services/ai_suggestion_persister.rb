# app/services/ai_suggestion_persister.rb
#
# Recebe o output do Gemini (agrupado por treino), aplica o guardrail de
# critical_delta_pct (default 20%, override via AdminSetting/Personal — sprint 012)
# e persiste as sugestões. Salva também a observação da IA em cada treino.
class AiSuggestionPersister
  # Default em porcentagem (ex: 20.0 = 20%). Convertido para fração no
  # constructor. Constante exposta para o AiConfigResolver fazer o fallback.
  DEFAULT_CRITICAL_DELTA_PCT = 20.0

  # suggestions_json: array de { "treino_id" => uuid_new, "observation" => text,
  #                               "sections" => [{"section_id"=>uuid_old, "suggested_load"=>float}] }
  # section_id_map: { original_section_id_string => new_section }
  # treino_id_map: { original_treino_id_string => new_treino }
  # critical_threshold: porcentagem (ex: 20.0 = 20%) — sprint 012 permite admin
  # ou coach customizar. Default cai no DEFAULT_CRITICAL_DELTA_PCT.
  def initialize(suggestions_json, section_id_map, treino_id_map, critical_threshold: DEFAULT_CRITICAL_DELTA_PCT)
    @suggestions = suggestions_json
    @section_map = section_id_map
    @treino_by_new_id = treino_id_map.values.index_by { |t| t.id.to_s }
    @critical_threshold_fraction = critical_threshold.to_f / 100.0
  end

  def persist!
    @suggestions.each do |treino_suggestion|
      new_treino_id = treino_suggestion["treino_id"].to_s
      new_treino = @treino_by_new_id[new_treino_id]
      next unless new_treino
      # Não sugere cargas em treinos preservados do coach (created_by_ai: false).
      # O coach mantém autonomia plena nos treinos que criou manualmente.
      next unless new_treino.created_by_ai

      # Salva a observação da IA no treino duplicado (exibida ao coach na revisão).
      observation = treino_suggestion["observation"].presence
      new_treino.update_column(:ai_observation, observation) if observation

      (treino_suggestion["sections"] || []).each do |section_suggestion|
        original_section_id = section_suggestion["section_id"].to_s
        new_section = @section_map[original_section_id]
        next unless new_section

        suggested_load = section_suggestion["suggested_load"].to_f
        prescribed_load = new_section.carga.to_f
        # IA agora retorna todas as sections (mesmo iguais à prescrita) pra rastreabilidade.
        # Só persistimos quando há mudança real — UI usa prescribed_load como fallback no input.
        next if (suggested_load - prescribed_load).abs < 0.01

        critical = load_change_critical?(prescribed_load, suggested_load)

        new_section.ai_load_suggestions.create!(
          suggested_load: suggested_load,
          status: :pending,
          critical: critical
        )
      end
    end
  end

  private

  def load_change_critical?(prescribed, suggested)
    return false if prescribed.zero?

    delta = (suggested - prescribed).abs / prescribed
    delta > @critical_threshold_fraction
  end
end
