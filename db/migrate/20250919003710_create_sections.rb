# db/migrate/xxxxxxxx_create_sections.rb
class CreateSections < ActiveRecord::Migration[8.0]
  def change
    create_table :sections, id: :uuid do |t|
      t.float :carga
      t.integer :series
      t.integer :reps
      t.string :equip
      t.float :rpe
      t.float :pr
      t.boolean :feito, default: false
      t.references :exercicio, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end
  end
end