class AddExpiredAtToWeeks < ActiveRecord::Migration[8.0]
  def change
    add_column :weeks, :expired_at, :datetime
    add_index :weeks, [:training_block_id, :expired_at]
  end
end
