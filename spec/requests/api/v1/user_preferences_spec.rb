require 'rails_helper'

RSpec.describe 'API V1 User Preferences', type: :request do
  # Disable transactional fixtures for JWT authentication tests
  # JWT tokens contain user IDs that need to be visible across request contexts
  self.use_transactional_tests = false

  before(:each) do
    # Clean database before each test
    UserPreference.delete_all
    User.delete_all
    WorkoutTemplate.delete_all
  end

  after(:all) do
    # Clean up after all tests
    UserPreference.delete_all
    User.delete_all
    WorkoutTemplate.delete_all
  end

  let!(:workout_template) do
    WorkoutTemplate.create!(
      name: 'PPL Programme',
      goal_type: 'physique',
      days_per_week: 4
    )
  end

  let!(:user) do
    u = User.new(
      email: 'test@example.com',
      first_name: 'Test',
      last_name: 'User'
    )
    u.password = 'Password123!'
    u.save!
    u
  end

  describe 'GET /api/v1/user_preference' do
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

      context 'when user has preferences' do
        let!(:preference) do
          UserPreference.create!(
            user: user,
            primary_goal: 'physique',
            training_days_per_week: 5,
            experience_level: 'Intermediate',
            onboarding_completed: true,
            onboarding_completed_at: Time.current
          )
        end

        it 'returns user preferences' do
          get api_v1_user_preference_path,
              headers: { 'X-CSRF-Token' => @csrf_token },
              as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)

          expect(json['data']['id']).to eq(preference.id)
          expect(json['data']['user_id']).to eq(user.id)
          expect(json['data']['primary_goal']).to eq('physique')
          expect(json['data']['training_days_per_week']).to eq(5)
          expect(json['data']['experience_level']).to eq('Intermediate')
          expect(json['data']['onboarding_completed']).to be true
        end
      end

      context 'when user has no preferences' do
        it 'returns not found' do
          get api_v1_user_preference_path,
              headers: { 'X-CSRF-Token' => @csrf_token },
              as: :json

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('User preferences not found')
        end
      end
    end

    context 'with JWT authentication (mobile client)' do
      let(:jwt_token) { AuthToken.for_user(user) }

      context 'when user has preferences' do
        let!(:preference) do
          UserPreference.create!(
            user: user,
            primary_goal: 'physique',
            training_days_per_week: 5,
            experience_level: 'Intermediate',
            onboarding_completed: true,
            onboarding_completed_at: Time.current
          )
        end

        it 'returns user preferences with JWT auth' do
          get api_v1_user_preference_path,
              headers: { 'Authorization' => "Bearer #{jwt_token}" },
              as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)

          expect(json['data']['id']).to eq(preference.id)
          expect(json['data']['user_id']).to eq(user.id)
          expect(json['data']['primary_goal']).to eq('physique')
          expect(json['data']['training_days_per_week']).to eq(5)
          expect(json['data']['experience_level']).to eq('Intermediate')
          expect(json['data']['onboarding_completed']).to be true
        end
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get api_v1_user_preference_path, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/user_preference' do
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

      context 'with valid parameters' do
        let(:valid_params) do
          {
            user_preference: {
              primary_goal: 'strength',
              training_days_per_week: 4,
              experience_level: 'Beginner'
            }
          }
        end

        it 'creates user preferences' do
          expect do
            post api_v1_user_preference_path,
                 params: valid_params,
                 headers: { 'X-CSRF-Token' => @csrf_token },
                 as: :json
          end.to change(UserPreference, :count).by(1)

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)

          expect(json['data']['user_id']).to eq(user.id)
          expect(json['data']['primary_goal']).to eq('strength')
          expect(json['data']['training_days_per_week']).to eq(4)
          expect(json['data']['experience_level']).to eq('Beginner')
        end

        it 'auto-completes onboarding when goal and days are set' do
          post api_v1_user_preference_path,
               params: valid_params,
               headers: { 'X-CSRF-Token' => @csrf_token },
               as: :json

          json = JSON.parse(response.body)
          expect(json['data']['onboarding_completed']).to be true
          expect(json['data']['onboarding_completed_at']).to be_present
        end
      end

      context 'with partial parameters' do
        let(:partial_params) do
          {
            user_preference: {
              primary_goal: 'physique'
            }
          }
        end

        it 'creates preferences without auto-completing onboarding' do
          post api_v1_user_preference_path,
               params: partial_params,
               headers: { 'X-CSRF-Token' => @csrf_token },
               as: :json

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)

          expect(json['data']['primary_goal']).to eq('physique')
          expect(json['data']['onboarding_completed']).to be false
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) do
          {
            user_preference: {
              primary_goal: 'invalid_goal',
              training_days_per_week: 10
            }
          }
        end

        it 'returns validation errors' do
          post api_v1_user_preference_path,
               params: invalid_params,
               headers: { 'X-CSRF-Token' => @csrf_token },
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to be_present
        end
      end

      context 'when preference already exists (upsert)' do
        let!(:existing_preference) do
          UserPreference.create!(
            user: user,
            primary_goal: 'physique',
            training_days_per_week: 3,
            experience_level: 'Beginner'
          )
        end

        it 'updates existing preference and returns 200' do
          expect do
            post api_v1_user_preference_path,
                 params: { user_preference: { primary_goal: 'strength', training_days_per_week: 5, experience_level: 'Advanced' } },
                 headers: { 'X-CSRF-Token' => @csrf_token },
                 as: :json
          end.not_to change(UserPreference, :count)

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']['primary_goal']).to eq('strength')
          expect(json['data']['training_days_per_week']).to eq(5)
        end
      end
    end

    context 'with JWT authentication (mobile client)' do
      let(:jwt_token) { AuthToken.for_user(user) }

      it 'creates user preferences with JWT' do
        valid_params = {
          user_preference: {
            primary_goal: 'strength',
            training_days_per_week: 4,
            experience_level: 'Beginner'
          }
        }

        expect do
          post api_v1_user_preference_path,
               params: valid_params,
               headers: { 'Authorization' => "Bearer #{jwt_token}" },
               as: :json
        end.to change(UserPreference, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        post api_v1_user_preference_path,
             params: { user_preference: { primary_goal: 'physique' } },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/user_preference' do
    let!(:preference) do
      UserPreference.create!(
        user: user,
        primary_goal: 'physique',
        training_days_per_week: 3,
        experience_level: 'Beginner'
      )
    end

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

      context 'with valid parameters' do
        let(:update_params) do
          {
            user_preference: {
              training_days_per_week: 5,
              preferred_workout_duration: 60
            }
          }
        end

        it 'updates user preferences' do
          patch api_v1_user_preference_path,
                params: update_params,
                headers: { 'X-CSRF-Token' => @csrf_token },
                as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)

          expect(json['data']['training_days_per_week']).to eq(5)
          expect(json['data']['preferred_workout_duration']).to eq(60)
          expect(json['data']['primary_goal']).to eq('physique') # unchanged
        end

        it 'saves selected_workout_template_id and returns template name' do
          patch api_v1_user_preference_path,
                params: { user_preference: { selected_workout_template_id: workout_template.id } },
                headers: { 'X-CSRF-Token' => @csrf_token },
                as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']['selected_workout_template_id']).to eq(workout_template.id)
          expect(json['data']['selected_workout_template_name']).to eq('PPL Programme')
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) do
          {
            user_preference: {
              training_days_per_week: 1
            }
          }
        end

        it 'returns validation errors' do
          patch api_v1_user_preference_path,
                params: invalid_params,
                headers: { 'X-CSRF-Token' => @csrf_token },
                as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to be_present
        end
      end
    end

    context 'with JWT authentication (mobile client)' do
      let(:jwt_token) { AuthToken.for_user(user) }

      it 'updates user preferences with JWT' do
        update_params = {
          user_preference: {
            training_days_per_week: 5,
            preferred_workout_duration: 60
          }
        }

        patch api_v1_user_preference_path,
              params: update_params,
              headers: { 'Authorization' => "Bearer #{jwt_token}" },
              as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']['training_days_per_week']).to eq(5)
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        patch api_v1_user_preference_path,
              params: { user_preference: { training_days_per_week: 5 } },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
