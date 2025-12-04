# config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      'http://localhost:3001',                    # dev
      'http://localhost:3000',                    # (se usar essa porta em dev, opcional)
      'https://thegrinderspowerlifting.com.br',   # domínio sem www
      'https://www.thegrinderspowerlifting.com.br' # domínio com www
    )

    resource '*',
      headers: :any,
      methods: %i[get post put patch delete options head],
      credentials: true
  end
end
