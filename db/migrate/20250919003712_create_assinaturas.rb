# db/migrate/xxxxxxxx_create_assinaturas.rb
class CreateAssinaturas < ActiveRecord::Migration[8.0]
  def change
    create_table :assinaturas, id: :uuid do |t|
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.integer :status, null: false, default: 0 # Default para 'ativo'
      t.references :aluno, type: :uuid, null: false, foreign_key: true
      t.references :plano, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end
  end
end