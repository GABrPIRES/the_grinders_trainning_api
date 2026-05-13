# app/models/user.rb
class User < ApplicationRecord
    has_secure_password
  
    enum :role, { admin: 0, personal: 1, aluno: 2 }
    enum :status, { 
    ativo: 0, 
    inativo: 1,
    unverified: 2,  # Criou conta, falta e-mail
    pending: 3,     # E-mail ok, falta coach aprovar
    rejected: 4     # Coach rejeitou
   }
  
    validates :name, presence: true
    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password,
      length: { minimum: 12, message: "deve ter pelo menos 12 caracteres" },
      format: {
        with: /\A(?=.*[A-Z])(?=.*[a-z])(?=.*\d).+\z/,
        message: "deve conter maiúscula, minúscula e número"
      },
      if: -> { password.present? }
  
    has_one :personal, dependent: :destroy
    has_one :aluno, dependent: :destroy
    has_many :notifications, dependent: :destroy
    has_many :push_subscriptions, dependent: :destroy

    before_create :generate_verification_token, if: -> { unverified? && aluno? }

    PASSWORD_RESET_EXPIRY = 1.hour

    def generate_password_reset_token!
      self.password_reset_token = SecureRandom.urlsafe_base64(32)
      self.password_reset_sent_at = Time.current
      save!(validate: false)
      password_reset_token
    end

    def password_reset_expired?
      password_reset_sent_at.nil? || password_reset_sent_at < PASSWORD_RESET_EXPIRY.ago
    end

    def clear_password_reset_token!
      update_columns(password_reset_token: nil, password_reset_sent_at: nil)
    end

    SENSITIVE_FIELDS = %i[
      password_digest
      password_reset_token
      password_reset_sent_at
      verification_token
    ].freeze

    def serializable_hash(options = nil)
      options ||= {}
      excepted = SENSITIVE_FIELDS + Array(options[:except])
      super(options.merge(except: excepted))
    end

    private

    def generate_verification_token
      self.verification_token = SecureRandom.urlsafe_base64
    end
  end