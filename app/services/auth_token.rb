# frozen_string_literal: true

# Service class for generating and decoding JWT tokens
# Used by mobile authentication
#
# Usage:
#   # Generate token
#   token = AuthToken.for_user(user)
#
#   # Decode token
#   payload = AuthToken.decode(token)
#
#   # Verify token and get user
#   user = AuthToken.verify(token)
#
class AuthToken
  # Token expiration time (24 hours)
  TOKEN_LIFETIME = 24.hours

  class << self
    # Generate a JWT token for a user
    #
    # @param user [User] The user to generate a token for
    # @param expires_in [ActiveSupport::Duration] Token lifetime (default: 24 hours)
    # @return [String] JWT token
    #
    # @example
    #   token = AuthToken.for_user(user)
    #   # => "eyJhbGciOiJIUzI1NiJ9..."
    #
    def for_user(user, expires_in: TOKEN_LIFETIME)
      payload = {
        sub: user.id,
        email: user.email,
        exp: expires_in.from_now.to_i,
        iat: Time.now.to_i
      }

      JWT.encode(payload, secret_key, "HS256")
    end

    # Decode a JWT token without verification
    #
    # @param token [String] The JWT token to decode
    # @return [Hash, nil] Decoded payload or nil if invalid
    #
    # @example
    #   payload = AuthToken.decode(token)
    #   # => {"sub"=>1, "email"=>"user@example.com", "exp"=>1700000000, "iat"=>1699913600}
    #
    def decode(token)
      decoded = JWT.decode(token, secret_key, true, algorithm: "HS256")
      decoded[0]
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    # Verify a token and return the associated user
    #
    # @param token [String] The JWT token to verify
    # @return [User, nil] The user if token is valid, nil otherwise
    #
    # @example
    #   user = AuthToken.verify(token)
    #   # => #<User id: 1, email: "user@example.com">
    #
    def verify(token)
      payload = decode(token)
      return nil unless payload

      User.find_by(id: payload["sub"])
    rescue ActiveRecord::RecordNotFound
      nil
    end

    # Check if a token is valid
    #
    # @param token [String] The JWT token to check
    # @return [Boolean] true if valid, false otherwise
    #
    # @example
    #   AuthToken.valid?(token)
    #   # => true
    #
    def valid?(token)
      decode(token).present?
    end

    # Extract user ID from token without full verification
    #
    # @param token [String] The JWT token
    # @return [Integer, nil] User ID or nil
    #
    # @example
    #   user_id = AuthToken.user_id_from(token)
    #   # => 1
    #
    def user_id_from(token)
      payload = decode(token)
      payload&.dig("sub")
    end

    # Get token expiration time
    #
    # @param token [String] The JWT token
    # @return [Time, nil] Expiration time or nil
    #
    # @example
    #   AuthToken.expires_at(token)
    #   # => 2024-11-24 12:00:00 UTC
    #
    def expires_at(token)
      payload = decode(token)
      return nil unless payload && payload["exp"]

      Time.at(payload["exp"])
    end

    # Check if token is expired
    #
    # @param token [String] The JWT token
    # @return [Boolean] true if expired, false otherwise
    #
    # @example
    #   AuthToken.expired?(token)
    #   # => false
    #
    def expired?(token)
      expiration = expires_at(token)
      return true unless expiration

      expiration < Time.now
    end

    private

    def secret_key
      Rails.application.secret_key_base
    end
  end
end
