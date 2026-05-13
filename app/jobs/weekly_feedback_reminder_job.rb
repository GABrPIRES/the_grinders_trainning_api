# app/jobs/weekly_feedback_reminder_job.rb
#
# Envia lembretes para alunos que escolheram "responder depois" no formulário semanal.
# Configurado no SolidQueue recurring para rodar algumas vezes ao dia (ver config/recurring.yml).
class WeeklyFeedbackReminderJob < ApplicationJob
  queue_as :notifications

  REMINDER_INTERVAL = 6.hours

  def perform
    weeks_needing_reminder.each do |week|
      aluno = week.training_block.aluno
      next unless week.feedback_available?(aluno)

      last_notif = last_reminder_for(aluno, week)
      next if last_notif && last_notif.created_at > REMINDER_INTERVAL.ago

      # Dedup: marca reminders antigos do mesmo aluno+semana como lidos antes
      # de criar o novo. Mantém no máximo 1 reminder não-lido por semana.
      previous_reminders_for(aluno, week).update_all(read_at: Time.current)

      aluno.user.notifications.create!(
        notification_type: :feedback_form_reminder,
        payload: {
          week_id: week.id,
          message: "Não esqueça de preencher o formulário semanal!",
          deadline_at: deadline_for(week)
        }
      )
    end
  end

  private

  def weeks_needing_reminder
    Week.feedback_active
        .joins(training_block: :aluno)
        .where.not(snoozed_at: nil)
        .where(coach_alerted_at: nil)
        .includes(training_block: :aluno)
  end

  def previous_reminders_for(aluno, week)
    aluno.user.notifications
         .where(notification_type: :feedback_form_reminder)
         .where("payload->>'week_id' = ?", week.id)
         .where(read_at: nil)
  end

  def last_reminder_for(aluno, week)
    aluno.user.notifications
         .where(notification_type: :feedback_form_reminder)
         .where("payload->>'week_id' = ?", week.id)
         .order(created_at: :desc)
         .first
  end

  def deadline_for(week)
    tz = ActiveSupport::TimeZone["America/Sao_Paulo"]
    last_day = week.last_treino_date || Date.current
    days_until_sunday = (7 - last_day.wday) % 7
    days_until_sunday = 7 if days_until_sunday.zero?
    sunday = last_day + days_until_sunday
    tz.local(sunday.year, sunday.month, sunday.day, 23, 59, 59).iso8601
  end
end
