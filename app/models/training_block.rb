# app/models/training_block.rb
class TrainingBlock < ApplicationRecord
  belongs_to :personal
  belongs_to :aluno
  
  has_many :weeks, -> { order(week_number: :asc) }, dependent: :destroy
  has_many :treinos, through: :weeks

  validates :title, presence: true
  validates :weeks_duration, presence: true, numericality: { only_integer: true, greater_than: 0 }
end