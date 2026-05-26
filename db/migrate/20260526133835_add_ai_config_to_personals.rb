class AddAiConfigToPersonals < ActiveRecord::Migration[8.0]
  def change
    # Todos nullable: null = "usa admin default" (que pode ser null → cai
    # no hard-coded). Validações de range (cap conservador) ficam no model.
    add_column :personals, :ai_system_prompt,          :text
    add_column :personals, :ai_max_load_increase_pct,  :decimal, precision: 5, scale: 2
    add_column :personals, :ai_critical_delta_pct,     :decimal, precision: 5, scale: 2
    add_column :personals, :ai_sleep_threshold,        :integer
    add_column :personals, :ai_stress_threshold,       :integer
  end
end
