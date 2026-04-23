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

  private

  def authorize_coach!
    return if @current_user.personal?
    render json: { error: 'Acesso restrito a coaches.' }, status: :forbidden
  end
end
