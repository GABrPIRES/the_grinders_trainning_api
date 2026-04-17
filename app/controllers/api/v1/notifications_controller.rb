# app/controllers/api/v1/notifications_controller.rb
class Api::V1::NotificationsController < ApplicationController
  before_action :authenticate_request

  # GET /api/v1/notifications
  # Retorna notificações não lidas do usuário logado (máximo 50).
  def index
    @notifications = @current_user.notifications.unread.order(created_at: :desc).limit(50)
    render json: @notifications.map { |n|
      {
        id: n.id,
        type: n.notification_type,
        payload: n.payload,
        created_at: n.created_at
      }
    }
  end

  # POST /api/v1/notifications/:id/read
  # Marca a notificação como lida.
  def read
    notification = @current_user.notifications.find(params[:id])
    notification.mark_read!
    render json: { message: "Notificação marcada como lida." }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Notificação não encontrada." }, status: :not_found
  end
end
