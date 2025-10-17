class RemoveDurationTimeFromTreinos < ActiveRecord::Migration[8.0]
  def change
    remove_column :treinos, :duration_time, :integer
  end
end
