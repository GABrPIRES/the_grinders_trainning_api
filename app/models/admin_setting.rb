# Singleton de configurações globais da plataforma.
# Apenas uma linha deve existir na tabela — use AdminSetting.instance.
class AdminSetting < ApplicationRecord
  def self.instance
    first_or_create!
  end

  def self.emails_enabled?
    instance.emails_enabled
  end
end
