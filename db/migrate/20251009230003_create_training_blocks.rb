# db/migrate/xxxxxxxx_create_training_blocks.rb
class CreateTrainingBlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :training_blocks, id: :uuid do |t|
      t.string :title
      t.integer :weeks_duration, default: 5 # <--- AJUSTE 1: Adicionado o default
      t.references :personal, null: false, foreign_key: true, type: :uuid # <--- AJUSTE 2: Adicionado type: :uuid
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end