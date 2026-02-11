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

  path "/api/v1/mobile/signup" do
    post "Mobile Signup (Registration)" do
      operationId "mobileSignup"
      tags "Mobile Authentication"
      consumes "application/json"
      produces "application/json"
      description "Creates a new user account for mobile and returns a JWT token. Use this token in the Authorization header for subsequent requests. Copy the returned token and click 'Authorize' in Swagger UI to test protected endpoints."

      parameter name: :user_data, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email, example: "newuser@example.com" },
              password: { type: :string, format: :password, example: "Password123!" },
              password_confirmation: { type: :string, format: :password, example: "Password123!" },
              first_name: { type: :string, example: "John" },
              last_name: { type: :string, example: "Doe" }
            },
            required: [ "email", "password", "password_confirmation", "first_name", "last_name" ]
          }
        },
        required: [ "user" ]
      }

      response "201", "signup successful" do
        schema type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                user: {
                  type: :object,
                  properties: {
                    id: { type: :integer, example: 1 },
                    email: { type: :string, example: "newuser@example.com" },
                    first_name: { type: :string, example: "John" },
                    last_name: { type: :string, example: "Doe" }
                  }
                },
                token: {
                  type: :string,
                  example: "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOjEsImVtYWlsIjoidXNlckBleGFtcGxlLmNvbSIsImV4cCI6MTcwMDAwMDAwMCwiaWF0IjoxNjk5OTEzNjAwfQ.abcdef123456",
                  description: "JWT token - copy this and click 'Authorize' button to use in protected endpoints"
                },
                expires_at: {
                  type: :string,
                  format: :"date-time",
                  example: "2024-11-24T12:00:00Z",
                  description: "Token expiration time (24 hours from signup)"
                },
                message: {
                  type: :string,
                  example: "Account created successfully! Welcome, John!"
                }
              }
            }
          }

        let(:user_data) do
          {
            user: {
              email: "newmobileuser@example.com",
              password: "Password123!",
              password_confirmation: "Password123!",
              first_name: "New",
              last_name: "MobileUser"
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["user"]["email"]).to eq("newmobileuser@example.com")
          expect(data["data"]["token"]).to be_present
          expect(data["data"]["expires_at"]).to be_present
          expect(data["data"]["message"]).to include("Welcome")

          # Verify token is valid JWT
          token = data["data"]["token"]
          decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256")
          expect(decoded[0]["sub"]).to be_present
        end
      end

      response "422", "validation errors" do
        schema type: :object,
          properties: {
            errors: {
              type: :object,
              additionalProperties: {
                type: :array,
                items: { type: :string }
              },
              example: {
                email: [ "can't be blank", "is invalid" ],
                password: [ "is too short (minimum is 8 characters)" ]
              }
            }
          }

        let(:user_data) do
          {
            user: {
              email: "invalid-email",
              password: "short",
              password_confirmation: "short",
              first_name: "",
              last_name: ""
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end

      response "422", "email already taken" do
        schema type: :object,
          properties: {
            errors: {
              type: :object,
              example: {
                email: [ "has already been taken" ]
              }
            }
          }

        let(:user_data) do
          {
            user: {
              email: user.email, # Using existing user's email
              password: "Password123!",
              password_confirmation: "Password123!",
              first_name: "Duplicate",
              last_name: "User"
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]["email"]).to include("Email has already been taken")
        end
      end
    end
  end

  path "/api/v1/mobile/login" do
    post "Mobile Login (JWT)" do
      operationId "mobileLogin"
      tags "Mobile Authentication"
      consumes "application/json"
      produces "application/json"
      description "Authenticates a mobile user and returns a JWT token. Copy the returned token and click 'Authorize' in Swagger UI to test protected endpoints."

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email, example: "newuser@example.com" },
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
          decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256")
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
      description "Returns the currently authenticated user based on JWT token. First login or signup to get a token, then click 'Authorize' button at the top right and paste the token."

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
      description "Logs out the mobile user. Use the 'Authorize' button at the top right to set your JWT token. Client should discard the JWT token after this call."

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
