# db/migrate/xxxxxxxx_create_treinos.rb
class CreateTreinos < ActiveRecord::Migration[8.0]
  def change
    # A chave primária :id será um UUID
    create_table :treinos, id: :uuid do |t|
      t.string :name, null: false
      t.integer :duration_time, null: false
      t.datetime :day, null: false

      # Chaves estrangeiras para aluno e personal, também como UUID
      t.references :aluno, type: :uuid, null: false, foreign_key: true
      t.references :personal, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end
  end
end