# app/models/payment_method.rb
class PaymentMethod < ApplicationRecord
  belongs_to :personal

  enum :method_type, { pix: 0, bank_account: 1 }

  validates :method_type, presence: true
  validates :details, presence: true
end