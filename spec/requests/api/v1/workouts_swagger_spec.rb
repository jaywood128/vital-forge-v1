# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "API V1 Workouts", type: :request do
  let(:user) do
    User.create!(
      email: "workouts.swagger@example.com",
      password: "Password123!",
      first_name: "Workout",
      last_name: "User"
    )
  end

  let(:jwt_auth) do
    post api_v1_mobile_login_path,
      params: { user: { email: user.email, password: "Password123!" } },
      as: :json
    token = JSON.parse(response.body).dig("data", "token")
    "Bearer #{token}"
  end

  let!(:workout_not_started) do
    user.workouts.create!(
      name: "Swagger Test Workout",
      workout_date: Date.current,
      completed: false,
      started_at: nil
    )
  end

  let!(:workout_started) do
    user.workouts.create!(
      name: "In Progress Workout",
      workout_date: Date.current,
      completed: false,
      started_at: 1.hour.ago
    )
  end

  path "/api/v1/workouts" do
    get "List workouts" do
      operationId "listWorkouts"
      tags "Workouts"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      description "Returns workouts for the authenticated user. Optionally filter by date range. Use JWT token from mobile login/signup."

      parameter name: :start_date, in: :query, type: :string, format: :date, required: false,
        description: "Filter workouts on or after this date (YYYY-MM-DD)"
      parameter name: :end_date, in: :query, type: :string, format: :date, required: false,
        description: "Filter workouts on or before this date (YYYY-MM-DD)"

      response "200", "workouts list" do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: { "$ref" => "#/components/schemas/WorkoutWithExercises" }
            }
          }

        let(:Authorization) { jwt_auth }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]).to be_an(Array)
        end
      end

      response "401", "unauthorized" do
        schema type: :object, properties: { error: { type: :string } }
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  path "/api/v1/workouts/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Workout ID"

    get "Get workout" do
      operationId "getWorkout"
      tags "Workouts"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      description "Returns a single workout with exercises and sets. Use JWT token from mobile login/signup."

      response "200", "workout found" do
        schema type: :object,
          properties: {
            data: { "$ref" => "#/components/schemas/WorkoutWithExercises" }
          }

        let(:id) { workout_not_started.id }
        let(:Authorization) { jwt_auth }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["id"]).to eq(workout_not_started.id)
        end
      end

      response "404", "workout not found" do
        schema type: :object, properties: { error: { type: :string } }
        let(:id) { 999_999 }
        let(:Authorization) { jwt_auth }
        run_test!
      end

      response "401", "unauthorized" do
        let(:id) { workout_not_started.id }
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  path "/api/v1/workouts/{id}/start" do
    parameter name: :id, in: :path, type: :integer, description: "Workout ID"

    patch "Start workout" do
      operationId "startWorkout"
      tags "Workouts"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      description "Marks the workout as started (sets started_at). Use JWT token from mobile login/signup."

      response "200", "workout started" do
        schema type: :object,
          properties: {
            workout: { "$ref" => "#/components/schemas/Workout" }
          }

        let(:id) { workout_not_started.id }
        let(:Authorization) { jwt_auth }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["workout"]["started_at"]).to be_present
        end
      end

      response "404", "workout not found" do
        let(:id) { 999_999 }
        let(:Authorization) { jwt_auth }
        run_test!
      end

      response "422", "invalid transition (e.g. already started)" do
        schema type: :object, properties: { error: { type: :string } }
        let(:id) { workout_started.id }
        let(:Authorization) { jwt_auth }
        run_test!
      end
    end
  end

  path "/api/v1/workouts/{id}/complete" do
    parameter name: :id, in: :path, type: :integer, description: "Workout ID"

    patch "Complete workout" do
      operationId "completeWorkout"
      tags "Workouts"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      description "Marks the workout as completed. Workout must have been started first. Use JWT token from mobile login/signup."

      response "200", "workout completed" do
        schema type: :object,
          properties: {
            workout: { "$ref" => "#/components/schemas/Workout" }
          }

        let(:id) { workout_started.id }
        let(:Authorization) { jwt_auth }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["workout"]["completed"]).to be(true)
          expect(data["workout"]["completed_at"]).to be_present
        end
      end

      response "404", "workout not found" do
        let(:id) { 999_999 }
        let(:Authorization) { jwt_auth }
        run_test!
      end

      response "422", "invalid transition (e.g. not started)" do
        schema type: :object, properties: { error: { type: :string } }
        let(:id) { workout_not_started.id }
        let(:Authorization) { jwt_auth }
        run_test!
      end
    end
  end

  path "/api/v1/workout_templates/{id}/start" do
    parameter name: :id, in: :path, type: :integer, description: "Workout template ID"

    post "Start workout from template" do
      operationId "startWorkoutFromTemplate"
      tags "Workouts"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      description "Creates a new workout from a template and returns it. Optional scheduled_time (HH:MM)."

      parameter name: :scheduled_time, in: :query, type: :string, required: false,
        description: "Scheduled time of day (HH:MM)"

      response "201", "workout created from template" do
        schema type: :object,
          properties: {
            workout: { "$ref" => "#/components/schemas/WorkoutWithExercises" }
          }

        let(:id) { template.id }
        let(:Authorization) { jwt_auth }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["workout"]["workout_template_id"]).to eq(template.id)
          expect(data["workout"]["completed"]).to be(false)
        end
      end

      response "404", "template not found" do
        schema type: :object, properties: { error: { type: :string } }
        let(:id) { 999_999 }
        let(:Authorization) { jwt_auth }
        run_test!
      end

      response "409", "active workout from this template already exists" do
        schema type: :object,
          properties: {
            error: { type: :string },
            active_workout_id: { type: :integer }
          }
        let(:id) { template.id }
        let(:Authorization) { jwt_auth }

        before do
          user.workouts.create!(
            name: template.name,
            workout_date: Date.current,
            workout_template_id: template.id,
            completed: false
          )
        end

        run_test!
      end
    end
  end

  # Template and exercise for start_from_template
  let(:template_exercise) do
    Exercise.create!(
      name: "Swagger Template Exercise",
      exercise_type: "Strength",
      muscle_group: "Chest",
      equipment: "Barbell"
    )
  end

  let(:template) do
    WorkoutTemplate.create!(
      name: "Swagger Template",
      goal_type: "physique",
      difficulty_level: "Beginner",
      days_per_week: 3,
      estimated_duration_minutes: 30,
      total_exercises: 1,
      source: "Swagger",
      is_active: true
    ).tap do |t|
      day = WorkoutTemplateDay.create!(workout_template: t, day_number: 1, name: "Day 1")
      t.workout_template_exercises.create!(
        exercise: template_exercise,
        workout_template_day: day,
        order_position: 1,
        recommended_sets: 3,
        recommended_reps: "8-12",
        rest_seconds: 60
      )
    end
  end
end
