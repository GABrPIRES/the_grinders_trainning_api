# Executa o envio de Web Push de forma assíncrona para não bloquear o request HTTP.
class SendPushNotificationJob < ApplicationJob
  queue_as :notifications

  def perform(user_id:, title:, body:, url: "/")
    user = User.find_by(id: user_id)
    return unless user

    PushNotificationService.notify(user: user, title: title, body: body, url: url)
  end
end
