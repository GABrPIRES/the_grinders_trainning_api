class Api::V1::Coach::NotificationPreferencesController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_coach!

  # GET /api/v1/coach/notification_preferences
  def show
    render json: preferences_json
  end

  # PATCH /api/v1/coach/notification_preferences
  def update
    if @current_user.personal.update(allowed_params)
      render json: preferences_json
    else
      render json: { errors: @current_user.personal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def allowed_params
    params.require(:notification_preferences).permit(
      :notifications_enabled,
      :email_on_workout_completed,
      :email_on_workout_missed,
      :email_students_on_publish
    )
  end

  def preferences_json
    p = @current_user.personal
    {
      notifications_enabled:      p.notifications_enabled,
      email_on_workout_completed: p.email_on_workout_completed,
      email_on_workout_missed:    p.email_on_workout_missed,
      email_students_on_publish:  p.email_students_on_publish,
      emails_globally_enabled:    AdminSetting.emails_enabled?
    }
  end

  def authorize_coach!
    unless @current_user.personal?
      render json: { error: "Acesso restrito a coaches." }, status: :forbidden
    end
  end
end
