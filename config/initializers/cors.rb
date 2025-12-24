Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins do |source, env|
      if Rails.env.development?
        # In development, allow localhost and 127.0.0.1 on any port
        source =~ /\Ahttp:\/\/(localhost|127\.0\.0\.1)(:\d+)?\z/
      else
        # In production/staging, use strict whitelist from environment variable
        # Example: ALLOWED_ORIGINS=https://staging.yourfrontend.com,https://app.yourfrontend.com
        allowed_origins = ENV.fetch("ALLOWED_ORIGINS", "").split(",").map(&:strip)
        allowed_origins.include?(source)
      end
    end

    resource "*",
      headers: :any,
      expose: [ "CSRF-TOKEN" ],
      methods: [ :get, :post, :patch, :put, :delete, :options, :head ],
      credentials: true
  end
end