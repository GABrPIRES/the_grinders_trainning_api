# db/migrate/20260411000007_add_snooze_and_alert_to_weeks.rb
class AddSnoozeAndAlertToWeeks < ActiveRecord::Migration[8.0]
  def change
    # Registra quando o aluno escolheu "responder depois" no formulário semanal.
    add_column :weeks, :snoozed_at, :datetime

    # Registra quando o coach foi alertado sobre feedback não preenchido.
    # Usada para garantir idempotência do alerta (não repetir notificação).
    add_column :weeks, :coach_alerted_at, :datetime
  end
end
