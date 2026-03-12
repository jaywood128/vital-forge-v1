# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Exercise Sets", type: :request do
  before(:each) do
    # Clean database before each test
    WorkoutTemplateExercise.delete_all
    WorkoutTemplate.delete_all
  end

  describe "PATCH /api/v1/exercise_sets/:id" do
    it "updates a set for the current user (happy path)" do
      user = User.create!(
        email: "test@example.com",
        password: "Password123!",
        first_name: "Test",
        last_name: "User"
      )
      exercise = Exercise.create!(
        name: "Bench Press",
        exercise_type: "Strength",
        muscle_group: "Chest",
        equipment: "Barbell"
      )
      template = WorkoutTemplate.create!(
        name: "Upper Body Routine",
        goal_type: "physique",
        difficulty_level: "Beginner",
        days_per_week: 4,
        estimated_duration_minutes: 45,
        total_exercises: 1,
        source: "Test",
        is_active: true
      )
      day = WorkoutTemplateDay.create!(workout_template: template, day_number: 1, name: "Day 1")
      wte = template.workout_template_exercises.create!(
        exercise: exercise,
        workout_template_day: day,
        order_position: 1,
        recommended_sets: 3,
        recommended_reps: "8-12",
        rest_seconds: 90
      )
      workout = user.workouts.create!(
        name: template.name,
        workout_date: Date.current,
        workout_template_id: template.id
      )
      workout_exercise = workout.workout_exercises.create!(
        exercise: exercise,
        order_position: wte.order_position,
        notes: "Initial notes",
        rest_between_sets: wte.rest_seconds,
        completed: false
      )
      exercise_set = workout_exercise.exercise_sets.create!(
        set_number: 1,
        reps: 8,
        weight: 95,
        weight_unit: "lbs",
        completed: false
      )

      post "/api/v1/login",
           params: { user: { email: user.email, password: "Password123!" } },
           as: :json
      expect(response).to have_http_status(:ok)

      patch "/api/v1/exercise_sets/#{exercise_set.id}",
            params: {
              exercise_set: {
                reps: 10,
                weight: 115,
                weight_unit: "lbs",
                completed: true,
                notes: "Felt strong"
              }
            },
            as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.dig("exercise_set", "reps")).to eq(10)
      expect(json.dig("exercise_set", "weight").to_f).to eq(115.0)
      expect(json.dig("exercise_set", "completed")).to be(true)
      exercise_set.reload
      expect(exercise_set.reps).to eq(10)
      expect(exercise_set.weight).to eq(115)
      expect(exercise_set.completed).to be(true)
      expect(exercise_set.notes).to eq("Felt strong")
    end

    it "returns 422 on validation failure" do
      user = User.create!(
        email: "test2@example.com",
        password: "Password123!",
        first_name: "Test",
        last_name: "User"
      )
      exercise = Exercise.create!(
        name: "Squat",
        exercise_type: "Strength",
        muscle_group: "Legs",
        equipment: "Barbell"
      )
      template = WorkoutTemplate.create!(
        name: "Leg Day",
        goal_type: "strength",
        difficulty_level: "Beginner",
        days_per_week: 3,
        estimated_duration_minutes: 50,
        total_exercises: 1,
        source: "Test",
        is_active: true
      )
      day = WorkoutTemplateDay.create!(workout_template: template, day_number: 1, name: "Day 1")
      wte = template.workout_template_exercises.create!(
        exercise: exercise,
        workout_template_day: day,
        order_position: 1,
        recommended_sets: 3,
        recommended_reps: "5",
        rest_seconds: 120
      )
      workout = user.workouts.create!(
        name: template.name,
        workout_date: Date.current,
        workout_template_id: template.id
      )
      workout_exercise = workout.workout_exercises.create!(
        exercise: exercise,
        order_position: wte.order_position,
        rest_between_sets: wte.rest_seconds,
        completed: false
      )
      exercise_set = workout_exercise.exercise_sets.create!(
        set_number: 1,
        reps: 5,
        weight: 185,
        weight_unit: "lbs",
        completed: false
      )

      post "/api/v1/login",
           params: { user: { email: user.email, password: "Password123!" } },
           as: :json
      expect(response).to have_http_status(:ok)

      patch "/api/v1/exercise_sets/#{exercise_set.id}",
            params: { exercise_set: { reps: nil, weight: -10 } },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end

    it "returns 422 when weight_unit is invalid" do
      user = User.create!(
        email: "unit@example.com",
        password: "Password123!",
        first_name: "Unit",
        last_name: "User"
      )
      exercise = Exercise.create!(
        name: "Press",
        exercise_type: "Strength",
        muscle_group: "Chest",
        equipment: "Barbell"
      )
      template = WorkoutTemplate.create!(
        name: "Unit Template",
        goal_type: "physique",
        difficulty_level: "Beginner",
        days_per_week: 3,
        estimated_duration_minutes: 30,
        total_exercises: 1,
        source: "Test",
        is_active: true
      )
      day = WorkoutTemplateDay.create!(workout_template: template, day_number: 1, name: "Day 1")
      wte = template.workout_template_exercises.create!(
        exercise: exercise,
        workout_template_day: day,
        order_position: 1,
        recommended_sets: 1,
        recommended_reps: "5",
        rest_seconds: 60
      )
      workout = user.workouts.create!(
        name: template.name,
        workout_date: Date.current,
        workout_template_id: template.id
      )
      workout_exercise = workout.workout_exercises.create!(
        exercise: exercise,
        order_position: wte.order_position,
        rest_between_sets: wte.rest_seconds,
        completed: false
      )
      exercise_set = workout_exercise.exercise_sets.create!(
        set_number: 1,
        reps: 5,
        weight: 50,
        weight_unit: "lbs",
        completed: false
      )

      post "/api/v1/login",
           params: { user: { email: user.email, password: "Password123!" } },
           as: :json
      expect(response).to have_http_status(:ok)

      patch "/api/v1/exercise_sets/#{exercise_set.id}",
            params: { exercise_set: { weight_unit: "stone" } },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end

    it "returns 422 when rpe is out of range" do
      user = User.create!(
        email: "rpe@example.com",
        password: "Password123!",
        first_name: "Rpe",
        last_name: "User"
      )
      exercise = Exercise.create!(
        name: "Row",
        exercise_type: "Strength",
        muscle_group: "Back",
        equipment: "Barbell"
      )
      template = WorkoutTemplate.create!(
        name: "Rpe Template",
        goal_type: "strength",
        difficulty_level: "Beginner",
        days_per_week: 3,
        estimated_duration_minutes: 30,
        total_exercises: 1,
        source: "Test",
        is_active: true
      )
      day = WorkoutTemplateDay.create!(workout_template: template, day_number: 1, name: "Day 1")
      wte = template.workout_template_exercises.create!(
        exercise: exercise,
        workout_template_day: day,
        order_position: 1,
        recommended_sets: 1,
        recommended_reps: "5",
        rest_seconds: 60
      )
      workout = user.workouts.create!(
        name: template.name,
        workout_date: Date.current,
        workout_template_id: template.id
      )
      workout_exercise = workout.workout_exercises.create!(
        exercise: exercise,
        order_position: wte.order_position,
        rest_between_sets: wte.rest_seconds,
        completed: false
      )
      exercise_set = workout_exercise.exercise_sets.create!(
        set_number: 1,
        reps: 5,
        weight: 135,
        weight_unit: "lbs",
        completed: false
      )

      post "/api/v1/login",
           params: { user: { email: user.email, password: "Password123!" } },
           as: :json
      expect(response).to have_http_status(:ok)

      patch "/api/v1/exercise_sets/#{exercise_set.id}",
            params: { exercise_set: { rpe: 11 } },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end

    it "returns 404 when updating another user's set" do
      current_user = User.create!(
        email: "me@example.com",
        password: "Password123!",
        first_name: "Me",
        last_name: "User"
      )
      other_user = User.create!(
        email: "other@example.com",
        password: "Password123!",
        first_name: "Other",
        last_name: "User"
      )
      exercise = Exercise.create!(
        name: "Deadlift",
        exercise_type: "Strength",
        muscle_group: "Back",
        equipment: "Barbell"
      )
      template = WorkoutTemplate.create!(
        name: "Pull Day",
        goal_type: "strength",
        difficulty_level: "Intermediate",
        days_per_week: 4,
        estimated_duration_minutes: 60,
        total_exercises: 1,
        source: "Test",
        is_active: true
      )
      day = WorkoutTemplateDay.create!(workout_template: template, day_number: 1, name: "Day 1")
      wte = template.workout_template_exercises.create!(
        exercise: exercise,
        workout_template_day: day,
        order_position: 1,
        recommended_sets: 3,
        recommended_reps: "5",
        rest_seconds: 150
      )
      workout = other_user.workouts.create!(
        name: template.name,
        workout_date: Date.current,
        workout_template_id: template.id
      )
      workout_exercise = workout.workout_exercises.create!(
        exercise: exercise,
        order_position: wte.order_position,
        rest_between_sets: wte.rest_seconds,
        completed: false
      )
      exercise_set = workout_exercise.exercise_sets.create!(
        set_number: 1,
        reps: 5,
        weight: 225,
        weight_unit: "lbs",
        completed: false
      )

      post "/api/v1/login",
           params: { user: { email: current_user.email, password: "Password123!" } },
           as: :json
      expect(response).to have_http_status(:ok)

      patch "/api/v1/exercise_sets/#{exercise_set.id}",
            params: { exercise_set: { reps: 6 } },
            as: :json

      expect(response).to have_http_status(:not_found)
      exercise_set.reload
      expect(exercise_set.reps).to eq(5)
    end
  end
end
