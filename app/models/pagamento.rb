# app/models/pagamento.rb
class Pagamento < ApplicationRecord
  belongs_to :aluno
  belongs_to :personal

  # Status: 0 para 'pendente', 1 para 'pago', 2 para 'atrasado'
  enum status: { pendente: 0, pago: 1, atrasado: 2 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :due_date, presence: true
  validates :status, presence: true
end