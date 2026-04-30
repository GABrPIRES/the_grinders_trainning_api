class AddPushEnabledToAdminSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_settings, :push_enabled, :boolean, default: false, null: false
  end
end
