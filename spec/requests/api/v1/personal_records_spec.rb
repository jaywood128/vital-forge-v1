# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Personal Records", type: :request do
  let(:user) { User.create!(email: "pr@example.com", password: "Password123!", first_name: "PR", last_name: "User") }
  let(:token) { AuthToken.for_user(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  let(:exercise_a) do
    Exercise.create!(name: "Squat", muscle_group: "Legs", equipment: "Barbell", exercise_type: "Strength")
  end
  let(:exercise_b) do
    Exercise.create!(name: "Bench Press", muscle_group: "Chest", equipment: "Barbell", exercise_type: "Strength")
  end

  def create_set_and_pr(user:, exercise:, weight:, reps:, estimated_1rm:, recorded_at: 1.week.ago)
    workout = user.workouts.create!(
      name: "Test", workout_date: Date.current,
      workout_type: "Strength", started_at: 2.hours.ago, completed: true, completed_at: 1.hour.ago,
      duration_minutes: 60
    )
    we = workout.workout_exercises.create!(exercise: exercise, order_position: 1, completed: true)
    set = we.exercise_sets.create!(set_number: 1, weight: weight, reps: reps, weight_unit: "lbs", completed: false)
    set.update_column(:completed, true)
    pr = PersonalRecord.create!(
      user: user, exercise: exercise, exercise_set: set,
      estimated_1rm: estimated_1rm, weight: weight, reps: reps, recorded_at: recorded_at
    )
    pr
  end

  describe "GET /api/v1/personal_records" do
    it "returns 401 when unauthenticated" do
      get "/api/v1/personal_records", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns an empty array when the user has no PRs" do
      get "/api/v1/personal_records", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns all PRs for the current user" do
      create_set_and_pr(user: user, exercise: exercise_a, weight: 225, reps: 5, estimated_1rm: 262.5)
      create_set_and_pr(user: user, exercise: exercise_b, weight: 185, reps: 5, estimated_1rm: 215.8)

      get "/api/v1/personal_records", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.length).to eq(2)
      expect(body.map { |pr| pr["exercise_id"] }).to contain_exactly(exercise_a.id, exercise_b.id)
    end

    it "returns the expected fields for each PR" do
      pr = create_set_and_pr(user: user, exercise: exercise_a, weight: 225, reps: 5, estimated_1rm: 262.5)

      get "/api/v1/personal_records", headers: headers, as: :json

      record = JSON.parse(response.body).first
      expect(record["exercise_id"]).to eq(exercise_a.id)
      expect(record["exercise_set_id"]).to eq(pr.exercise_set_id)
      expect(record["estimated_1rm"]).to eq(262.5)
      expect(record["weight"]).to eq(225.0)
      expect(record["reps"]).to eq(5)
      expect(record["recorded_at"]).to be_present
    end

    it "does not return PRs belonging to another user" do
      other = User.create!(email: "other@example.com", password: "Password123!", first_name: "O", last_name: "Ther")
      create_set_and_pr(user: other, exercise: exercise_a, weight: 315, reps: 5, estimated_1rm: 367.5)

      get "/api/v1/personal_records", headers: headers, as: :json

      expect(JSON.parse(response.body)).to eq([])
    end

    context "with exercise_id filter" do
      it "returns only PRs for the specified exercise" do
        create_set_and_pr(user: user, exercise: exercise_a, weight: 225, reps: 5, estimated_1rm: 262.5)
        create_set_and_pr(user: user, exercise: exercise_b, weight: 185, reps: 5, estimated_1rm: 215.8)

        get "/api/v1/personal_records", params: { exercise_id: exercise_a.id }, headers: headers, as: :json

        body = JSON.parse(response.body)
        expect(body.length).to eq(1)
        expect(body.first["exercise_id"]).to eq(exercise_a.id)
      end

      it "returns an empty array when no PRs exist for the exercise" do
        get "/api/v1/personal_records", params: { exercise_id: exercise_a.id }, headers: headers, as: :json
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end
end
