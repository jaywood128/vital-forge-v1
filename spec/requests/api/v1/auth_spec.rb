# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Authentication", type: :request do
  def csrf_token
    # Trigger after_action to set CSRF-TOKEN cookie
    get api_v1_current_user_path, as: :json
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

  describe "POST /api/v1/session" do
    it "signs in with valid credentials and returns user JSON" do
      token = csrf_token
      post api_v1_session_path,
        params: { user: { email: user.email, password: "Password123!" } },
        headers: { "X-CSRF-Token" => token },
        as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.dig("data", "user", "email")).to eq(user.email)

      # Verify session by calling current_user
      get api_v1_current_user_path, as: :json
      expect(response).to have_http_status(:ok)
      current = JSON.parse(response.body)
      expect(current.dig("data", "user", "email")).to eq(user.email)
    end
  end

  describe "DELETE /api/v1/session" do
    it "signs out when signed in" do
      # Sign in first
      token = csrf_token
      post api_v1_session_path,
        params: { user: { email: user.email, password: "Password123!" } },
        headers: { "X-CSRF-Token" => token },
        as: :json
      expect(response).to have_http_status(:ok)

      # Now sign out
      token = csrf_token
      delete api_v1_session_path,
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


