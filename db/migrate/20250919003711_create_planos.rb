# db/migrate/xxxxxxxx_create_planos.rb
class CreatePlanos < ActiveRecord::Migration[8.0]
  def change
    create_table :planos, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.float :price, null: false
      t.integer :duration, null: false # Duração em dias
      t.references :personal, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end
  end
end