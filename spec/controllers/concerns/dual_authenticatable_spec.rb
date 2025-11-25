# frozen_string_literal: true

require 'rails_helper'

# Test controller to include the concern
class TestDualAuthController < ApplicationController
  include DualAuthenticatable
  skip_before_action :require_authentication
  skip_before_action :verify_authenticity_token

  def index
    render json: { user_id: current_user.id, auth_method: auth_method }
  end
end

RSpec.describe DualAuthenticatable, type: :controller do
  controller(TestDualAuthController) do
    def index
      render json: { user_id: current_user.id, auth_method: auth_method }
    end
  end

  let(:user) { User.create!(email: 'test@example.com', password: 'Password123!', first_name: 'Test', last_name: 'User') }
  let(:jwt_token) { AuthToken.for_user(user) }

  describe '#authenticate_user_dual!' do
    context 'with JWT authentication' do
      it 'authenticates user with valid JWT token' do
        request.headers['Authorization'] = "Bearer #{jwt_token}"
        get :index
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['user_id']).to eq(user.id)
        expect(json['auth_method']).to eq('jwt')
      end

      it 'sets @auth_method to :jwt' do
        request.headers['Authorization'] = "Bearer #{jwt_token}"
        get :index
        
        json = JSON.parse(response.body)
        expect(json['auth_method']).to eq('jwt')
      end

      it 'returns 401 with invalid JWT token' do
        request.headers['Authorization'] = 'Bearer invalid_token_here'
        get :index
        
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Authentication required')
      end

      it 'returns 401 with expired JWT token' do
        expired_token = AuthToken.for_user(user, expires_in: -1.hour)
        request.headers['Authorization'] = "Bearer #{expired_token}"
        get :index
        
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns 401 with malformed authorization header' do
        request.headers['Authorization'] = 'InvalidFormat'
        get :index
        
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns 401 with empty bearer token' do
        request.headers['Authorization'] = 'Bearer '
        get :index
        
        expect(response).to have_http_status(:unauthorized)
      end

      it 'handles JWT decode errors gracefully' do
        request.headers['Authorization'] = 'Bearer not.a.valid.jwt'
        get :index
        
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with session authentication' do
      before do
        # Simulate session login
        session[:user_id] = user.id
      end

      it 'authenticates user with valid session' do
        get :index
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['user_id']).to eq(user.id)
        expect(json['auth_method']).to eq('session')
      end

      it 'sets @auth_method to :session' do
        get :index
        
        json = JSON.parse(response.body)
        expect(json['auth_method']).to eq('session')
      end

      it 'returns 401 with invalid session user_id' do
        session[:user_id] = 99999
        get :index
        
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns 401 with nil session user_id' do
        session[:user_id] = nil
        get :index
        
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'authentication priority' do
      it 'prefers JWT over session when both are present' do
        session[:user_id] = user.id
        request.headers['Authorization'] = "Bearer #{jwt_token}"
        get :index
        
        json = JSON.parse(response.body)
        expect(json['auth_method']).to eq('jwt')
      end

      it 'falls back to session when JWT is invalid' do
        session[:user_id] = user.id
        request.headers['Authorization'] = 'Bearer invalid_token'
        get :index
        
        json = JSON.parse(response.body)
        expect(json['auth_method']).to eq('session')
      end
    end

    context 'without any authentication' do
      it 'returns 401 when no auth provided' do
        get :index
        
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Authentication required')
      end
    end
  end

  describe '#current_user' do
    it 'returns the authenticated user via JWT' do
      request.headers['Authorization'] = "Bearer #{jwt_token}"
      get :index
      
      json = JSON.parse(response.body)
      expect(json['user_id']).to eq(user.id)
    end

    it 'returns the authenticated user via session' do
      session[:user_id] = user.id
      get :index
      
      json = JSON.parse(response.body)
      expect(json['user_id']).to eq(user.id)
    end

    it 'returns nil when not authenticated' do
      get :index
      
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe '#auth_method' do
    it 'returns :jwt for JWT authentication' do
      request.headers['Authorization'] = "Bearer #{jwt_token}"
      get :index
      
      json = JSON.parse(response.body)
      expect(json['auth_method']).to eq('jwt')
    end

    it 'returns :session for session authentication' do
      session[:user_id] = user.id
      get :index
      
      json = JSON.parse(response.body)
      expect(json['auth_method']).to eq('session')
    end
  end

  describe 'Security edge cases' do
    it 'prevents authentication with deleted user session' do
      session[:user_id] = user.id
      user.destroy
      get :index
      
      expect(response).to have_http_status(:unauthorized)
    end

    it 'prevents authentication with deleted user JWT' do
      token = jwt_token
      user.destroy
      request.headers['Authorization'] = "Bearer #{token}"
      get :index
      
      expect(response).to have_http_status(:unauthorized)
    end

    it 'handles JWT with missing sub claim' do
      payload = { email: user.email, exp: 24.hours.from_now.to_i }
      token = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
      request.headers['Authorization'] = "Bearer #{token}"
      get :index
      
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects JWT signed with wrong secret' do
      payload = { sub: user.id, exp: 24.hours.from_now.to_i }
      token = JWT.encode(payload, 'wrong_secret', 'HS256')
      request.headers['Authorization'] = "Bearer #{token}"
      get :index
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

