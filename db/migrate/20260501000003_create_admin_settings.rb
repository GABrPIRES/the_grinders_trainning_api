class CreateAdminSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_settings, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.boolean :emails_enabled, default: false, null: false
      t.timestamps
    end
  end
end
