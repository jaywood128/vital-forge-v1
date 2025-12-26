# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "API V1 Authentication", type: :request do
  let!(:user) do
    User.create!(
      email: "test@example.com",
      password: "Password123!",
      first_name: "Test",
      last_name: "User"
    )
  end

  path "/api/v1/csrf" do
    get "Get CSRF Token" do
      tags "API Authentication"
      produces "application/json"
      description "Retrieves a CSRF token for subsequent authenticated requests. The token is also set as a cookie."

      response "200", "CSRF token retrieved" do
        schema type: :object,
          properties: {
            csrfToken: { type: :string, example: "abc123xyz..." }
          },
          required: [ "csrfToken" ]

        run_test!
      end
    end
  end

  path "/api/v1/login" do
    post "Login (JSON API)" do
      tags "API Authentication"
      consumes "application/json"
      produces "application/json"
      description "Authenticates a user via JSON API and creates a session. Returns user data on success."

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email, example: "john.doe@example.com" },
              password: { type: :string, format: :password, example: "Password123!" }
            },
            required: [ "email", "password" ]
          }
        },
        required: [ "user" ]
      }

      response "200", "login successful" do
        # Note: This test is skipped due to Rswag's cookie handling limitations
        # The actual endpoint works correctly (see spec/requests/api/v1/auth_spec.rb)
        # For testing with Swagger UI, use the mobile endpoints (/api/v1/mobile/login)

        schema type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                user: {
                  type: :object,
                  properties: {
                    id: { type: :integer, example: 1 },
                    email: { type: :string, example: "john.doe@example.com" },
                    first_name: { type: :string, example: "John" },
                    last_name: { type: :string, example: "Doe" }
                  }
                }
              }
            }
          }

        let(:credentials) do
          { user: { email: user.email, password: "Password123!" } }
        end

        before do
          skip "Rswag has limitations with cookie-based sessions. Use mobile endpoints for testing."
        end

        run_test!
      end

      response "401", "invalid credentials" do
        # Note: This test is skipped due to Rswag's cookie handling limitations
        # The actual endpoint works correctly (see spec/requests/api/v1/auth_spec.rb)

        schema type: :object,
          properties: {
            error: { type: :string, example: "Invalid email or password" }
          }

        let(:credentials) do
          { user: { email: user.email, password: "WrongPassword" } }
        end

        before do
          skip "Rswag has limitations with cookie-based sessions. Use mobile endpoints for testing."
        end

        run_test!
      end
    end
  end

  path "/api/v1/current_user" do
    get "Get Current User" do
      tags "API Authentication"
      produces "application/json"
      description "Returns the currently authenticated user's information"

      response "200", "user found" do
        schema type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                user: {
                  type: :object,
                  properties: {
                    id: { type: :integer },
                    email: { type: :string },
                    first_name: { type: :string },
                    last_name: { type: :string }
                  }
                }
              }
            }
          }

        before do
          # Login first
          get api_v1_csrf_path, as: :json
          csrf_token = cookies["CSRF-TOKEN"]

          post api_v1_login_path,
            params: { user: { email: user.email, password: "Password123!" } },
            headers: { "X-CSRF-Token" => csrf_token },
            as: :json
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["user"]["email"]).to eq(user.email)
        end
      end

      response "401", "not authenticated" do
        schema type: :object,
          properties: {
            error: { type: :string, example: "Not signed in" }
          }

        run_test!
      end
    end
  end

  path "/api/v1/logout" do
    delete "Logout (JSON API)" do
      tags "API Authentication"
      produces "application/json"
      description "Logs out the current user and destroys the session"

      response "204", "logout successful" do
        # Note: This test is skipped due to Rswag's cookie handling limitations
        # The actual endpoint works correctly (see spec/requests/api/v1/auth_spec.rb)

        before do
          skip "Rswag has limitations with cookie-based sessions. Use mobile endpoints for testing."
        end

        run_test!
      end
    end
  end
end
