# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Workouts', type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'Password123!', first_name: 'Test', last_name: 'User') }
  let(:other_user) { User.create!(email: 'other@example.com', password: 'Password123!', first_name: 'Other', last_name: 'User') }
  
  let!(:workout1) do
    user.workouts.create!(
      name: 'Morning Run',
      description: 'Easy 5k run',
      workout_date: Date.today,
      duration_minutes: 30,
      workout_type: 'Cardio',
      calories_burned: 300,
      intensity_level: 5,
      completed: true
    )
  end
  
  let!(:workout2) do
    user.workouts.create!(
      name: 'Evening Weights',
      description: 'Upper body strength',
      workout_date: Date.yesterday,
      duration_minutes: 45,
      workout_type: 'Strength',
      calories_burned: 200,
      intensity_level: 8,
      completed: true
    )
  end
  
  let!(:other_workout) do
    other_user.workouts.create!(
      name: 'Other User Workout',
      description: 'Should not be visible',
      workout_date: Date.today,
      duration_minutes: 20,
      workout_type: 'Cardio',
      intensity_level: 6,
      completed: true
    )
  end

  describe 'GET /api/v1/workouts' do
    context 'with session authentication (web client)' do
      before do
        # Get CSRF token first
        get api_v1_csrf_path, as: :json
        @csrf_token = cookies['CSRF-TOKEN']
        
        # Login with CSRF token
        post api_v1_login_path, 
          params: { user: { email: user.email, password: 'Password123!' } },
          headers: { 'X-CSRF-Token' => @csrf_token },
          as: :json
        
        # Get fresh CSRF token after login
        @csrf_token = response.headers['X-CSRF-Token'] || @csrf_token
      end

      it 'returns all workouts for the authenticated user' do
        get api_v1_workouts_path, headers: { 'X-CSRF-Token' => @csrf_token }, as: :json
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json['data']).to be_an(Array)
        expect(json['data'].length).to eq(2)
        expect(json['data'].map { |w| w['name'] }).to contain_exactly('Morning Run', 'Evening Weights')
      end

      it 'orders workouts by workout_date descending' do
        get api_v1_workouts_path, headers: { 'X-CSRF-Token' => @csrf_token }, as: :json
        
        json = JSON.parse(response.body)
        expect(json['data'].first['name']).to eq('Morning Run')
        expect(json['data'].last['name']).to eq('Evening Weights')
      end

      it 'does not return other users workouts' do
        get api_v1_workouts_path, headers: { 'X-CSRF-Token' => @csrf_token }, as: :json
        
        json = JSON.parse(response.body)
        workout_names = json['data'].map { |w| w['name'] }
        expect(workout_names).not_to include('Other User Workout')
      end

      it 'returns only specified fields' do
        get api_v1_workouts_path, headers: { 'X-CSRF-Token' => @csrf_token }, as: :json
        
        json = JSON.parse(response.body)
        workout = json['data'].first
        
        # Verify essential fields are present
        expect(workout).to include(
          'id', 'name', 'description', 'workout_date', 'duration_minutes',
          'workout_type', 'calories_burned', 'intensity_level', 'completed'
        )
      end
    end

    context 'with JWT authentication (mobile client)' do
      let(:jwt_token) { AuthToken.for_user(user) }

      it 'returns workouts with valid JWT token' do
        get api_v1_workouts_path, headers: { 'Authorization' => "Bearer #{jwt_token}" }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json['data']).to be_an(Array)
        expect(json['data'].length).to eq(2)
      end

      it 'does not require CSRF token with JWT auth' do
        get api_v1_workouts_path, headers: { 'Authorization' => "Bearer #{jwt_token}" }
        
        expect(response).to have_http_status(:ok)
      end

      it 'returns 401 with invalid JWT token' do
        get api_v1_workouts_path, headers: { 'Authorization' => 'Bearer invalid_token' }
        
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Authentication required')
      end

      it 'returns 401 with expired JWT token' do
        expired_token = AuthToken.for_user(user, expires_in: -1.hour)
        get api_v1_workouts_path, headers: { 'Authorization' => "Bearer #{expired_token}" }
        
        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not return other users workouts with JWT' do
        get api_v1_workouts_path, headers: { 'Authorization' => "Bearer #{jwt_token}" }
        
        json = JSON.parse(response.body)
        workout_names = json['data'].map { |w| w['name'] }
        expect(workout_names).not_to include('Other User Workout')
      end
    end

    context 'without authentication' do
      it 'returns 401 when not authenticated' do
        get api_v1_workouts_path
        
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Authentication required')
      end
    end
  end

  describe 'GET /api/v1/workouts/:id' do
    context 'with session authentication' do
      before do
        # Get CSRF token first
        get api_v1_csrf_path, as: :json
        @csrf_token = cookies['CSRF-TOKEN']
        
        # Login with CSRF token
        post api_v1_login_path, 
          params: { user: { email: user.email, password: 'Password123!' } },
          headers: { 'X-CSRF-Token' => @csrf_token },
          as: :json
        
        # Get fresh CSRF token after login
        @csrf_token = response.headers['X-CSRF-Token'] || @csrf_token
      end

      it 'returns the specified workout' do
        get api_v1_workout_path(workout1), headers: { 'X-CSRF-Token' => @csrf_token }, as: :json
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json['data']['id']).to eq(workout1.id)
        expect(json['data']['name']).to eq('Morning Run')
      end

      it 'returns 404 for non-existent workout' do
        get api_v1_workout_path(99999), headers: { 'X-CSRF-Token' => @csrf_token }, as: :json
        
        expect(response).to have_http_status(:not_found)
        expect(response.content_type).to include('application/json')
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Workout not found')
      end

      it 'returns 404 when trying to access another users workout' do
        get api_v1_workout_path(other_workout), headers: { 'X-CSRF-Token' => @csrf_token }, as: :json
        
        expect(response).to have_http_status(:not_found)
        expect(response.content_type).to include('application/json')
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Workout not found')
      end
    end

    context 'with JWT authentication' do
      let(:jwt_token) { AuthToken.for_user(user) }

      it 'returns the specified workout with JWT' do
        get api_v1_workout_path(workout1), headers: { 'Authorization' => "Bearer #{jwt_token}" }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json['data']['id']).to eq(workout1.id)
        expect(json['data']['name']).to eq('Morning Run')
      end

      it 'returns 404 for non-existent workout with JWT' do
        get api_v1_workout_path(99999), headers: { 'Authorization' => "Bearer #{jwt_token}" }
        
        expect(response).to have_http_status(:not_found)
      end

      it 'prevents access to other users workouts with JWT' do
        get api_v1_workout_path(other_workout), headers: { 'Authorization' => "Bearer #{jwt_token}" }
        
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without authentication' do
      it 'returns 401 when not authenticated' do
        get api_v1_workout_path(workout1)
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'Security Tests' do
    let(:jwt_token) { AuthToken.for_user(user) }

    it 'prevents session hijacking by isolating user data' do
      # Get CSRF token and login
      get api_v1_csrf_path, as: :json
      csrf_token = cookies['CSRF-TOKEN']
      
      post api_v1_login_path, 
        params: { user: { email: user.email, password: 'Password123!' } },
        headers: { 'X-CSRF-Token' => csrf_token },
        as: :json
      
      csrf_token = response.headers['X-CSRF-Token'] || csrf_token
      
      # Try to access other user's workout
      get api_v1_workout_path(other_workout), headers: { 'X-CSRF-Token' => csrf_token }, as: :json
      
      expect(response).to have_http_status(:not_found)
    end

    it 'prevents JWT token reuse across users' do
      # Get token for user
      user_token = AuthToken.for_user(user)
      
      # Try to access other user's workout with user's token
      get api_v1_workout_path(other_workout), headers: { 'Authorization' => "Bearer #{user_token}" }
      
      expect(response).to have_http_status(:not_found)
    end

    it 'rejects malformed authorization headers' do
      get api_v1_workouts_path, headers: { 'Authorization' => 'InvalidFormat' }
      
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects empty bearer tokens' do
      get api_v1_workouts_path, headers: { 'Authorization' => 'Bearer ' }
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

