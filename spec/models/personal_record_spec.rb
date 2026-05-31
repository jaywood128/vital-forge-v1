# frozen_string_literal: true

require "rails_helper"

RSpec.describe PersonalRecord, type: :model do
  let(:user) do
    User.create!(
      email: "pr_model@example.com",
      password: "Password123!",
      first_name: "PR",
      last_name: "User"
    )
  end

  let(:exercise) do
    Exercise.create!(
      name: "Bench Press",
      exercise_type: "Strength",
      muscle_group: "Chest",
      equipment: "Barbell"
    )
  end

  let(:workout) do
    user.workouts.create!(
      name: "Test Workout",
      workout_date: Date.current,
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

  let(:exercise_set) do
    workout_exercise.exercise_sets.create!(
      set_number: 1,
      reps: 8,
      weight: 225,
      weight_unit: "lbs",
      completed: true
    )
  end

  def build_pr(overrides = {})
    PersonalRecord.new({
      user: user,
      exercise: exercise,
      exercise_set: exercise_set,
      estimated_1rm: 300.0,
      weight: 225.0,
      reps: 8,
      recorded_at: Time.current
    }.merge(overrides))
  end

  it "is valid with all required fields" do
    expect(build_pr).to be_valid
  end

  it "is invalid without estimated_1rm" do
    expect(build_pr(estimated_1rm: nil)).not_to be_valid
  end

  it "is invalid without weight" do
    expect(build_pr(weight: nil)).not_to be_valid
  end

  it "is invalid without reps" do
    expect(build_pr(reps: nil)).not_to be_valid
  end

  it "is invalid without recorded_at" do
    expect(build_pr(recorded_at: nil)).not_to be_valid
  end

  describe ".current_best_for" do
    it "returns the row with the highest estimated_1rm for the user + exercise" do
      exercise_set_2 = workout_exercise.exercise_sets.create!(
        set_number: 2, reps: 10, weight: 205, weight_unit: "lbs", completed: true
      )

      PersonalRecord.create!(
        user: user, exercise: exercise, exercise_set: exercise_set,
        estimated_1rm: 280.0, weight: 205.0, reps: 10, recorded_at: 2.weeks.ago
      )
      PersonalRecord.create!(
        user: user, exercise: exercise, exercise_set: exercise_set_2,
        estimated_1rm: 320.0, weight: 245.0, reps: 8, recorded_at: 1.week.ago
      )

      best = PersonalRecord.current_best_for(user_id: user.id, exercise_id: exercise.id)
      expect(best.estimated_1rm).to eq(320.0)
    end

    it "returns nil when no records exist for the exercise" do
      expect(
        PersonalRecord.current_best_for(user_id: user.id, exercise_id: exercise.id)
      ).to be_nil
    end
  end
end
