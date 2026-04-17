# app/jobs/weekly_feedback_coach_alert_job.rb
#
# Alerta coaches quando alunos não preencheram o formulário semanal até o prazo.
# Deve rodar domingo às 23:00 (America/Sao_Paulo).
# Configurado em config/recurring.yml para SolidQueue.
class WeeklyFeedbackCoachAlertJob < ApplicationJob
  queue_as :notifications

  def perform
    overdue_weeks.each do |week|
      aluno = week.training_block.aluno
      personal = week.training_block.personal

      next unless week.feedback_available?(aluno) # ainda pendente

      personal.user.notifications.create!(
        notification_type: :feedback_overdue_coach_alert,
        payload: {
          week_id: week.id,
          aluno_id: aluno.id,
          aluno_name: aluno.user.name,
          message: "#{aluno.user.name} não preencheu o formulário semanal. Entre em contato para desbloqueio."
        }
      )

      week.update_columns(coach_alerted_at: Time.current)
    end
  end

  private

  def overdue_weeks
    tz = ActiveSupport::TimeZone["America/Sao_Paulo"]
    deadline_passed = tz.now.beginning_of_day

    Week.joins(training_block: :aluno)
        .where(coach_alerted_at: nil)
        .where.not(snoozed_at: nil)
        .where("weeks.end_date < ?", deadline_passed.to_date)
        .includes(training_block: [ :aluno, :personal ])
  end
end
