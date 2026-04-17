# app/models/weekly_feedback.rb
class WeeklyFeedback < ApplicationRecord
  belongs_to :week
  belongs_to :aluno

  validates :week_id, uniqueness: { scope: :aluno_id, message: "já possui feedback para esta semana" }

  validates :sleep_level,     numericality: { only_integer: true, in: 1..10 }, allow_nil: true
  validates :stress_level,    numericality: { only_integer: true, in: 1..10 }, allow_nil: true
  validates :diet_level,      numericality: { only_integer: true, in: 1..10 }, allow_nil: true
  validates :training_desire, numericality: { only_integer: true, in: 1..10 }, allow_nil: true
  validates :body_weight,     numericality: { greater_than: 0 },               allow_nil: true
end
