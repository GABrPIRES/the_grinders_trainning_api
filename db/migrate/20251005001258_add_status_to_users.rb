# db/migrate/xxxxxxxx_add_status_to_users.rb
class AddStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :status, :integer, null: false, default: 0
  end
end