# Envia Web Push para todos os dispositivos com opt-in de um usuário.
# Trata subscriptions expiradas (410) removendo-as automaticamente.
module PushNotificationService
  VAPID = {
    public_key:  ENV["VAPID_PUBLIC_KEY"],
    private_key: ENV["VAPID_PRIVATE_KEY"],
    subject:     ENV["VAPID_MAILTO"]
  }.freeze

  def self.notify(user:, title:, body:, url: "/")
    return unless AdminSetting.push_enabled?

    subscriptions = user.push_subscriptions
    return if subscriptions.none?

    message = JSON.generate({ title: title, body: body, url: url })

    subscriptions.each do |sub|
      WebPush.payload_send(
        message:      message,
        endpoint:     sub.endpoint,
        p256dh:       sub.p256dh,
        auth:         sub.auth,
        vapid:        VAPID,
        ttl:          86_400
      )
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      sub.destroy
    rescue => e
      Rails.logger.error("[PushNotificationService] Erro: #{e.class} — #{e.message}")
    end
  end
end
