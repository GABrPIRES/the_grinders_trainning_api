# app/models/user.rb
class User < ApplicationRecord
    has_secure_password
  
    enum :role, { admin: 0, personal: 1, aluno: 2 }
    enum :status, { ativo: 0, inativo: 1 }
  
    validates :name, presence: true
    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
    has_one :personal, dependent: :destroy
    has_one :aluno, dependent: :destroy

    def as_json(options = {})
      super(options.merge(except: [:password_digest]))
    end
  end