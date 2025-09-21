# app/models/treino.rb
class Treino < ApplicationRecord
  belongs_to :aluno
  belongs_to :personal

  # Um treino tem muitos exercícios.
  # 'dependent: :destroy' garante que se o treino for apagado,
  # todos os exercícios dentro dele também serão.
  has_many :exercicios, dependent: :destroy

  accepts_nested_attributes_for :exercicios, allow_destroy: true

  validates :name, presence: true
  validates :duration_time, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :day, presence: true
end