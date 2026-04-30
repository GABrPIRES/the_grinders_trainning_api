# Centraliza a criação de notificações in-app e o disparo de e-mails transacionais.
#
# Regras:
#   - Alunos sempre recebem suas notificações (week_published).
#   - Coaches só recebem notificações se personal.notifications_enabled == true.
#   - E-mails só são enviados se AdminSetting.emails_enabled? == true E o coach optou
#     pelo evento específico.
module NotificationService
  # Cria notificação para qualquer usuário, sem verificação de preferências.
  # Usar para notificações de aluno.
  def self.notify(user:, type:, payload: {})
    user.notifications.create!(notification_type: type, payload: payload)
  end

  # Cria notificação para um coach, respeitando personal.notifications_enabled.
  def self.notify_coach(personal:, type:, payload: {})
    return unless personal&.notifications_enabled
    personal.user.notifications.create!(notification_type: type, payload: payload)
  end

  # Dispara o fluxo completo de "semana publicada":
  #   - Notificação in-app para o aluno
  #   - E-mail para o aluno (se feature flag ativa e coach optou)
  def self.on_week_published(week:, coach_user:)
    training_block = week.training_block
    aluno_user     = training_block.aluno.user
    personal       = training_block.personal

    notify(
      user:    aluno_user,
      type:    :week_published,
      payload: {
        week_id:     week.id,
        week_number: week.week_number,
        coach_name:  coach_user.name,
        block_title: training_block.title,
        route:       "/aluno/treinos"
      }
    )

    SendPushNotificationJob.perform_later(
      user_id: aluno_user.id,
      title:   "Novos treinos disponíveis 💪",
      body:    "Semana #{week.week_number} de \"#{training_block.title}\" publicada por #{coach_user.name}.",
      url:     "/aluno/treinos"
    )

    if AdminSetting.emails_enabled? && personal.email_students_on_publish
      WorkoutMailer.week_published(aluno_user, week, coach_user).deliver_later
    end
  end

  # Dispara o fluxo completo de "treino concluído":
  #   - Notificação in-app para o coach (se habilitado)
  #   - E-mail para o coach (se feature flag ativa e coach optou)
  def self.on_workout_completed(treino:, aluno_user:)
    personal  = treino.personal
    aluno     = aluno_user.aluno

    exercicios_data = treino.exercicios.includes(:sections).map do |ex|
      {
        name:     ex.name,
        sections: ex.sections.map do |s|
          {
            series:      s.series,
            reps:        s.reps,
            actual_load: s.actual_load,
            load_unit:   s.load_unit,
            actual_rpe:  s.actual_rpe,
            feito:       s.feito
          }
        end
      }
    end

    notify_coach(
      personal: personal,
      type:     :workout_completed,
      payload:  {
        treino_id:        treino.id,
        treino_name:      treino.name,
        aluno_name:       aluno_user.name,
        aluno_id:         aluno&.id,
        duration_seconds: treino.duration_seconds,
        exercicios:       exercicios_data,
        route:            "/coach/treinos/#{aluno&.id}/#{treino.id}"
      }
    )

    SendPushNotificationJob.perform_later(
      user_id: personal.user.id,
      title:   "#{aluno_user.name} concluiu um treino",
      body:    "#{treino.name}. Toque para ver detalhes.",
      url:     "/coach/treinos/#{aluno&.id}/#{treino.id}"
    )

    if AdminSetting.emails_enabled? && personal.email_on_workout_completed
      WorkoutMailer.workout_completed(personal.user, treino, aluno_user).deliver_later
    end
  end

  # Dispara o fluxo completo de "treino não realizado":
  #   - Notificação in-app para o coach (se habilitado)
  #   - E-mail para o coach (se feature flag ativa e coach optou)
  #   - Marca treino com missed_notified_at para não re-notificar
  def self.on_workout_missed(treino:)
    personal  = treino.personal
    aluno     = treino.week.training_block.aluno
    aluno_user = aluno.user

    notify_coach(
      personal: personal,
      type:     :workout_missed,
      payload:  {
        treino_id:   treino.id,
        treino_name: treino.name,
        aluno_name:  aluno_user.name,
        aluno_id:    aluno.id,
        route:       "/coach/students/#{aluno.id}"
      }
    )

    treino.update_column(:missed_notified_at, Time.current)

    SendPushNotificationJob.perform_later(
      user_id: personal.user.id,
      title:   "#{aluno_user.name} não realizou um treino",
      body:    "\"#{treino.name}\" não foi concluído.",
      url:     "/coach/students/#{aluno.id}"
    )

    if AdminSetting.emails_enabled? && personal.email_on_workout_missed
      WorkoutMailer.workout_missed(personal.user, treino).deliver_later
    end
  end
end
