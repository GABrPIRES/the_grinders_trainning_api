# db/migrate/xxxxxxxx_create_exercicios.rb
class CreateExercicios < ActiveRecord::Migration[8.0]
  def change
    create_table :exercicios, id: :uuid do |t|
      t.string :name, null: false
      t.references :treino, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end
  end
end