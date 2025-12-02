class Rack::Attack
    # Garante o uso do cache em memória
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  
    # 1. Permite tudo do Localhost (Opcional - ajuda a não se bloquear desenvolvendo)
    # safelist('allow-localhost') do |req|
    #   '127.0.0.1' == req.ip || '::1' == req.ip
    # end
  
    # 2. Proteção Geral (Throttle Global)
    throttle('req/ip', limit: 300, period: 5.minutes) do |req|
      req.ip
    end
  
    # 3. Proteção de Login (Brute Force por IP)
    # [CORREÇÃO] Mudamos para bloquear por IP, pois ler JSON no middleware é complexo/caro
    throttle('logins/ip', limit: 5, period: 60.seconds) do |req|
      if req.path == '/api/v1/login' && req.post?
        req.ip # Conta tentativas por IP nesta rota específica
      end
    end
  
    # 4. Resposta Personalizada (JSON)
    self.throttled_responder = lambda do |env|
      [ 429,
        { 'Content-Type' => 'application/json' },
        [{ error: 'Muitas tentativas de login. Aguarde alguns instantes.' }.to_json]
      ]
    end
  end