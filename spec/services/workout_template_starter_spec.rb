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

    let(:workout_template) do
      WorkoutTemplate.create!(
        name: "Upper Body Routine",
        goal_type: "physique",          # must be "physique" or "strength"
        difficulty_level: "Beginner",
        days_per_week: 4,
        estimated_duration_minutes: 45,
        total_exercises: 1,
        source: "Test",
        is_active: true
      )
    end

    let!(:template_exercise) do
      workout_template.workout_template_exercises.create!(
        exercise: exercise,
        order_position: 1,
        recommended_sets: 3,
        recommended_reps: "8-12",
        rest_seconds: 90,
        notes: "Controlled tempo"
      )
    end

    it "creates a workout with exercises and sets from the template" do
      workout = WorkoutTemplateStarter.new(
        user: user,
        workout_template: workout_template,
        scheduled_time: "07:30"
      ).call

      expect(workout).to be_persisted
      expect(workout.user).to eq(user)
      expect(workout.workout_template_id).to eq(workout_template.id)
      expect(workout.completed).to be(false)
      expect(workout.started_at).to be_nil
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
  end
end
