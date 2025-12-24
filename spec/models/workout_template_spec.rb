require 'rails_helper'

RSpec.describe WorkoutTemplate, type: :model do
  describe 'associations' do
    it 'has many workout_template_exercises' do
      template = WorkoutTemplate.create!(
        name: 'Test Template',
        goal_type: 'physique',
        days_per_week: 3
      )
      expect(template).to respond_to(:workout_template_exercises)
    end

    it 'has many exercises through workout_template_exercises' do
      template = WorkoutTemplate.create!(
        name: 'Test Template',
        goal_type: 'physique',
        days_per_week: 3
      )
      expect(template).to respond_to(:exercises)
    end
  end

  describe 'validations' do
    it 'requires name' do
      template = WorkoutTemplate.new(goal_type: 'physique', days_per_week: 3)
      expect(template).not_to be_valid
      expect(template.errors[:name]).to include("can't be blank")
    end

    it 'requires goal_type' do
      template = WorkoutTemplate.new(name: 'Test', days_per_week: 3)
      expect(template).not_to be_valid
      expect(template.errors[:goal_type]).to include("can't be blank")
    end

    it 'validates goal_type inclusion' do
      template = WorkoutTemplate.new(name: 'Test', goal_type: 'invalid', days_per_week: 3)
      expect(template).not_to be_valid
      expect(template.errors[:goal_type]).to be_present
    end

    it 'validates difficulty_level inclusion when present' do
      template = WorkoutTemplate.new(
        name: 'Test',
        goal_type: 'physique',
        days_per_week: 3,
        difficulty_level: 'Expert'
      )
      expect(template).not_to be_valid
      expect(template.errors[:difficulty_level]).to be_present
    end

    it 'requires days_per_week' do
      template = WorkoutTemplate.new(name: 'Test', goal_type: 'physique')
      expect(template).not_to be_valid
      expect(template.errors[:days_per_week]).to include("can't be blank")
    end

    it 'validates days_per_week range' do
      template = WorkoutTemplate.new(name: 'Test', goal_type: 'physique', days_per_week: 2)
      expect(template).not_to be_valid
      expect(template.errors[:days_per_week]).to be_present
    end
  end

  describe 'scopes' do
    before do
      WorkoutTemplate.destroy_all
    end

    describe '.active' do
      it 'returns only active templates' do
        active = WorkoutTemplate.create!(name: 'Active', goal_type: 'physique', days_per_week: 3, is_active: true)
        inactive = WorkoutTemplate.create!(name: 'Inactive', goal_type: 'strength', days_per_week: 4, is_active: false)

        expect(WorkoutTemplate.active).to include(active)
        expect(WorkoutTemplate.active).not_to include(inactive)
      end
    end

    describe '.by_goal' do
      it 'returns templates with specified goal' do
        physique = WorkoutTemplate.create!(name: 'Physique', goal_type: 'physique', days_per_week: 3)
        strength = WorkoutTemplate.create!(name: 'Strength', goal_type: 'strength', days_per_week: 4)

        expect(WorkoutTemplate.by_goal('physique')).to include(physique)
        expect(WorkoutTemplate.by_goal('physique')).not_to include(strength)
      end
    end

    describe '.by_difficulty' do
      it 'returns templates with specified difficulty' do
        beginner = WorkoutTemplate.create!(
          name: 'Beginner',
          goal_type: 'physique',
          days_per_week: 3,
          difficulty_level: 'Beginner'
        )
        advanced = WorkoutTemplate.create!(
          name: 'Advanced',
          goal_type: 'strength',
          days_per_week: 5,
          difficulty_level: 'Advanced'
        )

        expect(WorkoutTemplate.by_difficulty('Beginner')).to include(beginner)
        expect(WorkoutTemplate.by_difficulty('Beginner')).not_to include(advanced)
      end
    end

    describe '.by_days_per_week' do
      it 'returns templates with specified days per week' do
        three_day = WorkoutTemplate.create!(name: '3 Day', goal_type: 'physique', days_per_week: 3)
        five_day = WorkoutTemplate.create!(name: '5 Day', goal_type: 'strength', days_per_week: 5)

        expect(WorkoutTemplate.by_days_per_week(3)).to include(three_day)
        expect(WorkoutTemplate.by_days_per_week(3)).not_to include(five_day)
      end
    end
  end

  describe '#exercise_count' do
    it 'returns the number of exercises in the template' do
      template = WorkoutTemplate.create!(name: 'Test', goal_type: 'physique', days_per_week: 3)
      exercise1 = Exercise.create!(name: 'Exercise 1', exercise_type: 'Strength', equipment: 'Barbell')
      exercise2 = Exercise.create!(name: 'Exercise 2', exercise_type: 'Strength', equipment: 'Dumbbells')

      WorkoutTemplateExercise.create!(
        workout_template: template,
        exercise: exercise1,
        order_position: 1,
        recommended_sets: 3,
        recommended_reps: '10'
      )
      WorkoutTemplateExercise.create!(
        workout_template: template,
        exercise: exercise2,
        order_position: 2,
        recommended_sets: 3,
        recommended_reps: '12'
      )

      expect(template.exercise_count).to eq(2)
    end
  end

  describe '#formatted_duration' do
    it 'returns formatted duration when present' do
      template = WorkoutTemplate.create!(
        name: 'Test',
        goal_type: 'physique',
        days_per_week: 3,
        estimated_duration_minutes: 45
      )
      expect(template.formatted_duration).to eq('45 minutes')
    end

    it 'returns N/A when duration is nil' do
      template = WorkoutTemplate.create!(name: 'Test', goal_type: 'physique', days_per_week: 3)
      expect(template.formatted_duration).to eq('N/A')
    end
  end
end
