Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Use environment variable for allowed origins, falling back to localhost for development
    # Example ENV value: "https://myapp.com,https://staging.myapp.com"
    origins do |source, env|
      allowed_origins = ENV.fetch('ALLOWED_ORIGINS', 'http://localhost:3001').split(',')
      allowed_origins.include?(source)
    end

    resource '*',
      headers: :any,
      expose: ['CSRF-TOKEN'],
      methods: [:get, :post, :patch, :put, :delete, :options, :head],
      credentials: true
  end
end