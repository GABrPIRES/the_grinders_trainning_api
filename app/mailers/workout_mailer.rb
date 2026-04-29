class WorkoutMailer < ApplicationMailer
  LOGO_PATH = "/images/logos/logo_transparent.png"

  # Notifica o aluno quando todos os treinos da semana foram publicados.
  def week_published(aluno_user, week, coach_user)
    @aluno      = aluno_user
    @week       = week
    @coach      = coach_user
    @block      = week.training_block
    @logo_url   = "#{frontend_url}#{LOGO_PATH}"

    destinatario = Rails.env.development? ? "gabriellaeon@gmail.com" : @aluno.email

    mail(
      to:      destinatario,
      subject: "Semana #{@week.week_number} publicada — seus treinos estão prontos!"
    )
  end

  # Notifica o coach quando um aluno conclui um treino.
  def workout_completed(coach_user, treino, aluno_user)
    @coach      = coach_user
    @treino     = treino
    @aluno      = aluno_user
    @logo_url   = "#{frontend_url}#{LOGO_PATH}"
    @sections   = build_sections_summary(treino)

    destinatario = Rails.env.development? ? "gabriellaeon@gmail.com" : @coach.email

    mail(
      to:      destinatario,
      subject: "#{@aluno.name} concluiu um treino"
    )
  end

  # Notifica o coach quando um aluno não realizou um treino.
  def workout_missed(coach_user, treino)
    @coach      = coach_user
    @treino     = treino
    @aluno      = treino.week.training_block.aluno.user
    @logo_url   = "#{frontend_url}#{LOGO_PATH}"

    destinatario = Rails.env.development? ? "gabriellaeon@gmail.com" : @coach.email

    mail(
      to:      destinatario,
      subject: "#{@aluno.name} não realizou um treino"
    )
  end

  private

  def frontend_url
    Rails.env.development? ? "http://localhost:3001" : ENV.fetch("FRONTEND_URL", "https://thegrinderspowerlifting.com.br")
  end

  def build_sections_summary(treino)
    treino.exercicios.includes(:sections).flat_map do |ex|
      ex.sections.map do |s|
        {
          exercise: ex.name,
          feito:    s.feito,
          load:     s.actual_load,
          rpe:      s.actual_rpe,
          reps:     s.reps,
          series:   s.series
        }
      end
    end
  end
end
