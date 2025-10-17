# app/models/treino.rb
class Treino < ApplicationRecord
  belongs_to :week

  has_many :exercicios, dependent: :destroy

  accepts_nested_attributes_for :exercicios, allow_destroy: true

  validates :name, presence: true
  validates :day, presence: true
end