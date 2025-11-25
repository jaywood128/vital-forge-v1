# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthToken, type: :service do
  let(:user) { User.create!(email: 'test@example.com', password: 'Password123!', first_name: 'Test', last_name: 'User') }

  describe 'Edge Cases and Security' do
    describe '.for_user with invalid inputs' do
      it 'raises error when user is nil' do
        expect { AuthToken.for_user(nil) }.to raise_error
      end

      it 'raises error when user is blank' do
        expect { AuthToken.for_user('') }.to raise_error
      end

      it 'generates token with custom expiration' do
        token = AuthToken.for_user(user, expires_in: 1.hour)
        decoded = AuthToken.decode(token)
        
        expect(decoded['exp']).to be_within(5).of(1.hour.from_now.to_i)
      end

      it 'includes issued at time' do
        token = AuthToken.for_user(user)
        decoded = AuthToken.decode(token)
        
        expect(decoded['iat']).to be_within(5).of(Time.now.to_i)
      end
    end

    describe '.verify with edge cases' do
      it 'returns nil for nil token' do
        expect(AuthToken.verify(nil)).to be_nil
      end

      it 'returns nil for empty string token' do
        expect(AuthToken.verify('')).to be_nil
      end

      it 'returns nil for malformed token' do
        expect(AuthToken.verify('not.a.valid.jwt')).to be_nil
      end

      it 'returns nil for token with invalid signature' do
        payload = { sub: user.id, exp: 24.hours.from_now.to_i }
        token = JWT.encode(payload, 'wrong_secret', 'HS256')
        
        expect(AuthToken.verify(token)).to be_nil
      end

      it 'returns nil for expired token' do
        token = AuthToken.for_user(user, expires_in: -1.hour)
        expect(AuthToken.verify(token)).to be_nil
      end

      it 'returns nil for token with non-existent user' do
        token = AuthToken.for_user(user)
        user.destroy
        
        expect(AuthToken.verify(token)).to be_nil
      end

      it 'returns nil for token without sub claim' do
        payload = { email: user.email, exp: 24.hours.from_now.to_i }
        token = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
        
        expect(AuthToken.verify(token)).to be_nil
      end
    end

    describe '.decode with edge cases' do
      it 'returns nil for invalid token' do
        expect(AuthToken.decode('invalid')).to be_nil
      end

      it 'returns nil for nil token' do
        expect(AuthToken.decode(nil)).to be_nil
      end

      it 'returns nil for empty token' do
        expect(AuthToken.decode('')).to be_nil
      end

      it 'returns Hash for valid token' do
        token = AuthToken.for_user(user)
        decoded = AuthToken.decode(token)
        
        expect(decoded).to be_a(Hash)
        expect(decoded['sub']).to eq(user.id)
      end
    end

    describe '.valid? with edge cases' do
      it 'returns false for nil token' do
        expect(AuthToken.valid?(nil)).to be false
      end

      it 'returns false for empty token' do
        expect(AuthToken.valid?('')).to be false
      end

      it 'returns false for malformed token' do
        expect(AuthToken.valid?('not.a.jwt')).to be false
      end

      it 'returns false for expired token' do
        token = AuthToken.for_user(user, expires_in: -1.hour)
        expect(AuthToken.valid?(token)).to be false
      end

      it 'returns true for token with deleted user (token is still structurally valid)' do
        token = AuthToken.for_user(user)
        user.destroy
        # Token is still valid JWT, but verify() will return nil
        expect(AuthToken.valid?(token)).to be true
      end

      it 'returns true for valid token' do
        token = AuthToken.for_user(user)
        expect(AuthToken.valid?(token)).to be true
      end
    end

    describe '.expired? with edge cases' do
      it 'returns true for nil token' do
        expect(AuthToken.expired?(nil)).to be true
      end

      it 'returns true for empty token' do
        expect(AuthToken.expired?('')).to be true
      end

      it 'returns true for malformed token' do
        expect(AuthToken.expired?('invalid')).to be true
      end

      it 'returns true for expired token' do
        token = AuthToken.for_user(user, expires_in: -1.hour)
        expect(AuthToken.expired?(token)).to be true
      end

      it 'returns false for valid token' do
        token = AuthToken.for_user(user)
        expect(AuthToken.expired?(token)).to be false
      end

      it 'returns true for token without exp claim' do
        payload = { sub: user.id }
        token = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
        expect(AuthToken.expired?(token)).to be true
      end
    end

    describe '.expires_at with edge cases' do
      it 'returns nil for invalid token' do
        expect(AuthToken.expires_at('invalid')).to be_nil
      end

      it 'returns nil for nil token' do
        expect(AuthToken.expires_at(nil)).to be_nil
      end

      it 'returns Time object for valid token' do
        token = AuthToken.for_user(user, expires_in: 2.hours)
        
        expect(AuthToken.expires_at(token)).to be_a(Time)
        expect(AuthToken.expires_at(token)).to be_within(5).of(2.hours.from_now)
      end
    end

    describe '.user_id_from with edge cases' do
      it 'returns nil for invalid token' do
        expect(AuthToken.user_id_from('invalid')).to be_nil
      end

      it 'returns nil for nil token' do
        expect(AuthToken.user_id_from(nil)).to be_nil
      end

      it 'returns user id for valid token' do
        token = AuthToken.for_user(user)
        expect(AuthToken.user_id_from(token)).to eq(user.id)
      end

      it 'returns nil for token without sub claim' do
        payload = { email: user.email, exp: 24.hours.from_now.to_i }
        token = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
        
        expect(AuthToken.user_id_from(token)).to be_nil
      end
    end
  end

  describe 'Token Tampering Prevention' do
    it 'rejects token with modified payload' do
      token = AuthToken.for_user(user)
      parts = token.split('.')
      
      # Tamper with payload (change user id)
      tampered_payload = Base64.urlsafe_encode64({ sub: 999, exp: 24.hours.from_now.to_i }.to_json)
      tampered_token = "#{parts[0]}.#{tampered_payload}.#{parts[2]}"
      
      expect(AuthToken.verify(tampered_token)).to be_nil
    end

    it 'rejects token with modified signature' do
      token = AuthToken.for_user(user)
      parts = token.split('.')
      
      # Tamper with signature
      tampered_token = "#{parts[0]}.#{parts[1]}.tampered_signature"
      
      expect(AuthToken.verify(tampered_token)).to be_nil
    end

    it 'rejects token with different algorithm' do
      payload = { sub: user.id, exp: 24.hours.from_now.to_i }
      # Try to use 'none' algorithm (security vulnerability)
      token = JWT.encode(payload, nil, 'none')
      
      expect(AuthToken.verify(token)).to be_nil
    end
  end

  describe 'Concurrency and Race Conditions' do
    it 'handles rapid token verification' do
      token = AuthToken.for_user(user)
      
      results = 10.times.map { AuthToken.verify(token) }
      
      expect(results).to all(eq(user))
    end
  end

  describe 'Memory and Performance' do
    it 'does not leak sensitive data in token' do
      token = AuthToken.for_user(user)
      decoded = AuthToken.decode(token)
      
      # Should not contain password or sensitive fields
      expect(decoded.keys).not_to include('password')
      expect(decoded.keys).not_to include('password_digest')
      expect(decoded.keys).not_to include('encrypted_password')
    end

    it 'generates tokens in reasonable time' do
      start_time = Time.now
      100.times { AuthToken.for_user(user) }
      duration = Time.now - start_time
      
      expect(duration).to be < 2.0 # Should complete in under 2 seconds
    end

    it 'verifies tokens in reasonable time' do
      token = AuthToken.for_user(user)
      
      start_time = Time.now
      100.times { AuthToken.verify(token) }
      duration = Time.now - start_time
      
      expect(duration).to be < 2.0 # Should complete in under 2 seconds
    end
  end
end

