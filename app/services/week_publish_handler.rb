# app/services/week_publish_handler.rb
#
# Centraliza efeitos colaterais que acontecem quando uma semana é totalmente
# publicada pelo coach. Hoje:
#   - Expira a janela de feedback de semanas anteriores do mesmo bloco que
#     ainda estavam pendentes (sem submission e não expiradas).
#
# Idempotente: chamadas repetidas para a mesma semana não fazem nada de novo,
# porque o filtro pega só semanas com expired_at IS NULL.
class WeekPublishHandler
  FEEDBACK_NOTIFICATION_TYPES = %i[feedback_form_available feedback_form_reminder].freeze

  def self.expire_prior_weeks(published_week)
    block = published_week.training_block
    aluno = block.aluno
    return if aluno.nil?

    expired_week_ids = []

    block.weeks
         .feedback_active
         .where("weeks.week_number < ?", published_week.week_number)
         .find_each do |old_week|
      next if old_week.weekly_feedbacks.exists?(aluno: aluno)
      old_week.update_column(:expired_at, Time.current)
      expired_week_ids << old_week.id
    end

    mark_feedback_notifications_read(aluno.user, expired_week_ids) if expired_week_ids.any?
  end

  # Marca notificações de feedback (available/reminder) das semanas expiradas
  # como lidas para que não fiquem incomodando o aluno no dropdown ou push.
  def self.mark_feedback_notifications_read(user, week_ids)
    user.notifications
        .where(notification_type: FEEDBACK_NOTIFICATION_TYPES)
        .where("payload->>'week_id' IN (?)", week_ids.map(&:to_s))
        .where(read_at: nil)
        .update_all(read_at: Time.current)
  end
end
