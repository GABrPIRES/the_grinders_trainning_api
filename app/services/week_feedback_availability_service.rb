# app/services/week_feedback_availability_service.rb
#
# Deriva o estado de disponibilidade do formulário semanal para um aluno,
# sem persistir nenhuma flag no banco (tudo é computado on-the-fly).
class WeekFeedbackAvailabilityService
  # Timezone padrão para o deadline de domingo 23:59:59.
  # TODO: externalizar para config quando o app for multi-timezone.
  DEADLINE_TIMEZONE = "America/Sao_Paulo".freeze

  def initialize(aluno)
    @aluno = aluno
  end

  # Retorna o hash de status ou nil se não há formulário pendente.
  # { week_id:, deadline_at:, incomplete_treinos: [], start_date:, end_date:, date_range_label: }
  def pending_week
    week = find_week_pending_feedback
    return nil unless week

    {
      week_id: week.id,
      deadline_at: deadline_for(week),
      incomplete_treinos: week.incomplete_treino_names,
      start_date: week.start_date,
      end_date: week.end_date,
      date_range_label: week.date_range_label
    }
  end

  private

  # Busca qualquer semana do aluno onde o feedback ainda está disponível.
  # Percorre apenas semanas ativas (não expiradas), da mais recente para a mais antiga.
  def find_week_pending_feedback
    weeks = Week.feedback_active
                .joins(training_block: :aluno)
                .where(training_blocks: { aluno_id: @aluno.id })
                .joins(:treinos)
                .distinct
                .order('weeks.created_at DESC')

    weeks.find { |w| w.feedback_available?(@aluno) }
  end

  # Deadline: próximo domingo 23:59:59 no timezone de SP.
  # Se o último treino já está na semana corrente, o deadline é o domingo dessa semana.
  def deadline_for(week)
    last_day = week.last_treino_date || Date.current
    tz = ActiveSupport::TimeZone[DEADLINE_TIMEZONE]

    # Avança para o domingo da mesma semana (wday 0).
    days_until_sunday = (7 - last_day.wday) % 7
    days_until_sunday = 7 if days_until_sunday.zero? # já é domingo → próximo domingo

    sunday = last_day + days_until_sunday
    tz.local(sunday.year, sunday.month, sunday.day, 23, 59, 59)
  end
end
