# app/models/week.rb
class Week < ApplicationRecord
  belongs_to :training_block
  has_many :treinos, -> { order(day: :asc) }, dependent: :destroy
  has_many :weekly_feedbacks, dependent: :destroy

  enum :periodization_goal, { overload: 0, maintenance: 1, deload: 2 }

  validates :week_number, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # O formulário semanal fica disponível quando:
  # 1. Há pelo menos um treino não-draft na semana.
  # 2. Ainda não há weekly_feedback para esta semana + aluno.
  # 3. E uma das condições de gatilho:
  #    a. O último treino da semana (por dia) foi concluído (completed), OU
  #    b. É domingo a partir das 12h no fuso de SP.
  # Treinos draft (aguardando aprovação do coach) são ignorados propositalmente.
  def feedback_available?(aluno)
    return false if treinos.where.not(status: :draft).none?
    return false if weekly_feedbacks.exists?(aluno: aluno)

    last_treino_completed? || sunday_noon?
  end

  # Retorna nomes dos treinos não-draft que ainda não foram concluídos.
  def incomplete_treino_names
    treinos.where.not(status: [ :draft, :completed ]).order(:day).pluck(:name)
  end

  def last_treino
    treinos.reorder(day: :desc, created_at: :desc).first
  end

  def last_treino_date
    last_treino&.day&.to_date
  end

  private

  def last_treino_completed?
    last_treino&.completed? || false
  end

  def sunday_noon?
    now = ActiveSupport::TimeZone["America/Sao_Paulo"].now
    now.sunday? && now.hour >= 12
  end
end
