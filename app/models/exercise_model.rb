# app/models/exercise_model.rb
class ExerciseModel < ApplicationRecord
  belongs_to :coach, class_name: "Personal"

  validates :name,          presence: true
  validates :exercise_name, presence: true

  def as_summary_json
    as_json(only: [:id, :name, :exercise_name, :load, :load_unit, :series, :reps, :rpe, :coach_comment, :video_link])
  end
end
