# app/controllers/api/v1/notifications_controller.rb
class Api::V1::NotificationsController < ApplicationController
  before_action :authenticate_request

  # GET /api/v1/notifications
  # Retorna notificações do usuário. filter=all retorna todas; padrão retorna não lidas.
  def index
    scope = @current_user.notifications.order(created_at: :desc).limit(50)
    scope = scope.unread unless params[:filter] == "all"
    render json: scope.map { |n| serialize(n) }
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

  # POST /api/v1/notifications/read_all
  # Marca todas as notificações não lidas como lidas.
  def read_all
    @current_user.notifications.unread.update_all(read_at: Time.current)
    render json: { message: "Todas as notificações foram marcadas como lidas." }
  end

  private

  def serialize(n)
    {
      id:         n.id,
      type:       n.notification_type,
      payload:    n.payload,
      read_at:    n.read_at,
      created_at: n.created_at
    }
  end
end
