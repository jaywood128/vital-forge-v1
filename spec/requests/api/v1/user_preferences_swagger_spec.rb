# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "API V1 User Preferences", type: :request do
  let(:user) do
    User.create!(
      email: "prefs.swagger@example.com",
      password: "Password123!",
      first_name: "Prefs",
      last_name: "User"
    )
  end

  let(:jwt_auth) do
    post api_v1_mobile_login_path,
      params: { user: { email: user.email, password: "Password123!" } },
      as: :json
    token = JSON.parse(response.body).dig("data", "token")
    "Bearer #{token}"
  end

  path "/api/v1/user_preference" do
    get "Get user preference" do
      operationId "getUserPreference"
      tags "User Preferences"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      description "Returns the current user's preferences (onboarding, goals, training days, etc.). Use the 'Authorize' button at the top right to set your JWT token."

      response "200", "preference found" do
        schema type: :object,
          properties: {
            data: { "$ref" => "#/components/schemas/UserPreference" }
          }

        before { user.create_user_preference!(primary_goal: "physique", training_days_per_week: 4) }
        let(:Authorization) { jwt_auth }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["primary_goal"]).to eq("physique")
        end
      end

      response "404", "preference not found" do
        schema type: :object, properties: { error: { type: :string } }
        let(:Authorization) { jwt_auth }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end

    post "Create user preference" do
      operationId "createUserPreference"
      tags "User Preferences"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      description "Creates or initializes user preferences. If primary_goal and training_days_per_week are set, onboarding is marked complete. Use the 'Authorize' button at the top right to set your JWT token."

      parameter name: :user_preference, in: :body, schema: {
        type: :object,
        properties: {
          user_preference: {
            type: :object,
            properties: {
              primary_goal: { type: :string, enum: %w[physique strength] },
              training_days_per_week: { type: :integer },
              preferred_workout_duration: { type: :integer },
              experience_level: { type: :string, enum: %w[Beginner Intermediate Advanced] }
            }
          }
        },
        required: [ "user_preference" ]
      }

      response "201", "preference created" do
        schema type: :object,
          properties: {
            data: { "$ref" => "#/components/schemas/UserPreference" }
          }

        let(:Authorization) { jwt_auth }
        let(:user_preference) do
          {
            user_preference: {
              primary_goal: "strength",
              training_days_per_week: 4,
              preferred_workout_duration: 45,
              experience_level: "Intermediate"
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["primary_goal"]).to eq("strength")
          expect(data["data"]["training_days_per_week"]).to eq(4)
        end
      end

      response "422", "validation error" do
        schema type: :object, properties: { errors: { type: :object } }
        let(:Authorization) { jwt_auth }
        let(:user_preference) do
          {
            user_preference: {
              primary_goal: "invalid_goal",
              training_days_per_week: 10
            }
          }
        end
        run_test!
      end
    end

    patch "Update user preference" do
      operationId "updateUserPreference"
      tags "User Preferences"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      description "Updates the current user's preferences. Use the 'Authorize' button at the top right to set your JWT token."

      parameter name: :user_preference, in: :body, schema: {
        type: :object,
        properties: {
          user_preference: {
            type: :object,
            properties: {
              primary_goal: { type: :string, enum: %w[physique strength] },
              training_days_per_week: { type: :integer },
              preferred_workout_duration: { type: :integer },
              experience_level: { type: :string, enum: %w[Beginner Intermediate Advanced] }
            }
          }
        },
        required: [ "user_preference" ]
      }

      response "200", "preference updated" do
        schema type: :object,
          properties: {
            data: { "$ref" => "#/components/schemas/UserPreference" }
          }

        before { user.create_user_preference!(primary_goal: "physique", training_days_per_week: 3) }
        let(:Authorization) { jwt_auth }
        let(:user_preference) do
          {
            user_preference: {
              primary_goal: "strength",
              training_days_per_week: 5
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["primary_goal"]).to eq("strength")
          expect(data["data"]["training_days_per_week"]).to eq(5)
        end
      end

      response "422", "validation error" do
        schema type: :object, properties: { errors: { type: :object } }
        before { user.create_user_preference!(primary_goal: "physique", training_days_per_week: 3) }
        let(:Authorization) { jwt_auth }
        let(:user_preference) do
          {
            user_preference: {
              training_days_per_week: 99
            }
          }
        end
        run_test!
      end
    end
  end
end
