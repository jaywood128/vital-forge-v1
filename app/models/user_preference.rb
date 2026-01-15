class UserPreference < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :primary_goal, inclusion: {
    in: %w[physique strength],
    allow_nil: true,
    message: "%{value} is not a valid goal"
  }
  validates :training_days_per_week, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 3,
    less_than_or_equal_to: 6,
    allow_nil: true
  }
  validates :preferred_workout_duration, numericality: {
    only_integer: true,
    greater_than: 0,
    allow_nil: true
  }
  validates :experience_level, inclusion: {
    in: %w[Beginner Intermediate Advanced],
    allow_nil: true
  }

  # Instance methods
  def complete_onboarding!
    update!(
      onboarding_completed: true,
      onboarding_completed_at: Time.current
    )
  end
end
