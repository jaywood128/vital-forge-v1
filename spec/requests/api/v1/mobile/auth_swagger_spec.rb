# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "API V1 Mobile Authentication", type: :request do
  let!(:user) do
    u = User.new(
      email: "mobile.user@example.com",
      first_name: "Mobile",
      last_name: "User"
    )
    u.password = "Password123!"
    u.save!
    u
  end

  path "/api/v1/mobile/login" do
    post "Mobile Login (JWT)" do
      operationId "mobileLogin"
      tags "Mobile Authentication"
      consumes "application/json"
      produces "application/json"
      description "Authenticates a mobile user and returns a JWT token. Use this token in the Authorization header for subsequent requests."

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email, example: "mobile.user@example.com" },
              password: { type: :string, format: :password, example: "Password123!" }
            },
            required: [ "email", "password" ]
          }
        },
        required: [ "user" ]
      }

      response "200", "login successful" do
        schema type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                user: {
                  type: :object,
                  properties: {
                    id: { type: :integer, example: 1 },
                    email: { type: :string, example: "mobile.user@example.com" },
                    first_name: { type: :string, example: "Mobile" },
                    last_name: { type: :string, example: "User" },
                    full_name: { type: :string, example: "Mobile User" }
                  }
                },
                token: {
                  type: :string,
                  example: "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOjEsImVtYWlsIjoidXNlckBleGFtcGxlLmNvbSIsImV4cCI6MTcwMDAwMDAwMCwiaWF0IjoxNjk5OTEzNjAwfQ.abcdef123456",
                  description: "JWT token - use in Authorization header as 'Bearer <token>'"
                },
                expires_at: {
                  type: :string,
                  format: :"date-time",
                  example: "2024-11-24T12:00:00Z",
                  description: "Token expiration time (24 hours from login)"
                }
              }
            }
          }

        let(:credentials) do
          { user: { email: user.email, password: "Password123!" } }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["user"]["email"]).to eq(user.email)
          expect(data["data"]["token"]).to be_present
          expect(data["data"]["expires_at"]).to be_present

          # Verify token is valid JWT
          token = data["data"]["token"]
          decoded = JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: "HS256")
          expect(decoded[0]["sub"]).to eq(user.id)
        end
      end

      response "401", "invalid credentials" do
        schema type: :object,
          properties: {
            error: { type: :string, example: "Invalid email or password" }
          }

        let(:credentials) do
          { user: { email: user.email, password: "WrongPassword!" } }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Invalid email or password")
        end
      end

      response "401", "user not found" do
        schema type: :object,
          properties: {
            error: { type: :string, example: "Invalid email or password" }
          }

        let(:credentials) do
          { user: { email: "nonexistent@example.com", password: "Password123!" } }
        end

        run_test!
      end
    end
  end

  path "/api/v1/mobile/current_user" do
    get "Get Current Mobile User" do
      operationId "getCurrentMobileUser"
      tags "Mobile Authentication"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      description "Returns the currently authenticated user based on JWT token. Include the token in the Authorization header."

      parameter name: :Authorization,
                in: :header,
                type: :string,
                required: true,
                description: "JWT token in format: Bearer <token>",
                example: "Bearer eyJhbGciOiJIUzI1NiJ9..."

      response "200", "current user retrieved" do
        schema type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                user: {
                  type: :object,
                  properties: {
                    id: { type: :integer, example: 1 },
                    email: { type: :string, example: "mobile.user@example.com" },
                    first_name: { type: :string, example: "Mobile" },
                    last_name: { type: :string, example: "User" },
                    full_name: { type: :string, example: "Mobile User" },
                    created_at: { type: :string, format: :"date-time" },
                    last_login_at: { type: :string, format: :"date-time", nullable: true }
                  }
                }
              }
            }
          }

        let(:Authorization) do
          # Login to get token
          post api_v1_mobile_login_path,
            params: { user: { email: user.email, password: "Password123!" } },
            as: :json

          token = JSON.parse(response.body).dig("data", "token")
          "Bearer #{token}"
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["user"]["email"]).to eq(user.email)
          expect(data["data"]["user"]["id"]).to eq(user.id)
        end
      end

      response "401", "missing token" do
        schema type: :object,
          properties: {
            error: { type: :string, example: "Missing authentication token" }
          }

        let(:Authorization) { nil }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Missing authentication token")
        end
      end

      response "401", "invalid token" do
        schema type: :object,
          properties: {
            error: { type: :string, example: "Invalid or expired token" }
          }

        let(:Authorization) { "Bearer invalid_token_here" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Invalid or expired token")
        end
      end
    end
  end

  path "/api/v1/mobile/logout" do
    delete "Mobile Logout" do
      operationId "mobileLogout"
      tags "Mobile Authentication"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      description "Logs out the mobile user. Client should discard the JWT token after this call."

      parameter name: :Authorization,
                in: :header,
                type: :string,
                required: true,
                description: "JWT token in format: Bearer <token>",
                example: "Bearer eyJhbGciOiJIUzI1NiJ9..."

      response "204", "logout successful" do
        let(:Authorization) do
          # Login to get token
          post api_v1_mobile_login_path,
            params: { user: { email: user.email, password: "Password123!" } },
            as: :json

          token = JSON.parse(response.body).dig("data", "token")
          "Bearer #{token}"
        end

        run_test!
      end

      response "401", "missing token" do
        schema type: :object,
          properties: {
            error: { type: :string, example: "Missing authentication token" }
          }

        let(:Authorization) { nil }

        run_test!
      end
    end
  end
end
