# app/models/training_block.rb
class TrainingBlock < ApplicationRecord
  belongs_to :personal
  belongs_to :aluno
  
  has_many :weeks, -> { order(week_number: :asc) }, dependent: :destroy
  has_many :treinos, through: :weeks

  validates :title, presence: true
  validates :weeks_duration, presence: true, numericality: { only_integer: true, greater_than: 0 }

  validates :start_date, presence: true
  validate :validate_reasonable_year

  private

  def validate_reasonable_year
    return unless start_date

    if start_date.year < 2024 || start_date.year > 2100
      errors.add(:start_date, "deve ter um ano válido (entre 2024 e 2100).")
    end
  end
end