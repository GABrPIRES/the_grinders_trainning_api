# app/jobs/workout_missed_check_job.rb
#
# Verifica treinos que não foram realizados após o fim da semana e notifica o coach.
# Roda semanalmente (ver config/recurring.yml).
# Idempotente: usa missed_notified_at para não re-notificar o mesmo treino.
class WorkoutMissedCheckJob < ApplicationJob
  queue_as :notifications

  def perform
    missed_treinos.each do |treino|
      NotificationService.on_workout_missed(treino: treino)
    rescue => e
      Rails.logger.error("[WorkoutMissedCheckJob] Erro ao notificar treino #{treino.id}: #{e.message}")
    end
  end

  private

  def missed_treinos
    Treino
      .joins(week: { training_block: [ :aluno, :personal ] })
      .where(status: [ Treino.statuses[:published], Treino.statuses[:in_progress] ])
      .where(missed_notified_at: nil)
      .where("weeks.end_date < ?", Date.current)
      .includes(week: { training_block: [ :aluno, :personal ] })
  end
end
