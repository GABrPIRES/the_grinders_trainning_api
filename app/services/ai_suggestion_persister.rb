# app/services/ai_suggestion_persister.rb
#
# Recebe o output do Gemini (agrupado por treino), aplica o guardrail de 20%
# e persiste as sugestões. Salva também a observação da IA em cada treino.
class AiSuggestionPersister
  CRITICAL_DELTA_THRESHOLD = 0.20

  def initialize(suggestions_json, section_id_map, treino_id_map)
    # suggestions_json: array de { "treino_id" => uuid_new, "observation" => text,
    #                               "sections" => [{"section_id"=>uuid_old, "suggested_load"=>float}] }
    # section_id_map: { original_section_id_string => new_section }
    # treino_id_map: { original_treino_id_string => new_treino } — used to find treino by new id
    @suggestions = suggestions_json
    @section_map = section_id_map
    # Build reverse map: new_treino_id => new_treino
    @treino_by_new_id = treino_id_map.values.index_by { |t| t.id.to_s }
  end

  def persist!
    @suggestions.each do |treino_suggestion|
      new_treino_id = treino_suggestion["treino_id"].to_s
      new_treino = @treino_by_new_id[new_treino_id]
      next unless new_treino

      # Salva a observação da IA no treino duplicado (exibida ao coach na revisão).
      observation = treino_suggestion["observation"].presence
      new_treino.update_column(:ai_observation, observation) if observation

      (treino_suggestion["sections"] || []).each do |section_suggestion|
        original_section_id = section_suggestion["section_id"].to_s
        new_section = @section_map[original_section_id]
        next unless new_section

        suggested_load = section_suggestion["suggested_load"].to_f
        prescribed_load = new_section.carga.to_f
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
    delta > CRITICAL_DELTA_THRESHOLD
  end
end
