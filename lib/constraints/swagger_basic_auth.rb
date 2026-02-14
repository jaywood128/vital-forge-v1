# frozen_string_literal: true

module Constraints
  # Route constraint that enforces HTTP Basic Authentication for Swagger/API docs.
  # Uses environment variables for credentials:
  #   - SWAGGER_BASIC_AUTH_USERNAME
  #   - SWAGGER_BASIC_AUTH_PASSWORD
  #
  # Usage in routes.rb:
  #   constraints Constraints::SwaggerBasicAuth.new do
  #     mount Rswag::Ui::Engine => "/api-docs"
  #   end
  class SwaggerBasicAuth
    def matches?(request)
      return false unless credentials_configured?

      authenticate(request)
    end

    private

    def credentials_configured?
      username.present? && password.present?
    end

    def username
      @username ||= ENV["SWAGGER_BASIC_AUTH_USERNAME"]
    end

    def password
      @password ||= ENV["SWAGGER_BASIC_AUTH_PASSWORD"]
    end

    def authenticate(request)
      # Extract credentials from Authorization header
      auth_header = request.headers["Authorization"]
      return false unless auth_header&.start_with?("Basic ")

      # Decode Base64 credentials
      encoded_credentials = auth_header.delete_prefix("Basic ")
      decoded = Base64.decode64(encoded_credentials)
      provided_username, provided_password = decoded.split(":", 2)

      # Use secure_compare to prevent timing attacks
      username_matches = ActiveSupport::SecurityUtils.secure_compare(
        username.to_s,
        provided_username.to_s
      )
      password_matches = ActiveSupport::SecurityUtils.secure_compare(
        password.to_s,
        provided_password.to_s
      )

      username_matches && password_matches
    rescue StandardError => e
      Rails.logger.warn("Swagger Basic Auth failed: #{e.message}")
      false
    end
  end
end
