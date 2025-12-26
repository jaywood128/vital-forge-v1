require 'rails_helper'

RSpec.describe 'API V1 Workout Templates', type: :request do
  # Disable transactional fixtures for consistency
  self.use_transactional_tests = false

  before(:each) do
    # Clean database before each test
    WorkoutTemplateExercise.delete_all
    WorkoutTemplate.delete_all
    Exercise.delete_all
  end

  after(:all) do
    # Clean up after all tests
    WorkoutTemplateExercise.delete_all
    WorkoutTemplate.delete_all
    Exercise.delete_all
  end

  let!(:template1) do
    WorkoutTemplate.create!(
      name: 'Push Pull Legs',
      description: 'Classic 3-day split',
      goal_type: 'physique',
      difficulty_level: 'Intermediate',
      days_per_week: 6,
      estimated_duration_minutes: 45,
      total_exercises: 6,
      source: 'Bodybuilding.com',
      is_active: true
    )
  end

  let!(:template2) do
    WorkoutTemplate.create!(
      name: 'Strength Program',
      description: 'Build max strength',
      goal_type: 'strength',
      difficulty_level: 'Advanced',
      days_per_week: 4,
      estimated_duration_minutes: 60,
      total_exercises: 5,
      source: 'T-Nation',
      is_active: true
    )
  end

  let!(:inactive_template) do
    WorkoutTemplate.create!(
      name: 'Inactive Template',
      goal_type: 'physique',
      days_per_week: 3,
      is_active: false
    )
  end

  describe 'GET /api/v1/workout_templates' do
    it 'returns all active templates without authentication' do
      get '/api/v1/workout_templates', as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['data']).to be_an(Array)
      expect(json['data'].length).to eq(2)
      expect(json['data'].map { |t| t['name'] }).to include('Push Pull Legs', 'Strength Program')
      expect(json['data'].map { |t| t['name'] }).not_to include('Inactive Template')
    end

    it 'returns template attributes' do
      get '/api/v1/workout_templates', as: :json

      json = JSON.parse(response.body)
      template = json['data'].first

      expect(template).to have_key('id')
      expect(template).to have_key('name')
      expect(template).to have_key('description')
      expect(template).to have_key('goal_type')
      expect(template).to have_key('difficulty_level')
      expect(template).to have_key('days_per_week')
      expect(template).to have_key('estimated_duration_minutes')
      expect(template).to have_key('total_exercises')
      expect(template).to have_key('source')
    end

    it 'only returns active templates' do
      get '/api/v1/workout_templates', as: :json
      json = JSON.parse(response.body)
      expect(json['data'].none? { |t| t['name'] == 'Inactive Template' }).to be true
    end
  end

  describe 'GET /api/v1/workout_templates/:id' do
    let!(:exercise1) do
      Exercise.create!(
        name: 'Bench Press',
        description: 'Chest exercise',
        exercise_type: 'Strength',
        muscle_group: 'Chest',
        equipment: 'Barbell',
        difficulty_level: 'Intermediate'
      )
    end

    let!(:exercise2) do
      Exercise.create!(
        name: 'Squat',
        description: 'Leg exercise',
        exercise_type: 'Strength',
        muscle_group: 'Legs',
        equipment: 'Barbell',
        difficulty_level: 'Intermediate'
      )
    end

    let!(:template_exercise1) do
      WorkoutTemplateExercise.create!(
        workout_template: template1,
        exercise: exercise1,
        order_position: 1,
        recommended_sets: 4,
        recommended_reps: '8-12',
        rest_seconds: 90,
        notes: 'Focus on form'
      )
    end

    let!(:template_exercise2) do
      WorkoutTemplateExercise.create!(
        workout_template: template1,
        exercise: exercise2,
        order_position: 2,
        recommended_sets: 3,
        recommended_reps: '10',
        rest_seconds: 60
      )
    end

    it 'returns template with exercises without authentication' do
      get "/api/v1/workout_templates/#{template1.id}", as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['data']['id']).to eq(template1.id)
      expect(json['data']['name']).to eq('Push Pull Legs')
      expect(json['data']['exercises']).to be_an(Array)
      expect(json['data']['exercises'].length).to eq(2)
    end

    it 'returns exercises in correct order' do
      get "/api/v1/workout_templates/#{template1.id}", as: :json

      json = JSON.parse(response.body)
      exercises = json['data']['exercises']

      expect(exercises.first['exercise']['name']).to eq('Bench Press')
      expect(exercises.first['order_position']).to eq(1)
      expect(exercises.second['exercise']['name']).to eq('Squat')
      expect(exercises.second['order_position']).to eq(2)
    end

    it 'includes exercise details' do
      get "/api/v1/workout_templates/#{template1.id}", as: :json

      json = JSON.parse(response.body)
      exercise_entry = json['data']['exercises'].first

      expect(exercise_entry).to have_key('id')
      expect(exercise_entry).to have_key('exercise')
      expect(exercise_entry).to have_key('recommended_sets')
      expect(exercise_entry).to have_key('recommended_reps')
      expect(exercise_entry).to have_key('rest_seconds')
      expect(exercise_entry).to have_key('notes')
      expect(exercise_entry['recommended_sets']).to eq(4)
      expect(exercise_entry['recommended_reps']).to eq('8-12')
      expect(exercise_entry['exercise']).to have_key('name')
      expect(exercise_entry['exercise']['name']).to eq('Bench Press')
    end

    it 'returns 404 for non-existent template' do
      get '/api/v1/workout_templates/99999', as: :json

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Workout template not found')
    end
  end

  describe 'Data Integrity' do
    it 'ensures templates have required fields' do
      get '/api/v1/workout_templates', as: :json
      json = JSON.parse(response.body)
      json['data'].each do |template|
        expect(template['name']).to be_present
        expect(template['goal_type']).to be_present
        expect(template['days_per_week']).to be_a(Integer)
        expect(template['days_per_week']).to be >= 3
        expect(template['days_per_week']).to be <= 6
      end
    end
  end
end
