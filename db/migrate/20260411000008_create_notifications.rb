# db/migrate/20260411000008_create_notifications.rb
class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.integer :notification_type, null: false
      t.jsonb :payload, default: {}, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [ :user_id, :read_at ]
    add_index :notifications, :notification_type
  end
end
