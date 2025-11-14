# app/controllers/api/v1/coach_dashboard_controller.rb
class Api::V1::CoachDashboardController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_coach!

  def show
    @personal = @current_user.personal
    
    # 1. Faturamento Total no Mês Atual
    start_of_month = Time.current.beginning_of_month
    end_of_month = Time.current.end_of_month
    total_revenue_current_month = @personal.pagamentos
                                         .where(status: :pago, paid_at: start_of_month..end_of_month)
                                         .sum(:amount)

    # 2. Contagem de Alunos Ativos
    # (Alunos com pelo menos uma assinatura ativa)
    active_students_count = @personal.alunos
                                     .joins(:assinaturas)
                                     .where(assinaturas: { status: :ativo })
                                     .distinct
                                     .count

    # 3. Pagamentos Atrasados
    overdue_payments_count = @personal.pagamentos
                                      .where(status: :pendente, due_date: ..Time.current)
                                      .count

    # 4. Dados para o Gráfico (Faturamento dos últimos 30 dias)
    pagamentos_last_30_days = @personal.pagamentos
                                       .where(status: :pago, paid_at: 30.days.ago.beginning_of_day..Time.current)
    
    # Agrupa os pagamentos por dia
    revenue_by_day = pagamentos_last_30_days.group_by { |p| p.paid_at.to_date }
                                            .transform_values { |payments| payments.sum(&:amount) }
    
    # Preenche os dias vazios com zero para o gráfico
    revenue_chart_data = (30.days.ago.to_date..Time.current.to_date).map do |date|
      {
        date: date.strftime("%d/%m"), # Formato para o gráfico
        total: revenue_by_day[date] || 0
      }
    end

    render json: {
      total_revenue_current_month: total_revenue_current_month,
      active_students_count: active_students_count,
      overdue_payments_count: overdue_payments_count,
      revenue_chart_data: revenue_chart_data
    }
  end

  private

  def authorize_coach!
    return if @current_user.personal?
    render json: { error: 'Acesso restrito a coaches.' }, status: :forbidden
  end
end