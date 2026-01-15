# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Sessions", type: :request do
  let!(:user) do
    User.create!(
      email: "login@example.com",
      password: "Password123!",
      first_name: "Login",
      last_name: "User"
    )
  end

  def csrf_token
    get "/api/v1/csrf", as: :json
    cookies["CSRF-TOKEN"]
  end

  describe "POST /api/v1/login" do
    it "logs in with valid credentials" do
      token = csrf_token
      post "/api/v1/login",
           params: { user: { email: user.email, password: "Password123!" } },
           headers: { "X-CSRF-Token" => token },
           as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.dig("data", "user", "email")).to eq(user.email)
    end

    it "returns 401 with invalid credentials" do
      token = csrf_token
      post "/api/v1/login",
           params: { user: { email: user.email, password: "wrong" } },
           headers: { "X-CSRF-Token" => token },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/logout" do
    it "logs out after login" do
      token = csrf_token
      post "/api/v1/login",
           params: { user: { email: user.email, password: "Password123!" } },
           headers: { "X-CSRF-Token" => token },
           as: :json
      expect(response).to have_http_status(:ok)

      token = cookies["CSRF-TOKEN"] || token
      delete "/api/v1/logout",
             headers: { "X-CSRF-Token" => token },
             as: :json

      expect(response).to have_http_status(:no_content)
    end
  end
end
