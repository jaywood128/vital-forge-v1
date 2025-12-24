class WorkoutTemplate < ApplicationRecord
  # Associations
  has_many :workout_template_exercises, -> { order(:order_position) }, dependent: :destroy
  has_many :exercises, through: :workout_template_exercises

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :goal_type, presence: true, inclusion: {
    in: %w[physique strength],
    message: "%{value} is not a valid goal type"
  }
  validates :difficulty_level, inclusion: {
    in: %w[Beginner Intermediate Advanced],
    allow_nil: true
  }
  validates :days_per_week, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 3,
    less_than_or_equal_to: 6
  }
  validates :estimated_duration_minutes, numericality: {
    only_integer: true,
    greater_than: 0,
    allow_nil: true
  }
  validates :total_exercises, numericality: {
    only_integer: true,
    greater_than: 0,
    allow_nil: true
  }

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :by_goal, ->(goal) { where(goal_type: goal) }
  scope :by_difficulty, ->(level) { where(difficulty_level: level) }
  scope :by_days_per_week, ->(days) { where(days_per_week: days) }

  # Helper methods
  def exercise_count
    workout_template_exercises.count
  end

  def formatted_duration
    return "N/A" unless estimated_duration_minutes

    "#{estimated_duration_minutes} minutes"
  end
end
