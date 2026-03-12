class WorkoutTemplateExercise < ApplicationRecord
  # Associations
  belongs_to :workout_template
  belongs_to :workout_template_day
  belongs_to :exercise

  # Validations
  validates :order_position, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0
  }
  validates :recommended_sets, presence: true, numericality: {
    only_integer: true,
    greater_than: 0
  }
  validates :recommended_reps, presence: true
  validates :rest_seconds, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    allow_nil: true
  }

  # Scopes
  default_scope { order(:order_position) }
end
