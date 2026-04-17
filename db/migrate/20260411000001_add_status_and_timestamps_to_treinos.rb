# db/migrate/20260411000001_add_status_and_timestamps_to_treinos.rb
class AddStatusAndTimestampsToTreinos < ActiveRecord::Migration[8.0]
  def change
    add_column :treinos, :status, :integer, default: 0, null: false
    add_column :treinos, :started_at, :datetime
    add_column :treinos, :finished_at, :datetime

    add_index :treinos, :status
  end
end
