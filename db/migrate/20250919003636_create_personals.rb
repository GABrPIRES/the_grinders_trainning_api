# db/migrate/xxxxxxxx_create_personals.rb
class CreatePersonals < ActiveRecord::Migration[8.0]
  def change
    # A chave primária :id será a mesma do usuário (UUID)
    create_table :personals, id: :uuid do |t|
      # Adicionamos a referência explícita ao User
      t.references :user, type: :uuid, null: false, foreign_key: true

      t.text :bio
      t.string :phone_number
      t.string :instagram

      t.timestamps
    end
  end
end