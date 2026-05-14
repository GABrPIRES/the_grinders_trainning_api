class AddAiFlagsToPersonals < ActiveRecord::Migration[8.0]
  def change
    add_column :personals, :ai_enabled_by_admin, :boolean, default: true, null: false
    add_column :personals, :ai_enabled, :boolean, default: true, null: false
    add_index :personals, [:ai_enabled_by_admin, :ai_enabled]
  end
end
