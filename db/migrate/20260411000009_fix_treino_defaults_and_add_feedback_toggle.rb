class FixTreinoDefaultsAndAddFeedbackToggle < ActiveRecord::Migration[8.0]
  def change
    # Treinos criados pelo coach são published por padrão.
    # draft só existe para treinos duplicados pela IA aguardando aprovação.
    change_column_default :treinos, :status, from: 0, to: 1

    # O coach pode desativar o formulário semanal para uma semana específica.
    add_column :weeks, :feedback_enabled, :boolean, default: true, null: false

    # Observação da IA sobre o treino (gerada pelo Gemini, exibida ao coach na revisão).
    add_column :treinos, :ai_observation, :text
  end
end
