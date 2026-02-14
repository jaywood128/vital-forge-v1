# Only configure Rswag::Ui if the gem is loaded (development environment)
if defined?(Rswag::Ui)
  Rswag::Ui.configure do |c|
    # List the Swagger endpoints that you want to be documented through the
    # swagger-ui. The first parameter is the path (absolute or relative to the UI
    # host) to the corresponding endpoint and the second is a title that will be
    # displayed in the document selector.
    # NOTE: If you're using rspec-api to expose Swagger files
    # (under openapi_root) as JSON or YAML endpoints, then the list below should
    # correspond to the relative paths for those endpoints.

    c.swagger_endpoint "/openapi/v1/swagger.yaml", "VitalForge API V1"

    # Add Basic Auth in case your API is private
    # This is a secondary layer - the primary auth is via middleware
    if ENV["SWAGGER_BASIC_AUTH_USERNAME"].present? && ENV["SWAGGER_BASIC_AUTH_PASSWORD"].present?
      c.basic_auth_enabled = true
      c.basic_auth_credentials ENV["SWAGGER_BASIC_AUTH_USERNAME"], ENV["SWAGGER_BASIC_AUTH_PASSWORD"]
    end
  end
end
