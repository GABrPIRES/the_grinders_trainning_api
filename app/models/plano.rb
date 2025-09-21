# app/models/plano.rb
class Plano < ApplicationRecord
  belongs_to :personal
  has_many :assinaturas, dependent: :destroy

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :duration, presence: true, numericality: { only_integer: true, greater_than: 0 }
end