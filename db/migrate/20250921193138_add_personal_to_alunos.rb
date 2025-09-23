class AddPersonalToAlunos < ActiveRecord::Migration[8.0]
  def change
    add_reference :alunos, :personal, type: :uuid, null: false, foreign_key: true
  end
end
