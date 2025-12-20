# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Mobile Users", type: :request do
  describe "POST /api/v1/mobile/signup" do
    it "creates a mobile user and returns JWT" do
      post "/api/v1/mobile/signup",
           params: {
             user: {
               email: "mobile@example.com",
               password: "Password123!",
               password_confirmation: "Password123!",
               first_name: "Mobile",
               last_name: "User"
             }
           },
           as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body.dig("data", "token")).to be_present
      expect(body.dig("data", "expires_at")).to be_present
      expect(body.dig("data", "user", "email")).to eq("mobile@example.com")
    end

    it "returns 422 on invalid payload" do
      post "/api/v1/mobile/signup",
           params: {
             user: {
               email: "",
               password: "",
               password_confirmation: "",
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

