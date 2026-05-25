# app/models/exercicio.rb
class Exercicio < ApplicationRecord
  belongs_to :treino

  # Um exercício tem muitas 'sections' (séries).
  has_many :sections, -> { order(created_at: :asc) }, dependent: :destroy

  accepts_nested_attributes_for :sections, allow_destroy: true

  validates :name, presence: true
  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :set_default_position, on: :create

  private

  # Position default = max+1 dentro do treino. Permite que callers passem
  # position explícita (ex: duplicações que copiam o position do source) sem
  # serem sobrescritos.
  def set_default_position
    return if position.present?
    self.position = (treino&.exercicios&.maximum(:position) || -1) + 1
  end
end
