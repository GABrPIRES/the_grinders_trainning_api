# app/models/section.rb
class Section < ApplicationRecord
  belongs_to :exercicio
  validates :load_unit, inclusion: { in: %w[kg lb rir %], allow_nil: true }, allow_blank: true
end