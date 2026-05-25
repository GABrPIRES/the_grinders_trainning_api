class AddAiDuplicationModeToPersonals < ActiveRecord::Migration[8.0]
  def change
    add_column :personals, :ai_duplication_mode, :integer, default: 0, null: false
    add_index  :personals, :ai_duplication_mode
  end
end
