# app/models/week.rb
class Week < ApplicationRecord
  belongs_to :training_block
  has_many :treinos, -> { order(day: :asc) }, dependent: :destroy

  validates :week_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
end