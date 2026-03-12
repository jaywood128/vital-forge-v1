require 'rails_helper'

RSpec.describe WorkoutTemplateExercise, type: :model do
  let(:template) do
    WorkoutTemplate.create!(
      name: 'Test Template',
      goal_type: 'physique',
      days_per_week: 3
    )
  end

  let(:exercise) do
    Exercise.create!(
      name: 'Test Exercise',
      exercise_type: 'Strength',
      equipment: 'Barbell'
    )
  end

  describe 'associations' do
    it 'belongs to workout_template' do
      wte = WorkoutTemplateExercise.new(
        workout_template: template,
        exercise: exercise,
        order_position: 1,
        recommended_sets: 3,
        recommended_reps: '10'
      )
      expect(wte.workout_template).to eq(template)
    end

    it 'belongs to exercise' do
      wte = WorkoutTemplateExercise.new(
        workout_template: template,
        exercise: exercise,
        order_position: 1,
        recommended_sets: 3,
        recommended_reps: '10'
      )
      expect(wte.exercise).to eq(exercise)
    end
  end

  describe 'validations' do
    it 'requires order_position' do
      wte = WorkoutTemplateExercise.new(
        workout_template: template,
        exercise: exercise,
        recommended_sets: 3,
        recommended_reps: '10'
      )
      wte.order_position = nil
      expect(wte).not_to be_valid
      expect(wte.errors[:order_position]).to include("can't be blank")
    end

    it 'requires recommended_sets' do
      wte = WorkoutTemplateExercise.new(
        workout_template: template,
        exercise: exercise,
        order_position: 1,
        recommended_reps: '10'
      )
      wte.recommended_sets = nil
      expect(wte).not_to be_valid
      expect(wte.errors[:recommended_sets]).to include("can't be blank")
    end

    it 'requires recommended_reps' do
      wte = WorkoutTemplateExercise.new(
        workout_template: template,
        exercise: exercise,
        order_position: 1,
        recommended_sets: 3
      )
      wte.recommended_reps = nil
      expect(wte).not_to be_valid
      expect(wte.errors[:recommended_reps]).to include("can't be blank")
    end

    it 'validates recommended_sets is greater than 0' do
      wte = WorkoutTemplateExercise.new(
        workout_template: template,
        exercise: exercise,
        order_position: 1,
        recommended_sets: 0,
        recommended_reps: '10'
      )
      expect(wte).not_to be_valid
      expect(wte.errors[:recommended_sets]).to be_present
    end

    it 'validates rest_seconds is non-negative when present' do
      wte = WorkoutTemplateExercise.new(
        workout_template: template,
        exercise: exercise,
        order_position: 1,
        recommended_sets: 3,
        recommended_reps: '10',
        rest_seconds: -10
      )
      expect(wte).not_to be_valid
      expect(wte.errors[:rest_seconds]).to be_present
    end
  end

  describe 'default scope' do
    it 'orders by order_position' do
      day = WorkoutTemplateDay.create!(workout_template: template, day_number: 1, name: 'Day 1')
      wte1 = WorkoutTemplateExercise.create!(
        workout_template: template,
        workout_template_day: day,
        exercise: exercise,
        order_position: 2,
        recommended_sets: 3,
        recommended_reps: '10'
      )
      exercise2 = Exercise.create!(name: 'Exercise 2', exercise_type: 'Strength', equipment: 'Dumbbells')
      wte2 = WorkoutTemplateExercise.create!(
        workout_template: template,
        workout_template_day: day,
        exercise: exercise2,
        order_position: 1,
        recommended_sets: 3,
        recommended_reps: '12'
      )

      expect(WorkoutTemplateExercise.all.first).to eq(wte2)
      expect(WorkoutTemplateExercise.all.last).to eq(wte1)
    end
  end
end
