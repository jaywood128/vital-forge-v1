# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExerciseSet, type: :model do
  let(:user) do
    User.create!(
      email: "model@example.com",
      password: "Password123!",
      first_name: "Model",
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

  let(:workout) do
    user.workouts.create!(
      name: "Workout",
      workout_date: Date.current,
      workout_type: "Strength",
      completed: false
    )
  end

  let(:workout_exercise) do
    workout.workout_exercises.create!(
      exercise: exercise,
      order_position: 1,
      rest_between_sets: 90,
      completed: false
    )
  end

  describe "validations" do
    it "is invalid with non-positive reps" do
      set = workout_exercise.exercise_sets.build(set_number: 1, reps: 0, weight_unit: "lbs")
      expect(set).not_to be_valid
      expect(set.errors[:reps]).to be_present
    end

    it "is invalid with invalid weight_unit" do
      set = workout_exercise.exercise_sets.build(set_number: 1, reps: 5, weight_unit: "stone")
      expect(set).not_to be_valid
      expect(set.errors[:weight_unit]).to be_present
    end

    it "is invalid with rpe out of range" do
      set = workout_exercise.exercise_sets.build(set_number: 1, reps: 5, weight_unit: "lbs", rpe: 11)
      expect(set).not_to be_valid
      expect(set.errors[:rpe]).to be_present
    end
  end

  describe "helpers" do
    it "calculates volume as reps * weight" do
      set = workout_exercise.exercise_sets.create!(
        set_number: 1,
        reps: 10,
        weight: 100,
        weight_unit: "lbs"
      )
      expect(set.volume).to eq(1000)
    end

    it "describes intensity from rpe" do
      set = workout_exercise.exercise_sets.create!(
        set_number: 1,
        reps: 5,
        weight: 100,
        weight_unit: "lbs",
        rpe: 8
      )
      expect(set.intensity_description).to eq("Hard")
    end
  end
end
