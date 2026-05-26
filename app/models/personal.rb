class Personal < ApplicationRecord
  belongs_to :user
  has_many :alunos, foreign_key: 'personal_id', dependent: :nullify
  has_many :payment_methods, dependent: :destroy
  has_many :training_blocks, dependent: :destroy
  has_many :treinos, dependent: :destroy
  has_many :planos, dependent: :destroy
  has_many :pagamentos, dependent: :destroy
  has_many :exercise_models, foreign_key: 'coach_id', dependent: :destroy

  # Como a IA deve duplicar a semana ao receber o feedback do aluno:
  #   - preserve (default): duplica source.treinos sem mexer no que já existe
  #     na target_week (drafts manuais do coach são preservados lado a lado).
  #   - destructive: apaga TODOS os treinos da target_week antes de duplicar.
  # Prefix evita conflito com possíveis futuros enums de "mode".
  enum :ai_duplication_mode, { preserve: 0, destructive: 1 }, prefix: :duplication_mode

  # Ranges editáveis pelo coach (cap conservador, divergem dos do admin).
  # Sprint 012 — usados pelo AiConfigResolver e validados pelo controller.
  COACH_AI_RANGES = {
    ai_max_load_increase_pct: 0..25,
    ai_critical_delta_pct:    5..25,
    ai_sleep_threshold:       1..7,
    ai_stress_threshold:      4..10
  }.freeze

  validate :validate_ai_config_ranges

  # IA de auto-regulação de cargas roda para este coach apenas se as três flags
  # estão habilitadas:
  #   - admin ativou IA globalmente (AdminSetting.ai_enabled_global)
  #   - admin habilitou IA especificamente para este coach (ai_enabled_by_admin)
  #   - o próprio coach não se autodesativou (ai_enabled)
  def ai_runs?
    AdminSetting.ai_enabled_global? && ai_enabled_by_admin && ai_enabled
  end

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

  private

  # Sprint 012: cap conservador no que o coach pode setar para os
  # parâmetros guardrail da IA. Admin tem ranges mais largos (validados
  # no Admin::AiConfigsController). Se valor for nil, ignora (fallback
  # para admin default via AiConfigResolver).
  def validate_ai_config_ranges
    COACH_AI_RANGES.each do |attr, range|
      val = self[attr]
      next if val.nil?
      unless range.cover?(val.to_f)
        errors.add(attr, "deve estar entre #{range.min} e #{range.max}")
      end
    end
  end
end