# app/models/ai_load_suggestion.rb
class AiLoadSuggestion < ApplicationRecord
  belongs_to :section

  enum :status, { pending: 0, approved: 1, rejected: 2 }

  validates :suggested_load, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Escopo auxiliar para buscar sugestões de um treino inteiro.
  scope :for_treino, ->(treino_id) {
    joins(section: :exercicio).where(exercicios: { treino_id: treino_id })
  }
end
