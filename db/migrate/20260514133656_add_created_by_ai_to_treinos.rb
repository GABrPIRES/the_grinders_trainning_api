class AddCreatedByAiToTreinos < ActiveRecord::Migration[8.0]
  def change
    add_column :treinos, :created_by_ai, :boolean, default: false, null: false
    add_index :treinos, :created_by_ai
  end
end
