# app/models/aluno.rb
class Aluno < ApplicationRecord
  belongs_to :user
  belongs_to :personal

  has_many :assinaturas, dependent: :destroy
  has_many :pagamentos, dependent: :destroy
  has_many :training_blocks, dependent: :destroy
end