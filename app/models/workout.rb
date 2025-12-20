class Workout < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :workout_template, optional: true
  has_many :workout_exercises, -> { order(:order_position) }, dependent: :destroy
  has_many :exercises, through: :workout_exercises

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :workout_date, presence: true
  validates :duration_minutes, numericality: { greater_than: 0, allow_nil: true }
  validates :calories_burned, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :intensity_level, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 10,
    allow_nil: true
  }
  validates :workout_type, inclusion: {
    in: %w[Strength Cardio HIIT Yoga Flexibility Sports Other],
    allow_nil: true
  }

  # Scopes for common queries
  scope :completed, -> { where(completed: true) }
  scope :in_progress, -> { where(completed: false).where.not(started_at: nil) }
  scope :not_started, -> { where(completed: false, started_at: nil) }
  scope :from_template, -> { where.not(workout_template_id: nil) }
  scope :custom, -> { where(workout_template_id: nil) }
  scope :recent, -> { order(workout_date: :desc) }
  scope :by_date_range, ->(start_date, end_date) {
    where(workout_date: start_date..end_date)
  }
  scope :by_type, ->(type) { where(workout_type: type) }

  # Default scope to order by most recent first
  default_scope { order(workout_date: :desc) }

  # Helper methods
  def total_volume
    # Total volume across all exercises in this workout
    workout_exercises.sum(&:total_volume)
  end

  def total_sets
    # Count all sets across all exercises
    workout_exercises.sum(&:total_sets)
  end

  # Workout lifecycle methods
  def start!
    update!(started_at: Time.current)
  end

  def complete!
    update!(
      completed: true,
      completed_at: Time.current,
      duration_minutes: calculate_duration
    )
  end

  def all_exercises_completed?
    workout_exercises.any? && workout_exercises.all?(&:completed?)
  end

  def check_and_complete!
    complete! if all_exercises_completed? && !completed?
  end

  private

  def calculate_duration
    return nil unless started_at && completed_at
    ((completed_at - started_at) / 60).round
  end
end
