class AddNotificationPrefsToPersonals < ActiveRecord::Migration[8.0]
  def change
    add_column :personals, :notifications_enabled,        :boolean, default: true, null: false
    add_column :personals, :email_on_workout_completed,   :boolean, default: true, null: false
    add_column :personals, :email_on_workout_missed,      :boolean, default: true, null: false
    add_column :personals, :email_students_on_publish,    :boolean, default: true, null: false
  end
end
