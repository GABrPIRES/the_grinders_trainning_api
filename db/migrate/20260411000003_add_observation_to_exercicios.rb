# db/migrate/20260411000003_add_observation_to_exercicios.rb
class AddObservationToExercicios < ActiveRecord::Migration[8.0]
  def change
    # Observação é por exercício (não por section), conforme PRD §2.2.
    add_column :exercicios, :observation, :text
  end
end
