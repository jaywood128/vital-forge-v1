# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Mobile Authentication", type: :request do
  let!(:user) do
    u = User.new(
      email: "mobile@example.com",
      first_name: "Mobile",
      last_name: "User"
    )
    u.password = "Password123!"
    u.save!
    u
  end

  describe "POST /api/v1/mobile/login" do
    it "returns JWT token with valid credentials" do
      post api_v1_mobile_login_path,
        params: { user: { email: user.email, password: "Password123!" } },
        as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body.dig("data", "user", "email")).to eq(user.email)
      expect(body.dig("data", "token")).to be_present
      expect(body.dig("data", "expires_at")).to be_present

      # Verify token is valid JWT
      token = body.dig("data", "token")
      decoded = JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: "HS256")
      expect(decoded[0]["sub"]).to eq(user.id)
    end

    it "returns 401 with invalid credentials" do
      post api_v1_mobile_login_path,
        params: { user: { email: user.email, password: "WrongPassword" } },
        as: :json

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Invalid email or password")
    end

    it "returns 401 with non-existent user" do
      post api_v1_mobile_login_path,
        params: { user: { email: "nonexistent@example.com", password: "Password123!" } },
        as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/mobile/current_user" do
    it "returns current user with valid token" do
      # Login to get token
      post api_v1_mobile_login_path,
        params: { user: { email: user.email, password: "Password123!" } },
        as: :json

      token = JSON.parse(response.body).dig("data", "token")

      # Use token to get current user
      get api_v1_mobile_current_user_path,
        headers: { "Authorization" => "Bearer #{token}" },
        as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.dig("data", "user", "email")).to eq(user.email)
      expect(body.dig("data", "user", "id")).to eq(user.id)
    end

    it "returns 401 without token" do
      get api_v1_mobile_current_user_path, as: :json

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Missing authentication token")
    end

    it "returns 401 with invalid token" do
      get api_v1_mobile_current_user_path,
        headers: { "Authorization" => "Bearer invalid_token" },
        as: :json

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Invalid or expired token")
    end
  end

  describe "DELETE /api/v1/mobile/logout" do
    it "returns 204 with valid token" do
      # Login to get token
      post api_v1_mobile_login_path,
        params: { user: { email: user.email, password: "Password123!" } },
        as: :json

      token = JSON.parse(response.body).dig("data", "token")

      # Logout
      delete api_v1_mobile_logout_path,
        headers: { "Authorization" => "Bearer #{token}" },
        as: :json

      expect(response).to have_http_status(:no_content)
    end
  end
end
