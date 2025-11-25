# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Users API", type: :request do
  path "/users" do
    post "User registration" do
      tags "Users", "Authentication"
      consumes "application/json", "application/x-www-form-urlencoded"
      produces "text/html", "application/json"
      description "Creates a new user account. Automatically logs in the user and creates a session on success."

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          email: {
            type: :string,
            format: :email,
            example: "john.doe@example.com",
            description: "User email address (must be unique)"
          },
          password: {
            type: :string,
            format: :password,
            example: "SecurePass123!",
            description: "User password (minimum 8 characters)"
          },
          password_confirmation: {
            type: :string,
            format: :password,
            example: "SecurePass123!",
            description: "Password confirmation (must match password)"
          },
          first_name: {
            type: :string,
            example: "John",
            description: "User first name"
          },
          last_name: {
            type: :string,
            example: "Doe",
            description: "User last name"
          }
        },
        required: [ "email", "password", "password_confirmation", "first_name", "last_name" ]
      }

      response "302", "user created successfully - redirects to dashboard" do
        let(:user) do
          {
            user: {
              email: "newuser@example.com",
              password: "SecurePass123!",
              password_confirmation: "SecurePass123!",
              first_name: "New",
              last_name: "User"
            }
          }
        end

        run_test! do |response|
          expect(response).to redirect_to(dashboard_path)
          expect(User.find_by(email: "newuser@example.com")).to be_present
          expect(session[:user_id]).to be_present
        end
      end

      response "422", "validation failed - email already taken" do
        let(:existing_user) do
          User.create!(
            email: "existing@example.com",
            password: "Password123!",
            password_confirmation: "Password123!",
            first_name: "Existing",
            last_name: "User"
          )
        end

        let(:user) do
          {
            user: {
              email: existing_user.email,
              password: "NewPassword123!",
              password_confirmation: "NewPassword123!",
              first_name: "Another",
              last_name: "User"
            }
          }
        end

        before { existing_user } # Ensure existing user is created

        run_test! do |response|
          expect(response.body).to include("Email has already been taken")
        end
      end

      response "422", "validation failed - password too short" do
        let(:user) do
          {
            user: {
              email: "shortpass@example.com",
              password: "short",
              password_confirmation: "short",
              first_name: "Short",
              last_name: "Pass"
            }
          }
        end

        run_test! do |response|
          expect(response.body).to include("Password is too short")
        end
      end

      response "422", "validation failed - password confirmation doesn't match" do
        let(:user) do
          {
            user: {
              email: "mismatch@example.com",
              password: "SecurePass123!",
              password_confirmation: "DifferentPass123!",
              first_name: "Mismatch",
              last_name: "User"
            }
          }
        end

        run_test! do |response|
          expect(response.body).to include("Password confirmation doesn&#39;t match Password")
        end
      end

      response "422", "validation failed - missing required fields" do
        let(:user) do
          {
            user: {
              email: "incomplete@example.com"
              # Missing password, first_name, last_name
            }
          }
        end

        run_test! do |response|
          expect(response.body).to include("can&#39;t be blank")
        end
      end

      response "422", "validation failed - invalid email format" do
        let(:user) do
          {
            user: {
              email: "invalid-email-format",
              password: "SecurePass123!",
              password_confirmation: "SecurePass123!",
              first_name: "Invalid",
              last_name: "Email"
            }
          }
        end

        run_test! do |response|
          expect(response.body).to include("Email is invalid")
        end
      end
    end
  end
end
