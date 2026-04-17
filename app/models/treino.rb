# app/models/treino.rb
class Treino < ApplicationRecord
  belongs_to :week

  has_many :exercicios, dependent: :destroy
  has_many :sections, through: :exercicios
  has_many :ai_load_suggestions, through: :sections

  accepts_nested_attributes_for :exercicios, allow_destroy: true

  enum :status, { draft: 0, published: 1, in_progress: 2, completed: 3 }

  validates :name, presence: true
  validates :day, presence: true

  # Duração oficial em segundos, calculada no servidor.
  # Retorna nil se o treino ainda não foi iniciado ou finalizado.
  def duration_seconds
    return nil unless started_at && finished_at

    (finished_at - started_at).to_i
  end
end
