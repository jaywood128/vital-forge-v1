require 'rails_helper'

RSpec.describe UserPreference, type: :model do
  let(:user) do
    User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Test',
      last_name: 'User'
    )
  end

  let(:workout_template) do
    WorkoutTemplate.create!(
      name: 'Test Programme',
      goal_type: 'physique',
      days_per_week: 4
    )
  end

  describe 'associations' do
    it 'belongs to user' do
      preference = UserPreference.new(user: user)
      expect(preference.user).to eq(user)
    end

    it 'optionally belongs to a workout template' do
      preference = UserPreference.create!(user: user, selected_workout_template: workout_template)
      expect(preference.selected_workout_template).to eq(workout_template)
    end

    it 'is valid without a selected workout template' do
      preference = UserPreference.new(user: user)
      expect(preference).to be_valid
    end
  end

  describe 'validations' do
    it 'validates primary_goal inclusion when present' do
      preference = UserPreference.new(user: user, primary_goal: 'invalid')
      expect(preference).not_to be_valid
      expect(preference.errors[:primary_goal]).to be_present
    end

    it 'allows nil primary_goal' do
      preference = UserPreference.new(user: user, primary_goal: nil)
      expect(preference).to be_valid
    end

    it 'validates training_days_per_week range when present' do
      preference = UserPreference.new(user: user, training_days_per_week: 2)
      expect(preference).not_to be_valid
      expect(preference.errors[:training_days_per_week]).to be_present

      preference.training_days_per_week = 7
      expect(preference).not_to be_valid
      expect(preference.errors[:training_days_per_week]).to be_present
    end

    it 'allows nil training_days_per_week' do
      preference = UserPreference.new(user: user, training_days_per_week: nil)
      expect(preference).to be_valid
    end

    it 'validates preferred_workout_duration is positive when present' do
      preference = UserPreference.new(user: user, preferred_workout_duration: 0)
      expect(preference).not_to be_valid
      expect(preference.errors[:preferred_workout_duration]).to be_present
    end

    it 'validates experience_level inclusion when present' do
      preference = UserPreference.new(user: user, experience_level: 'Expert')
      expect(preference).not_to be_valid
      expect(preference.errors[:experience_level]).to be_present
    end

    it 'allows valid experience_level values' do
      %w[Beginner Intermediate Advanced].each do |level|
        preference = UserPreference.new(user: user, experience_level: level)
        expect(preference).to be_valid
      end
    end
  end

  describe '#complete_onboarding!' do
    it 'sets onboarding_completed to true' do
      preference = UserPreference.create!(user: user)
      expect(preference.onboarding_completed).to be false

      preference.complete_onboarding!
      expect(preference.onboarding_completed).to be true
    end

    it 'sets onboarding_completed_at timestamp' do
      preference = UserPreference.create!(user: user)
      expect(preference.onboarding_completed_at).to be_nil

      preference.complete_onboarding!
      expect(preference.onboarding_completed_at).to be_present
      expect(preference.onboarding_completed_at).to be_within(1.second).of(Time.current)
    end
  end
end
