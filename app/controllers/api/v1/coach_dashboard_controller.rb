# app/controllers/api/v1/coach_dashboard_controller.rb
class Api::V1::CoachDashboardController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_coach!

  def show
    @personal = @current_user.personal
    period = (params[:period] || 30).to_i.clamp(1, 365)

    # 1. Faturamento mês atual
    start_of_month = Time.current.beginning_of_month
    end_of_month   = Time.current.end_of_month
    total_revenue_current_month = @personal.pagamentos
                                           .where(status: :pago, paid_at: start_of_month..end_of_month)
                                           .sum(:amount)

    # 2. Faturamento mês anterior (para trend)
    start_of_last_month = Time.current.last_month.beginning_of_month
    end_of_last_month   = Time.current.last_month.end_of_month
    total_revenue_previous_month = @personal.pagamentos
                                            .where(status: :pago, paid_at: start_of_last_month..end_of_last_month)
                                            .sum(:amount)

    # 3. Alunos ativos e total
    active_students_count = @personal.alunos
                                     .joins(:assinaturas)
                                     .where(assinaturas: { status: :ativo })
                                     .distinct
                                     .count
    total_students_count = @personal.alunos.count

    # 4. Pagamentos atrasados
    overdue_payments_count = @personal.pagamentos
                                      .where(status: :pendente, due_date: ..Time.current)
                                      .count

    # 5. Revisões IA pendentes para este coach
    pending_ai_reviews_count = AiLoadSuggestion.pending
                                               .joins(section: { exercicio: :treino })
                                               .where(treinos: { personal_id: @personal.id })
                                               .count

    # 6. Dados para o gráfico conforme período solicitado
    start_date = period.days.ago.beginning_of_day
    pagamentos_period = @personal.pagamentos
                                 .where(status: :pago, paid_at: start_date..Time.current)

    if period <= 90
      revenue_by_day = pagamentos_period.group_by { |p| p.paid_at.to_date }
                                        .transform_values { |payments| payments.sum(&:amount) }
      revenue_chart_data = (period.days.ago.to_date..Time.current.to_date).map do |date|
        { date: date.strftime("%d/%m"), total: revenue_by_day[date] || 0 }
      end
    else
      revenue_by_month = pagamentos_period.group_by { |p| p.paid_at.beginning_of_month.to_date }
                                          .transform_values { |payments| payments.sum(&:amount) }
      start_month = period.days.ago.to_date.beginning_of_month
      end_month   = Time.current.to_date.beginning_of_month
      months = []
      m = start_month
      while m <= end_month
        months << m
        m = m >> 1
      end
      revenue_chart_data = months.map do |month|
        { date: month.strftime("%b/%y"), total: revenue_by_month[month] || 0 }
      end
    end

    render json: {
      total_revenue_current_month:  total_revenue_current_month,
      total_revenue_previous_month: total_revenue_previous_month,
      active_students_count:        active_students_count,
      total_students_count:         total_students_count,
      overdue_payments_count:       overdue_payments_count,
      pending_ai_reviews_count:     pending_ai_reviews_count,
      revenue_chart_data:           revenue_chart_data
    }
  end

  def training_stats
    @personal   = @current_user.personal
    start_date, end_date = resolve_date_range
    aluno_id    = params[:aluno_id].presence

    # Escopo de alunos deste coach
    aluno_scope = @personal.alunos.joins(:user)
    aluno_scope = aluno_scope.where('alunos.id = ?', aluno_id) if aluno_id
    aluno_ids   = aluno_scope.pluck(:id)

    # Treinos não-draft do período (filtra por treinos.day)
    period_treinos = Treino
      .joins(week: :training_block)
      .where(personal_id: @personal.id, training_blocks: { aluno_id: aluno_ids })
      .where(day: start_date.beginning_of_day..end_date.end_of_day)
      .where.not(status: :draft)

    # Alunos sem treino publicado no período
    alunos_com_treino_ids = period_treinos
      .distinct
      .pluck(Arel.sql('training_blocks.aluno_id'))

    alunos_sem_treino = aluno_scope
      .where.not(id: alunos_com_treino_ids)
      .map { |a| { id: a.id, name: a.user.name, email: a.user.email } }

    # IDs de treinos ativos (in_progress ou completed)
    active_treino_ids = period_treinos
      .where(status: [ :in_progress, :completed ])
      .pluck(:id)

    # Engagement global (uma query)
    agg = Section
      .joins(exercicio: :treino)
      .where(treinos: { id: active_treino_ids })
      .pick(
        Arel.sql('COUNT(*)'),
        Arel.sql('SUM(CASE WHEN sections.feito = true THEN 1 ELSE 0 END)'),
        Arel.sql('SUM(CASE WHEN sections.actual_load IS NOT NULL THEN 1 ELSE 0 END)'),
        Arel.sql('SUM(CASE WHEN sections.actual_rpe  IS NOT NULL THEN 1 ELSE 0 END)')
      )
    total_s, feito_c, load_c, rpe_c = (agg || [0, 0, 0, 0]).map(&:to_i)

    # Engagement por aluno (uma query)
    section_stats = Section
      .joins(exercicio: { treino: { week: :training_block } })
      .where(treinos: { id: active_treino_ids })
      .group(Arel.sql('training_blocks.aluno_id'))
      .pluck(
        Arel.sql('training_blocks.aluno_id'),
        Arel.sql('COUNT(*)'),
        Arel.sql('SUM(CASE WHEN sections.feito = true THEN 1 ELSE 0 END)'),
        Arel.sql('SUM(CASE WHEN sections.actual_load IS NOT NULL THEN 1 ELSE 0 END)'),
        Arel.sql('SUM(CASE WHEN sections.actual_rpe  IS NOT NULL THEN 1 ELSE 0 END)')
      )
      .each_with_object({}) { |(aid, tot, f, l, r), h|
        h[aid] = { total: tot.to_i, feito: f.to_i, load: l.to_i, rpe: r.to_i }
      }

    # Contagem de treinos por aluno (uma query)
    treinos_stats = Treino
      .joins(week: :training_block)
      .where(id: active_treino_ids)
      .group(Arel.sql('training_blocks.aluno_id'))
      .pluck(
        Arel.sql('training_blocks.aluno_id'),
        Arel.sql('SUM(CASE WHEN treinos.status = 2 THEN 1 ELSE 0 END)'),
        Arel.sql('SUM(CASE WHEN treinos.status = 3 THEN 1 ELSE 0 END)')
      )
      .each_with_object({}) { |(aid, inp, comp), h|
        h[aid] = { in_progress: inp.to_i, completed: comp.to_i }
      }

    students_engagement = aluno_scope.filter_map do |a|
      s = section_stats[a.id]
      next unless s && s[:total] > 0
      t = treinos_stats[a.id] || { in_progress: 0, completed: 0 }
      {
        aluno_id:            a.id,
        name:                a.user.name,
        total_sections:      s[:total],
        feito_pct:           pct(s[:feito], s[:total]),
        load_pct:            pct(s[:load],  s[:total]),
        rpe_pct:             pct(s[:rpe],   s[:total]),
        treinos_in_progress: t[:in_progress],
        treinos_completed:   t[:completed],
      }
    end.sort_by { |s| s[:feito_pct] }

    # Treinos com pelo menos um dado preenchido
    treinos_com_dados = Section
      .joins(exercicio: :treino)
      .where(treinos: { id: active_treino_ids })
      .where('sections.feito = true OR sections.actual_load IS NOT NULL OR sections.actual_rpe IS NOT NULL')
      .distinct
      .pluck(Arel.sql('treinos.id'))

    workouts_without_engagement = Treino
      .joins(week: :training_block)
      .joins('JOIN alunos ON alunos.id = training_blocks.aluno_id JOIN users ON users.id = alunos.user_id')
      .where(id: active_treino_ids)
      .where.not(id: treinos_com_dados)
      .pluck(
        Arel.sql('treinos.id'),
        Arel.sql('treinos.name'),
        Arel.sql('treinos.status'),
        Arel.sql('treinos.day'),
        Arel.sql('users.name')
      )
      .map { |id, name, status, day, aluno_name|
        {
          treino_id:   id,
          treino_name: name,
          aluno_name:  aluno_name,
          status:      Treino.statuses.key(status.to_i),
          day:         day&.strftime('%d/%m/%Y'),
        }
      }

    render json: {
      period: { start_date: start_date, end_date: end_date },
      students_without_workouts:          alunos_sem_treino,
      students_without_workouts_count:    alunos_sem_treino.size,
      engagement_global: {
        total_sections: total_s,
        feito_pct:      pct(feito_c, total_s),
        load_pct:       pct(load_c,  total_s),
        rpe_pct:        pct(rpe_c,   total_s),
      },
      students_engagement:                students_engagement,
      workouts_without_engagement:        workouts_without_engagement,
      workouts_without_engagement_count:  workouts_without_engagement.size,
    }
  end

  private

  def resolve_date_range
    if params[:start_date].present? && params[:end_date].present?
      [Date.parse(params[:start_date]), Date.parse(params[:end_date])]
    else
      period = (params[:period] || 30).to_i.clamp(1, 365)
      [period.days.ago.to_date, Date.current]
    end
  rescue ArgumentError
    [30.days.ago.to_date, Date.current]
  end

  def pct(count, total)
    return 0.0 if total.zero?
    ((count.to_f / total) * 100).round(1)
  end

  def authorize_coach!
    return if @current_user.personal?
    render json: { error: 'Acesso restrito a coaches.' }, status: :forbidden
  end
end
