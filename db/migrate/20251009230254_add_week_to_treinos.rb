# db/migrate/xxxxxxxx_add_week_to_treinos.rb
class AddWeekToTreinos < ActiveRecord::Migration[8.0]
  def change
    # Adiciona a referência para a semana, PERMITINDO nulos por enquanto
    add_reference :treinos, :week, type: :uuid, foreign_key: true, null: true # <--- A MUDANÇA ESTÁ AQUI

    # Remove a referência antiga para aluno
    remove_reference :treinos, :aluno, type: :uuid, foreign_key: true
  end
end