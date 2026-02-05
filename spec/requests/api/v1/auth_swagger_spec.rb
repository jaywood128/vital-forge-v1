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

  path "/api/v1/health" do
    get "Health check" do
      operationId "getHealth"
      tags "Health"
      produces "text/plain"
      description "Returns 200 OK if the API is up. Used by load balancers and uptime monitors."

      response "200", "API is healthy" do
        run_test! do |response|
          expect(response.body).to eq("ok")
        end
      end
    end
  end

  path "/api/v1/csrf" do
    get "Get CSRF Token" do
      operationId "getCsrfToken"
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
      operationId "login"
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
              email: { type: :string, format: :email, example: "new.user@example.com" },
              password: { type: :string, format: :password, example: "SecurePass123!" }
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
      operationId "getCurrentUser"
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
      operationId "logout"
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

  path "/api/v1/signup" do
    post "Register (signup)" do
      operationId "signup"
      tags "Users"
      consumes "application/json"
      produces "application/json"
      description "Creates a new user account. Automatically logs in the user and sets session."

      parameter name: :registration, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email, example: "new.user@example.com" },
              password: { type: :string, format: :password, example: "SecurePass123!" },
              password_confirmation: { type: :string, format: :password, example: "SecurePass123!" },
              first_name: { type: :string, example: "New" },
              last_name: { type: :string, example: "User" }
            },
            required: %w[email password password_confirmation first_name last_name]
          }
        },
        required: [ "user" ]
      }

      response "201", "user created" do
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
                },
                message: { type: :string }
              }
            }
          }

        let(:registration) do
          {
            user: {
              email: "signup.test@example.com",
              password: "Password123!",
              password_confirmation: "Password123!",
              first_name: "Signup",
              last_name: "Test"
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["user"]["email"]).to eq("signup.test@example.com")
        end
      end

      response "422", "validation error" do
        schema type: :object,
          properties: {
            errors: {
              type: :object,
              additionalProperties: {
                type: :array,
                items: { type: :string }
              }
            }
          }

        let(:registration) do
          {
            user: {
              email: "invalid",
              password: "short",
              password_confirmation: "mismatch",
              first_name: "",
              last_name: ""
            }
          }
        end

        run_test!
      end
    end
  end
end
