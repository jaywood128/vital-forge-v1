# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Authentication", type: :request do
  def csrf_token
    # Seed CSRF-TOKEN cookie for non-GET requests (logout, etc.)
    get api_v1_csrf_path, as: :json
    cookies["CSRF-TOKEN"]
  end

  let!(:user) do
    u = User.new(
      email: "test@example.com",
      first_name: "Test",
      last_name: "User"
    )
    u.password = "Password123!"
    u.save!
    u
  end

  describe "POST /api/v1/login" do
    it "signs in with valid credentials and returns user JSON" do
      # Login does not require CSRF in our API (SessionsController skips verify_authenticity_token on create),
      # but we keep the flow simple by just posting credentials.
      post api_v1_login_path,
        params: { user: { email: user.email, password: "Password123!" } },
        as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.dig("data", "user", "email")).to eq(user.email)

      # rack-test automatically persists the session cookie; do NOT pass Set-Cookie back as Cookie.
      get api_v1_current_user_path, as: :json

      expect(response).to have_http_status(:ok)
      current = JSON.parse(response.body)
      expect(current.dig("data", "user", "email")).to eq(user.email)
    end
  end

  describe "DELETE /api/v1/logout" do
    # NOTE: This test has a known issue with rack-test not properly clearing session cookies
    # In production, the logout works correctly. This is a test framework limitation.
    it "signs out when signed in" do
      token = csrf_token

      # Sign in
      post api_v1_login_path,
        params: { user: { email: user.email, password: "Password123!" } },
        headers: { "X-CSRF-Token" => token },
        as: :json
      expect(response).to have_http_status(:ok)

      # Get fresh token from cookies (login response sets a new one)
      token = cookies["CSRF-TOKEN"]

      # Now sign out
      delete api_v1_logout_path,
        headers: { "X-CSRF-Token" => token },
        as: :json
      expect(response).to have_http_status(:no_content)

      # Current user should now be unauthorized
      get api_v1_current_user_path, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/current_user" do
    it "returns 401 when not signed in" do
      get api_v1_current_user_path, as: :json
      # First call sets cookie and returns 401 since no session
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
