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
  def self.expire_prior_weeks(published_week)
    block = published_week.training_block
    aluno = block.aluno
    return if aluno.nil?

    block.weeks
         .feedback_active
         .where("weeks.week_number < ?", published_week.week_number)
         .find_each do |old_week|
      next if old_week.weekly_feedbacks.exists?(aluno: aluno)
      old_week.update_column(:expired_at, Time.current)
    end
  end
end
