class Personal < ApplicationRecord
  belongs_to :user
  has_many :alunos, foreign_key: 'personal_id', dependent: :nullify
  has_many :payment_methods, dependent: :destroy
  has_many :training_blocks, dependent: :destroy
  has_many :treinos, dependent: :destroy
  has_many :planos, dependent: :destroy
  has_many :pagamentos, dependent: :destroy

  # Retorna o código atual se válido, ou gera um novo
  def active_signup_code
    if signup_code.present? && signup_code_expires_at > Time.current
      signup_code
    else
      rotate_signup_code!
    end
  end

  def rotate_signup_code!
    loop do
      self.signup_code = SecureRandom.alphanumeric(6).upcase
      break unless Personal.exists?(signup_code: signup_code)
    end
    self.signup_code_expires_at = 7.days.from_now
    save!
    signup_code
  end
end