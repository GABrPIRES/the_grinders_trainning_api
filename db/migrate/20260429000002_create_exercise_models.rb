class CreateExerciseModels < ActiveRecord::Migration[7.1]
  def change
    create_table :exercise_models, id: :uuid do |t|
      t.references :coach, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string  :name,          null: false
      t.string  :exercise_name, null: false
      t.decimal :load,          precision: 8, scale: 2
      t.string  :load_unit,     default: 'kg'
      t.integer :series
      t.string  :reps
      t.decimal :rpe,           precision: 4, scale: 1
      t.text    :coach_comment
      t.text    :video_link

      t.timestamps
    end
  end
end
