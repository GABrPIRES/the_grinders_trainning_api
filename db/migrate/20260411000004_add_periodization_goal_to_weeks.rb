# db/migrate/20260411000004_add_periodization_goal_to_weeks.rb
class AddPeriodizationGoalToWeeks < ActiveRecord::Migration[8.0]
  def change
    # Periodização é por semana, podendo variar dentro de um mesmo training_block.
    # Default maintenance para não impactar semanas já criadas.
    add_column :weeks, :periodization_goal, :integer, default: 1, null: false
    add_index :weeks, :periodization_goal
  end
end
