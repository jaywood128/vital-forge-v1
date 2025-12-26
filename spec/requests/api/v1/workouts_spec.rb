# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Workouts', type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'Password123!', first_name: 'Test', last_name: 'User') }
  let(:other_user) { User.create!(email: 'other@example.com', password: 'Password123!', first_name: 'Other', last_name: 'User') }
  let(:jwt_token) { AuthToken.for_user(user) }

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

  describe 'POST /api/v1/workout_templates/:id/start' do
    let!(:exercise) do
      Exercise.create!(
        name: 'Push Up',
        exercise_type: 'Strength',
        muscle_group: 'Chest',
        equipment: 'Bodyweight'
      )
    end

    let!(:template) do
      WorkoutTemplate.create!(
        name: 'Template A',
        goal_type: 'physique',
        difficulty_level: 'Beginner',
        days_per_week: 3,
        estimated_duration_minutes: 30,
        total_exercises: 1,
        source: 'Test',
        is_active: true
      ).tap do |t|
        t.workout_template_exercises.create!(
          exercise: exercise,
          order_position: 1,
          recommended_sets: 3,
          recommended_reps: '8-12',
          rest_seconds: 60
        )
      end
    end

    it 'creates a workout from template (JWT)' do
      post "/api/v1/workout_templates/#{template.id}/start",
           headers: { 'Authorization' => "Bearer #{jwt_token}" },
           as: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json.dig('workout', 'workout_template_id')).to eq(template.id)
      expect(json.dig('workout', 'completed')).to be(false)
    end

    it 'returns 409 when an active workout already exists' do
      existing = user.workouts.create!(
        name: template.name,
        workout_date: Date.current,
        workout_template_id: template.id,
        completed: false
      )

      post "/api/v1/workout_templates/#{template.id}/start",
           headers: { 'Authorization' => "Bearer #{jwt_token}" },
           as: :json

      expect(response).to have_http_status(:conflict)
      json = JSON.parse(response.body)
      expect(json['active_workout_id']).to eq(existing.id)
    end

    it 'returns 404 for missing template' do
      post "/api/v1/workout_templates/999999/start",
           headers: { 'Authorization' => "Bearer #{jwt_token}" },
           as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 when unauthenticated' do
      post "/api/v1/workout_templates/#{template.id}/start", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'builds exercises and sets from template' do
      post "/api/v1/workout_templates/#{template.id}/start",
           headers: { 'Authorization' => "Bearer #{jwt_token}" },
           as: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      workout_id = json.dig('workout', 'id')
      workout = Workout.find(workout_id)
      expect(workout.workout_exercises.size).to eq(1)
      expect(workout.workout_exercises.first.exercise_sets.size).to eq(3)
    end
  end

  describe 'PATCH /api/v1/workouts/:id/start' do
    let(:workout) do
      user.workouts.create!(
        name: 'To Start',
        workout_date: Date.current,
        completed: false,
        workout_type: 'Strength'
      )
    end

    it 'returns 422 when workout was already started (JWT)' do
      workout.update!(started_at: 5.minutes.ago)

      patch "/api/v1/workouts/#{workout.id}/start",
            headers: { 'Authorization' => "Bearer #{jwt_token}" },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Workout already started')
    end

    it 'returns 422 when workout is already completed (JWT)' do
      workout.update!(completed: true, completed_at: 1.minute.ago, started_at: 10.minutes.ago)

      patch "/api/v1/workouts/#{workout.id}/start",
            headers: { 'Authorization' => "Bearer #{jwt_token}" },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Workout already completed')
    end

    it 'sets started_at for the user workout (JWT)' do
      patch "/api/v1/workouts/#{workout.id}/start",
            headers: { 'Authorization' => "Bearer #{jwt_token}" },
            as: :json

      expect(response).to have_http_status(:ok)
      workout.reload
      expect(workout.started_at).not_to be_nil
    end

    it 'returns 401 when unauthenticated' do
      patch "/api/v1/workouts/#{workout.id}/start", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 404 when workout belongs to another user' do
      patch "/api/v1/workouts/#{other_workout.id}/start",
            headers: { 'Authorization' => "Bearer #{jwt_token}" },
            as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /api/v1/workouts/:id/complete' do
    let(:workout) do
      user.workouts.create!(
        name: 'To Complete',
        workout_date: Date.current,
        completed: false,
        workout_type: 'Strength',
        started_at: Time.current
      )
    end

    it 'returns 422 when workout has not been started (JWT)' do
      workout.update!(started_at: nil)

      patch "/api/v1/workouts/#{workout.id}/complete",
            headers: { 'Authorization' => "Bearer #{jwt_token}" },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Workout has not been started')
    end

    it 'returns 422 when workout is already completed (JWT)' do
      workout.update!(completed: true, completed_at: 1.minute.ago)

      patch "/api/v1/workouts/#{workout.id}/complete",
            headers: { 'Authorization' => "Bearer #{jwt_token}" },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Workout already completed')
    end

    it 'marks workout complete for the user (JWT)' do
      patch "/api/v1/workouts/#{workout.id}/complete",
            headers: { 'Authorization' => "Bearer #{jwt_token}" },
            as: :json

      expect(response).to have_http_status(:ok)
      workout.reload
      expect(workout.completed).to be(true)
      expect(workout.completed_at).not_to be_nil
      expect(workout.duration_minutes).to be >= 1
    end

    it 'returns 401 when unauthenticated' do
      patch "/api/v1/workouts/#{workout.id}/complete", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 404 when workout belongs to another user' do
      patch "/api/v1/workouts/#{other_workout.id}/complete",
            headers: { 'Authorization' => "Bearer #{jwt_token}" },
            as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/workouts with date filters' do
    let!(:older_workout) do
      user.workouts.create!(
        name: 'Old',
        workout_date: Date.current - 10,
        workout_type: 'Cardio',
        completed: true
      )
    end

    let(:jwt_token) { AuthToken.for_user(user) }

    it 'returns workouts within start_date and end_date' do
      start_date = (Date.current - 2).to_s
      end_date = Date.current.to_s

      get api_v1_workouts_path,
          params: { start_date: start_date, end_date: end_date },
          headers: { 'Authorization' => "Bearer #{jwt_token}" },
          as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      names = json['data'].map { |w| w['name'] }
      expect(names).to include('Morning Run', 'Evening Weights')
      expect(names).not_to include('Old')
    end
  end
  describe 'Security Tests' do
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
