class AddMissedNotifiedAtToTreinos < ActiveRecord::Migration[8.0]
  def change
    add_column :treinos, :missed_notified_at, :datetime
  end
end
