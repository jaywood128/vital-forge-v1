# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "API V1 Weekly Feedbacks", type: :request do
  before do
    # Enable AI features for testing
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("ENABLE_AI_FEATURES", "false").and_return("true")
  end

  let(:user) do
    User.create!(
      email: "feedback.swagger@example.com",
      password: "Password123!",
      first_name: "Feedback",
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

  path "/api/v1/weekly_feedbacks/current" do
    get "Get current weekly feedback" do
      operationId "getCurrentWeeklyFeedback"
      tags "Weekly Feedback"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      description "Returns AI-generated weekly feedback for the current week. If not yet generated, returns 202 and queues generation. Use the 'Authorize' button at the top right to set your JWT token."

      response "200", "feedback found" do
        schema type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                feedback: { type: :string, description: "AI-generated feedback text" },
                week_start: { type: :string, format: :date },
                generated_at: { type: :string, format: :"date-time" },
                stats: { type: :object, nullable: true, description: "Stats snapshot for the week" }
              }
            }
          }

        before do
          user.weekly_feedbacks.create!(
            week_start: Date.current.beginning_of_week,
            feedback_text: "Great progress this week! You hit your strength targets.",
            generated_at: Time.current,
            stats_snapshot: { "workouts" => 4, "total_volume" => 12_000 }
          )
        end
        let(:Authorization) { jwt_auth }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["feedback"]).to be_present
          expect(data["data"]["week_start"]).to be_present
        end
      end

      response "202", "feedback not yet generated (queued)" do
        schema type: :object,
          properties: {
            status: { type: :string, example: "generating" },
            message: { type: :string }
          }

        let(:Authorization) { jwt_auth }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("generating")
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
