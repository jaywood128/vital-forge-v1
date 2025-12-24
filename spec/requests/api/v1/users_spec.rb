# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Users", type: :request do
  describe "POST /api/v1/signup" do
    it "creates a user and logs in" do
      post "/api/v1/signup",
           params: {
             user: {
               email: "new@example.com",
               password: "Password123!",
               password_confirmation: "Password123!",
               first_name: "New",
               last_name: "User"
             }
           },
           as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body.dig("data", "user", "email")).to eq("new@example.com")
      # Ensure session is established by hitting current_user
      get "/api/v1/current_user", as: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns 422 on validation errors" do
      post "/api/v1/signup",
           params: {
             user: {
               email: "",
               password: "short",
               password_confirmation: "mismatch",
               first_name: "",
               last_name: ""
             }
           },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to be_present
    end
  end
end
