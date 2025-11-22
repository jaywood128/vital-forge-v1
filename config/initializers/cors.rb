Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:3001', 'https://next.yourdomain.com' # Next.js dev/prod
    resource '*',
      headers: :any,
      expose: ['CSRF-TOKEN'],
      methods: [:get, :post, :patch, :put, :delete, :options, :head],
      credentials: true
  end
end