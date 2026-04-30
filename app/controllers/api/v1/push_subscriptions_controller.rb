# app/controllers/api/v1/push_subscriptions_controller.rb
class Api::V1::PushSubscriptionsController < ApplicationController
  before_action :authenticate_request, except: [:vapid_public_key]

  # GET /api/v1/push_subscriptions/vapid_public_key
  # Retorna a VAPID public key para o frontend gerar a subscription.
  def vapid_public_key
    render json: { vapid_public_key: ENV["VAPID_PUBLIC_KEY"] }
  end

  # POST /api/v1/push_subscriptions
  # Registra ou atualiza a subscription do dispositivo atual.
  def create
    sub = @current_user.push_subscriptions.find_or_initialize_by(
      endpoint: subscription_params[:endpoint]
    )
    sub.assign_attributes(
      p256dh:     subscription_params[:p256dh],
      auth:       subscription_params[:auth],
      user_agent: request.user_agent
    )

    if sub.save
      render json: { message: "Subscription registrada." }, status: :ok
    else
      render json: { error: sub.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/push_subscriptions
  # Remove a subscription do dispositivo atual.
  def destroy
    sub = @current_user.push_subscriptions.find_by(endpoint: params[:endpoint])
    sub&.destroy
    render json: { message: "Subscription removida." }
  end

  private

  def subscription_params
    params.require(:subscription).permit(:endpoint, :p256dh, :auth)
  end
end
