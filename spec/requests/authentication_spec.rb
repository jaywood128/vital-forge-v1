# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Authentication API", type: :request do
  # Helper to create a test user
  let(:test_user) do
    User.create!(
      email: "test@example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      first_name: "Test",
      last_name: "User"
    )
  end

  path "/login" do
    post "User login" do
      tags "Authentication"
      consumes "application/json", "application/x-www-form-urlencoded"
      produces "text/html", "application/json"
      description "Authenticates a user and creates a session. Returns HTML redirect on success or renders login form with errors."

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email, example: "john.doe@example.com" },
          password: { type: :string, format: :password, example: "Password123!" }
        },
        required: [ "email", "password" ]
      }

      response "302", "successful login - redirects to dashboard" do
        let(:credentials) do
          {
            email: test_user.email,
            password: "Password123!"
          }
        end

        before { test_user } # Ensure user exists

        run_test! do |response|
          expect(response).to redirect_to(dashboard_path)
          expect(session[:user_id]).to eq(test_user.id)
        end
      end

      response "422", "invalid credentials" do
        let(:credentials) do
          {
            email: "wrong@example.com",
            password: "wrongpassword"
          }
        end

        run_test! do |response|
          expect(response.body).to include("Invalid email or password")
        end
      end

      response "422", "account locked" do
        let(:locked_user) do
          User.create!(
            email: "locked@example.com",
            password: "Password123!",
            password_confirmation: "Password123!",
            first_name: "Locked",
            last_name: "User",
            failed_login_attempts: 5,
            locked_at: Time.current
          )
        end

        let(:credentials) do
          {
            email: locked_user.email,
            password: "Password123!"
          }
        end

        before { locked_user } # Ensure locked user exists

        run_test! do |response|
          expect(response.body).to include("Account is locked")
        end
      end
    end
  end

  path "/logout" do
    delete "User logout" do
      tags "Authentication"
      produces "text/html"
      description "Logs out the current user and destroys their session. Requires active session."

      response "302", "successful logout - redirects to root" do
        before do
          # Simulate logged-in user
          post login_path, params: { email: test_user.email, password: "Password123!" }
        end

        run_test! do |response|
          expect(response).to redirect_to(root_path)
          expect(session[:user_id]).to be_nil
        end
      end

      response "302", "logout without session - still redirects" do
        run_test! do |response|
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end
end
