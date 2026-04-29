# app/models/notification.rb
class Notification < ApplicationRecord
  belongs_to :user

  enum :notification_type, {
    feedback_form_available: 0,
    feedback_form_reminder: 1,
    feedback_overdue_coach_alert: 2,
    coach_review_pending: 3,
    week_published: 4,
    workout_completed: 5,
    workout_missed: 6
  }

  scope :unread, -> { where(read_at: nil) }
  scope :for_user, ->(user) { where(user: user) }

  def mark_read!
    update!(read_at: Time.current) unless read_at
  end
end
