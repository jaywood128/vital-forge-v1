# frozen_string_literal: true

module Middleware
  # Middleware that sends HTTP 401 Unauthorized with WWW-Authenticate header
  # when a request is made to Swagger routes without valid credentials.
  # This triggers the browser's Basic Auth login prompt.
  class SwaggerAuth
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      # Only intercept Swagger/OpenAPI routes
      if swagger_route?(request.path)
        constraint = Constraints::SwaggerBasicAuth.new

        unless constraint.matches?(request)
          return unauthorized_response
        end
      end

      @app.call(env)
    end

    private

    def swagger_route?(path)
      path.start_with?("/api-docs") || path.start_with?("/openapi")
    end

    def unauthorized_response
      [
        401,
        {
          "Content-Type" => "text/plain",
          "WWW-Authenticate" => 'Basic realm="Swagger Documentation"'
        },
        [ "Unauthorized - Valid credentials required" ]
      ]
    end
  end
end
