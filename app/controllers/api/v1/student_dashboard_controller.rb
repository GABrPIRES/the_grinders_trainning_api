# app/controllers/api/v1/student_dashboard_controller.rb
class Api::V1::StudentDashboardController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_aluno!

  def show
    aluno = @current_user.aluno

    # 1. Status Financeiro
    # Prioridade: 1. Pagamento Vencido -> 2. Assinatura Ativa -> 3. Inativo
    assinatura = aluno.assinaturas.find_by(status: :ativo)
    pagamento_atrasado = aluno.pagamentos.find_by(status: :atrasado)
    # Considera vencido se está atrasado explicitamente OU se está pendente e venceu ontem ou antes
    pagamento_pendente_vencido = aluno.pagamentos.where(status: :pendente).where("due_date < ?", Date.today).exists?
    
    status_financeiro = if pagamento_atrasado || pagamento_pendente_vencido
                          'vencido'
                        elsif assinatura
                          'ativo'
                        else
                          'inativo'
                        end
    
    # Pega o próximo boleto para exibir a data
    proximo_pagamento = aluno.pagamentos.where(status: :pendente).order(:due_date).first

    # 2. Bloco e Semana Atual
    active_block = aluno.training_blocks.order(start_date: :desc).first
    current_week_info = nil
    
    if active_block
      today = Date.today
      # Tenta achar a semana exata pela data de hoje
      current_week = active_block.weeks.find { |w| w.start_date && w.end_date && (w.start_date..w.end_date).cover?(today) }
      
      # Fallback 1: Pega a próxima semana que vai começar (se hoje for domingo e semana começa segunda)
      current_week ||= active_block.weeks.where("start_date >= ?", today).order(:start_date).first
      
      # Fallback 2: Se o bloco já acabou, mostra a última semana para ele ver o histórico
      current_week ||= active_block.weeks.order(:week_number).last

      if current_week
        current_week_info = {
          number: current_week.week_number,
          start_date: current_week.start_date,
          end_date: current_week.end_date,
          id: current_week.id
        }
      end
    end

    # 3. Próximo Treino
    next_workout = nil
    if active_block
        # Busca o primeiro treino de hoje ou futuro
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

    # 4. Estatísticas Reais (Treinos Concluídos)
    # [CORREÇÃO] Conta treinos onde PELO MENOS UMA série foi marcada como 'feita'.
    # Isso é muito mais preciso do que apenas olhar a data.
    treinos_concluidos = 0
    if active_block
         treinos_concluidos = Treino.joins(week: :training_block, exercicios: :sections)
                                    .where(training_blocks: { id: active_block.id })
                                    .where(sections: { feito: true })
                                    .distinct # Garante que se ele fez 10 séries no mesmo treino, conta como 1 treino
                                    .count
    end

    render json: {
      # ... (restante do json igual)
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