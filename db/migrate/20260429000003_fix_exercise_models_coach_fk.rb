class FixExerciseModelsCoachFk < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :exercise_models, column: :coach_id
    add_foreign_key :exercise_models, :personals, column: :coach_id
  end
end
