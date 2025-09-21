# app/models/exercicio.rb
class Exercicio < ApplicationRecord
  belongs_to :treino

  # Um exercício tem muitas 'sections' (séries).
  has_many :sections, dependent: :destroy

  accepts_nested_attributes_for :sections, allow_destroy: true

  validates :name, presence: true
end