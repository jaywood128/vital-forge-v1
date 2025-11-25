# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthToken do
  let(:user) do
    User.create!(
      email: "token@example.com",
      password: "Password123!",
      first_name: "Token",
      last_name: "User"
    )
  end

  describe ".for_user" do
    it "generates a valid JWT token" do
      token = AuthToken.for_user(user)
      
      expect(token).to be_present
      expect(token).to be_a(String)
      expect(token.split(".").length).to eq(3) # JWT has 3 parts
    end

    it "includes user information in payload" do
      token = AuthToken.for_user(user)
      payload = AuthToken.decode(token)
      
      expect(payload["sub"]).to eq(user.id)
      expect(payload["email"]).to eq(user.email)
      expect(payload["exp"]).to be_present
      expect(payload["iat"]).to be_present
    end

    it "accepts custom expiration time" do
      token = AuthToken.for_user(user, expires_in: 1.hour)
      payload = AuthToken.decode(token)
      
      expected_exp = 1.hour.from_now.to_i
      expect(payload["exp"]).to be_within(5).of(expected_exp)
    end
  end

  describe ".decode" do
    it "decodes a valid token" do
      token = AuthToken.for_user(user)
      payload = AuthToken.decode(token)
      
      expect(payload).to be_a(Hash)
      expect(payload["sub"]).to eq(user.id)
    end

    it "returns nil for invalid token" do
      payload = AuthToken.decode("invalid.token.here")
      expect(payload).to be_nil
    end

    it "returns nil for expired token" do
      token = AuthToken.for_user(user, expires_in: -1.hour)
      payload = AuthToken.decode(token)
      
      expect(payload).to be_nil
    end
  end

  describe ".verify" do
    it "returns user for valid token" do
      token = AuthToken.for_user(user)
      verified_user = AuthToken.verify(token)
      
      expect(verified_user).to eq(user)
    end

    it "returns nil for invalid token" do
      verified_user = AuthToken.verify("invalid.token.here")
      expect(verified_user).to be_nil
    end

    it "returns nil for expired token" do
      token = AuthToken.for_user(user, expires_in: -1.hour)
      verified_user = AuthToken.verify(token)
      
      expect(verified_user).to be_nil
    end

    it "returns nil if user no longer exists" do
      token = AuthToken.for_user(user)
      user.destroy
      verified_user = AuthToken.verify(token)
      
      expect(verified_user).to be_nil
    end
  end

  describe ".valid?" do
    it "returns true for valid token" do
      token = AuthToken.for_user(user)
      expect(AuthToken.valid?(token)).to be true
    end

    it "returns false for invalid token" do
      expect(AuthToken.valid?("invalid.token")).to be false
    end

    it "returns false for expired token" do
      token = AuthToken.for_user(user, expires_in: -1.hour)
      expect(AuthToken.valid?(token)).to be false
    end
  end

  describe ".user_id_from" do
    it "extracts user ID from token" do
      token = AuthToken.for_user(user)
      user_id = AuthToken.user_id_from(token)
      
      expect(user_id).to eq(user.id)
    end

    it "returns nil for invalid token" do
      user_id = AuthToken.user_id_from("invalid.token")
      expect(user_id).to be_nil
    end
  end

  describe ".expires_at" do
    it "returns expiration time" do
      token = AuthToken.for_user(user)
      expires_at = AuthToken.expires_at(token)
      
      expect(expires_at).to be_a(Time)
      expect(expires_at).to be > Time.now
      expect(expires_at).to be < 25.hours.from_now
    end

    it "returns nil for invalid token" do
      expires_at = AuthToken.expires_at("invalid.token")
      expect(expires_at).to be_nil
    end
  end

  describe ".expired?" do
    it "returns false for valid token" do
      token = AuthToken.for_user(user)
      expect(AuthToken.expired?(token)).to be false
    end

    it "returns true for expired token" do
      token = AuthToken.for_user(user, expires_in: -1.hour)
      expect(AuthToken.expired?(token)).to be true
    end

    it "returns true for invalid token" do
      expect(AuthToken.expired?("invalid.token")).to be true
    end
  end
end

