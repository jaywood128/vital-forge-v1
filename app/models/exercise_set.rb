class ExerciseSet < ApplicationRecord
  # Associations
  belongs_to :workout_exercise

  # Validations
  validates :set_number, presence: true,
            uniqueness: { scope: :workout_exercise_id },
            numericality: { greater_than: 0 }
  validates :reps, presence: true, numericality: { greater_than: 0 }
  validates :weight, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :weight_unit, inclusion: { in: %w[lbs kg] }
  validates :rpe, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 10
  }, allow_nil: true
  validates :rest_after_seconds, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :completed, -> { where(completed: true) }
  scope :in_order, -> { order(:set_number) }
  scope :with_weight, -> { where.not(weight: nil) }
  scope :to_failure, -> { where(to_failure: true) }

  # Callbacks
  after_save :check_exercise_completion

  # Helper methods
  def volume
    # Volume for this set = reps × weight
    reps * (weight || 0)
  end


  def display_set
    # Human-readable format: "Set 1: 135 lbs × 10 reps"
    weight_str = weight ? "#{weight} #{weight_unit}" : "bodyweight"
    "Set #{set_number}: #{weight_str} × #{reps} reps"
  end


  def one_rep_max
    # Estimate 1RM using Brzycki formula: weight / (1.0278 - 0.0278 × reps)
    return nil unless weight && reps > 0 && reps <= 12


    (weight / (1.0278 - (0.0278 * reps))).round(2)
  end


  def intensity_description
    return nil unless rpe


    case rpe
    when 1..3 then "Light"
    when 4..6 then "Moderate"
    when 7..8 then "Hard"
    when 9..10 then "Maximum"
    end
  end

  private

  def check_exercise_completion
    workout_exercise.check_and_complete!
    workout_exercise.workout.check_and_complete!
  end
end
