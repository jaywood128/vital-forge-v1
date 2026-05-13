# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkoutTemplateStarter do
  describe "#call" do
    let(:user) do
      User.create!(
        email: "token@example.com",
        password: "Password123!",
        first_name: "Token",
        last_name: "User"
      )
    end

    let(:exercise) do
      Exercise.create!(
        name: "Bench Press",
        exercise_type: "Strength",
        muscle_group: "Chest",
        equipment: "Barbell",
        difficulty_level: "Intermediate"
      )
    end

    let(:exercise2) do
      Exercise.create!(
        name: "Squat",
        exercise_type: "Strength",
        muscle_group: "Legs",
        equipment: "Barbell",
        difficulty_level: "Intermediate"
      )
    end

    let(:workout_template) do
      WorkoutTemplate.create!(
        name: "Upper Body Routine",
        goal_type: "physique",
        difficulty_level: "Beginner",
        days_per_week: 4,
        estimated_duration_minutes: 45,
        total_exercises: 1,
        source: "Test",
        is_active: true
      )
    end

    let!(:day1) do
      WorkoutTemplateDay.create!(
        workout_template: workout_template,
        day_number: 1,
        name: "Push Day"
      )
    end

    let!(:day2) do
      WorkoutTemplateDay.create!(
        workout_template: workout_template,
        day_number: 2,
        name: "Legs Day"
      )
    end

    let!(:day1_exercise) do
      WorkoutTemplateExercise.create!(
        workout_template: workout_template,
        workout_template_day: day1,
        exercise: exercise,
        order_position: 1,
        recommended_sets: 3,
        recommended_reps: "8-12",
        rest_seconds: 90,
        notes: "Controlled tempo"
      )
    end

    let!(:day2_exercise) do
      WorkoutTemplateExercise.create!(
        workout_template: workout_template,
        workout_template_day: day2,
        exercise: exercise2,
        order_position: 1,
        recommended_sets: 4,
        recommended_reps: "5",
        rest_seconds: 180,
        notes: "Heavy sets"
      )
    end

    it "creates a workout with exercises and sets from the template" do
      workout = WorkoutTemplateStarter.new(
        user: user,
        workout_template: workout_template,
        day_number: 1,
        scheduled_time: "07:30"
      ).call

      expect(workout).to be_persisted
      expect(workout.user).to eq(user)
      expect(workout.workout_template_id).to eq(workout_template.id)
      expect(workout.completed).to be(false)
      expect(workout.started_at).to be_present
      expect(workout.workout_type).to eq("Strength") # goal_type mapping
      expect(workout.scheduled_time.strftime("%H:%M")).to eq("07:30")

      expect(workout.workout_exercises.count).to eq(1)
      we = workout.workout_exercises.first
      expect(we.exercise_id).to eq(exercise.id)
      expect(we.order_position).to eq(1)
      expect(we.notes).to eq("Controlled tempo")

      expect(we.exercise_sets.count).to eq(3)
      expect(we.exercise_sets.map(&:reps)).to all(eq(8)) # parsed from "8-12"
      expect(we.exercise_sets.map(&:set_number)).to eq([ 1, 2, 3 ])
    end

    it "creates workout exercises only for the specified day_number" do
      workout = WorkoutTemplateStarter.new(
        user: user,
        workout_template: workout_template,
        day_number: 2
      ).call

      expect(workout.workout_exercises.count).to eq(1)
      expect(workout.workout_exercises.first.exercise_id).to eq(exercise2.id)
      expect(workout.workout_exercises.first.exercise_sets.count).to eq(4)
    end

    it "defaults to day 1 when day_number not provided" do
      workout = WorkoutTemplateStarter.new(
        user: user,
        workout_template: workout_template
      ).call

      expect(workout.workout_exercises.count).to eq(1)
      expect(workout.workout_exercises.first.exercise_id).to eq(exercise.id)
    end

    xit "raises when day_number has no matching day record"
  end
end
