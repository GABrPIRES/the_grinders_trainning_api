class AddAiEnabledGlobalToAdminSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_settings, :ai_enabled_global, :boolean, default: true, null: false
  end
end
