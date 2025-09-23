# app/models/aluno.rb
class Aluno < ApplicationRecord
  # Um perfil 'Aluno' pertence a um 'User'.
  belongs_to :user

  # Um 'Aluno' pertence a um 'Personal' (treinador).
  # A associação é opcional, pois um aluno pode existir sem um treinador.
  belongs_to :personal

  # Relações com outras partes do sistema
  has_many :treinos, dependent: :destroy
  has_many :assinaturas, dependent: :destroy
  has_many :pagamentos, dependent: :destroy
end