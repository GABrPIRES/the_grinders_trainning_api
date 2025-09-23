# app/models/assinatura.rb
class Assinatura < ApplicationRecord
  belongs_to :aluno
  belongs_to :plano

  # Status: 0 para 'ativo', 1 para 'expirado', 2 para 'cancelado'
  enum :status, { ativo: 0, expirado: 1, cancelado: 2 }

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :status, presence: true
end