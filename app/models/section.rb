# app/models/section.rb
class Section < ApplicationRecord
  belongs_to :exercicio
  has_many :ai_load_suggestions, dependent: :destroy

  validates :load_unit, inclusion: { in: %w[kg lb rir %], allow_nil: true }, allow_blank: true
end
