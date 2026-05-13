# app/models/week.rb
class Week < ApplicationRecord
  belongs_to :training_block
  has_many :treinos, -> { order(day: :asc) }, dependent: :destroy
  has_many :weekly_feedbacks, dependent: :destroy

  enum :periodization_goal, { overload: 0, maintenance: 1, deload: 2 }

  validates :week_number, presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :feedback_active, -> { where(expired_at: nil) }
  scope :feedback_expired, -> { where.not(expired_at: nil) }

  def feedback_expired?
    expired_at.present?
  end

  # O formulário semanal fica disponível quando:
  # 1. A semana não está com janela de feedback expirada (semana posterior já publicada).
  # 2. Há pelo menos um treino não-draft na semana.
  # 3. Ainda não há weekly_feedback para esta semana + aluno.
  # 4. E uma das condições de gatilho:
  #    a. O último treino da semana (por dia) foi concluído (completed), OU
  #    b. É domingo a partir das 12h no fuso de SP.
  # Treinos draft (aguardando aprovação do coach) são ignorados propositalmente.
  def feedback_available?(aluno)
    return false if feedback_expired?
    return false if treinos.where.not(status: :draft).none?
    return false if weekly_feedbacks.exists?(aluno: aluno)

    last_treino_completed? || sunday_noon?
  end

  # Label formatado "DD/MM a DD/MM" usado no banner/modal do front.
  def date_range_label
    return nil unless start_date && end_date
    "#{start_date.strftime('%d/%m')} a #{end_date.strftime('%d/%m')}"
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
