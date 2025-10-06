# app/models/personal.rb
class Personal < ApplicationRecord
    # Um perfil 'Personal' pertence a um 'User'.
    belongs_to :user
  
    # Um 'Personal' pode ter muitos 'Alunos'.
    # O 'foreign_key' especifica qual coluna na tabela 'alunos' aponta para este personal.
    # 'dependent: :nullify' significa que se um personal for deletado,
    # o campo 'personal_id' dos seus alunos será setado para nulo, mas os alunos não serão deletados.
    has_many :alunos, foreign_key: 'personal_id', dependent: :nullify
    has_many :payment_methods, dependent: :destroy
 
    # Relações com outras partes do sistema
    has_many :treinos, dependent: :destroy
    has_many :planos, dependent: :destroy
    has_many :pagamentos, dependent: :destroy
  end