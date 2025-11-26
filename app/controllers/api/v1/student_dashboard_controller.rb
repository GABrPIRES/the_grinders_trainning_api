# app/controllers/api/v1/student_dashboard_controller.rb
class Api::V1::StudentDashboardController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_aluno!

  def show
    aluno = @current_user.aluno

    # 1. Status da Assinatura e Pagamento
    assinatura = aluno.assinaturas.where(status: :ativo).first
    proximo_pagamento = aluno.pagamentos.where(status: :pendente).order(:due_date).first
    
    status_financeiro = if proximo_pagamento && proximo_pagamento.due_date < Date.today
                          'vencido'
                        elsif assinatura
                          'ativo'
                        else
                          'inativo'
                        end

    # 2. Bloco e Semana Atual
    active_block = aluno.training_blocks.order(start_date: :desc).first
    current_week_info = nil
    
    if active_block && active_block.start_date.present?
      today = Date.today
      # Encontra a semana que engloba hoje
      current_week = active_block.weeks.find { |w| w.start_date && w.end_date && (w.start_date..w.end_date).cover?(today) }
      
      # Se não achar (ex: feriado ou intervalo), pega a próxima ou a última
      current_week ||= active_block.weeks.where("start_date >= ?", today).order(:start_date).first
      
      if current_week
        current_week_info = {
          number: current_week.week_number,
          start_date: current_week.start_date,
          end_date: current_week.end_date,
          id: current_week.id # ID para o link
        }
      end
    end

    # 3. Próximo Treino (ou treino de hoje)
    # Busca o primeiro treino a partir de hoje
    next_workout = nil
    if active_block
        next_workout_record = Treino.joins(:week)
                                    .where(weeks: { training_block_id: active_block.id })
                                    .where("day >= ?", Date.today)
                                    .order(:day)
                                    .first
        
        if next_workout_record
            next_workout = {
                id: next_workout_record.id,
                name: next_workout_record.name,
                day: next_workout_record.day
            }
        end
    end

    # 4. Estatísticas Rápidas (Treinos feitos no bloco atual)
    # Consideramos 'feito' se a data do treino já passou (simplificação)
    # ou poderíamos contar sections.feito (mais preciso, mas mais pesado)
    treinos_concluidos = 0
    if active_block
         treinos_concluidos = Treino.joins(:week)
                                    .where(weeks: { training_block_id: active_block.id })
                                    .where("day < ?", Date.today)
                                    .count
    end

    render json: {
      student_name: @current_user.name,
      status_financeiro: status_financeiro,
      plano_nome: assinatura&.plano&.name || 'Sem Plano',
      vencimento: proximo_pagamento&.due_date,
      active_block: active_block ? { title: active_block.title, id: active_block.id } : nil,
      current_week: current_week_info,
      next_workout: next_workout,
      treinos_concluidos: treinos_concluidos
    }
  end

  private

  def authorize_aluno!
    return if @current_user.aluno?
    render json: { error: 'Acesso restrito a alunos.' }, status: :forbidden
  end
end