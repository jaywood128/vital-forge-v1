# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "API V1 Exercise Sets", type: :request do
  let(:user) do
    User.create!(
      email: "sets.swagger@example.com",
      password: "Password123!",
      first_name: "Sets",
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

  let(:exercise) do
    Exercise.create!(
      name: "Swagger Bench Press",
      exercise_type: "Strength",
      muscle_group: "Chest",
      equipment: "Barbell"
    )
  end

  let(:template) do
    WorkoutTemplate.create!(
      name: "Sets Template",
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
        exercise: exercise,
        workout_template_day: day,
        order_position: 1,
        recommended_sets: 3,
        recommended_reps: "8-12",
        rest_seconds: 60
      )
    end
  end

  let!(:workout) do
    user.workouts.create!(
      name: template.name,
      workout_date: Date.current,
      workout_template_id: template.id
    )
  end

  let!(:workout_exercise) do
    workout.workout_exercises.create!(
      exercise: exercise,
      order_position: 1,
      rest_between_sets: 60,
      completed: false
    )
  end

  let!(:set_record) do
    workout_exercise.exercise_sets.create!(
      set_number: 1,
      reps: 8,
      weight: 95,
      weight_unit: "lbs",
      completed: false
    )
  end

  path "/api/v1/exercise_sets/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Exercise set ID"

    patch "Update exercise set" do
      operationId "updateExerciseSet"
      tags "Exercise Sets"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      description "Updates an exercise set (reps, weight, completed, notes, etc.). Set must belong to the current user's workout. Use the 'Authorize' button at the top right to set your JWT token."

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          exercise_set: {
            type: :object,
            properties: {
              reps: { type: :integer },
              weight: { type: :number },
              weight_unit: { type: :string },
              rest_after_seconds: { type: :integer },
              rpe: { type: :integer },
              to_failure: { type: :boolean },
              notes: { type: :string },
              completed: { type: :boolean }
            }
          }
        },
        required: [ "exercise_set" ]
      }

      response "200", "exercise set updated" do
        schema type: :object,
          properties: {
            exercise_set: { "$ref" => "#/components/schemas/ExerciseSet" }
          }

        let(:id) { set_record.id }
        let(:Authorization) { jwt_auth }
        let(:payload) do
          {
            exercise_set: {
              reps: 10,
              weight: 115,
              weight_unit: "lbs",
              completed: true,
              notes: "Felt strong"
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["exercise_set"]["reps"]).to eq(10)
          expect(data["exercise_set"]["completed"]).to be(true)
        end
      end

      response "404", "exercise set not found" do
        schema type: :object, properties: { error: { type: :string } }
        let(:id) { 999_999 }
        let(:Authorization) { jwt_auth }
        let(:payload) { { exercise_set: { reps: 10 } } }
        run_test!
      end

      response "401", "unauthorized" do
        let(:id) { set_record.id }
        let(:Authorization) { nil }
        let(:payload) { { exercise_set: { reps: 10 } } }
        run_test!
      end
    end
  end
end
