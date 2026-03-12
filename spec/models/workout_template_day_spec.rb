require 'rails_helper'

RSpec.describe WorkoutTemplateDay, type: :model do
  let(:template) { WorkoutTemplate.create!(name: "Test Template", goal_type: "physique", days_per_week: 3, difficulty_level: "Beginner") }

  describe "associations" do
    it "belongs to workout_template" do
      day = WorkoutTemplateDay.new(workout_template: template, day_number: 1, name: "Push Day")
      expect(day.workout_template).to eq(template)
    end

    it "has many workout_template_exercises that are destroyed with the day" do
      day = WorkoutTemplateDay.create!(workout_template: template, day_number: 1, name: "Push Day")
      exercise = Exercise.create!(name: "Bench Press", exercise_type: "Strength", equipment: "Barbell")
      day.workout_template_exercises.create!(
        workout_template: template,
        exercise: exercise,
        order_position: 1,
        recommended_sets: 3,
        recommended_reps: "8-10"
      )
      expect { day.destroy }.to change(WorkoutTemplateExercise, :count).by(-1)
    end

    it "has many exercises through workout_template_exercises" do
      day = WorkoutTemplateDay.create!(workout_template: template, day_number: 1, name: "Push Day")
      exercise = Exercise.create!(name: "Cable Fly", exercise_type: "Hypertrophy", equipment: "Cable")
      day.workout_template_exercises.create!(
        workout_template: template,
        exercise: exercise,
        order_position: 1,
        recommended_sets: 3,
        recommended_reps: "12-15"
      )
      expect(day.exercises).to include(exercise)
    end
  end

  describe "validations" do
    subject do
      WorkoutTemplateDay.new(workout_template: template, day_number: 1, name: "Push Day")
    end

    it "is valid with all required attributes" do
      expect(subject).to be_valid
    end

    it "requires workout_template_id" do
      subject.workout_template = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:workout_template]).to be_present
    end

    it "requires day_number" do
      subject.day_number = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:day_number]).to be_present
    end

    it "requires day_number to be a positive integer" do
      subject.day_number = 0
      expect(subject).not_to be_valid

      subject.day_number = -1
      expect(subject).not_to be_valid
    end

    it "requires name" do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to be_present
    end

    it "enforces name length maximum of 100" do
      subject.name = "A" * 101
      expect(subject).not_to be_valid
    end

    it "enforces uniqueness of day_number scoped to workout_template_id" do
      subject.save!
      duplicate = WorkoutTemplateDay.new(workout_template: template, day_number: 1, name: "Another Day 1")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:day_number]).to be_present
    end

    it "allows the same day_number for different templates" do
      subject.save!
      other_template = WorkoutTemplate.create!(name: "Other Template", goal_type: "strength", days_per_week: 3, difficulty_level: "Beginner")
      other_day = WorkoutTemplateDay.new(workout_template: other_template, day_number: 1, name: "Day 1")
      expect(other_day).to be_valid
    end

    it "allows optional estimated_duration_minutes" do
      subject.estimated_duration_minutes = nil
      expect(subject).to be_valid
    end

    it "allows optional muscle_focus" do
      subject.muscle_focus = nil
      expect(subject).to be_valid
    end
  end

  describe "scopes" do
    it "orders by day_number with in_order scope" do
      WorkoutTemplateDay.create!(workout_template: template, day_number: 3, name: "Legs Day")
      WorkoutTemplateDay.create!(workout_template: template, day_number: 1, name: "Push Day")
      WorkoutTemplateDay.create!(workout_template: template, day_number: 2, name: "Pull Day")

      ordered = WorkoutTemplateDay.where(workout_template: template).in_order
      expect(ordered.map(&:day_number)).to eq([ 1, 2, 3 ])
    end
  end
end
