# db/migrate/xxxxxxxx_add_aluno_to_training_blocks.rb
class AddAlunoToTrainingBlocks < ActiveRecord::Migration[8.0]
  def change
    add_reference :training_blocks, :aluno, null: true, foreign_key: true, type: :uuid
  end
end