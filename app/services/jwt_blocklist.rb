class JwtBlocklist
  CACHE_NAMESPACE = "jwt_blocklist".freeze

  def self.add(jti, exp)
    ttl = exp.to_i - Time.now.to_i
    return if ttl <= 0

    Rails.cache.write(key_for(jti), true, expires_in: ttl.seconds)
  end

  def self.blocked?(jti)
    Rails.cache.exist?(key_for(jti))
  end

  def self.key_for(jti)
    "#{CACHE_NAMESPACE}:#{jti}"
  end
end
