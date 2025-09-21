# db/migrate/xxxxxxxx_create_pagamentos.rb
class CreatePagamentos < ActiveRecord::Migration[8.0]
  def change
    create_table :pagamentos, id: :uuid do |t|
      t.float :amount, null: false
      t.integer :status, null: false, default: 0 # Default para 'pendente'
      t.datetime :due_date, null: false
      t.datetime :paid_at
      t.references :aluno, type: :uuid, null: false, foreign_key: true
      t.references :personal, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end
  end
end