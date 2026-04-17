# db/migrate/20260411000005_create_weekly_feedbacks.rb
class CreateWeeklyFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :weekly_feedbacks, id: :uuid do |t|
      t.references :week, type: :uuid, null: false, foreign_key: true
      t.references :aluno, type: :uuid, null: false, foreign_key: true

      t.integer :sleep_level
      t.integer :stress_level
      t.integer :diet_level
      t.float :body_weight
      t.integer :training_desire
      t.text :general_evaluation

      t.timestamps
    end

    # Um aluno só pode ter UM feedback por semana.
    add_index :weekly_feedbacks, [ :week_id, :aluno_id ], unique: true
  end
end
