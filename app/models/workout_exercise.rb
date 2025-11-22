class WorkoutExercise < ApplicationRecord
  # Associations
  belongs_to :workout
  belongs_to :exercise
  has_many :exercise_sets, -> { order(:set_number) }, dependent: :destroy
  
  # Validations
  validates :order_position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rest_between_sets, numericality: { greater_than: 0 }, allow_nil: true
  
  # Scopes
  scope :completed, -> { where(completed: true) }
  scope :in_order, -> { order(:order_position) }
  
  # Helper methods
  def total_sets
    exercise_sets.count
  end
  
  def total_volume
    # Volume = sum of (sets × reps × weight) for all sets
    exercise_sets.sum { |set| set.reps * (set.weight || 0) }
  end
  
  def max_weight
    # Highest weight lifted across all sets
    exercise_sets.maximum(:weight) || 0
  end
  
  def total_reps
    # Total reps across all sets
    exercise_sets.sum(:reps)
  end
  
  def average_rpe
    # Average Rate of Perceived Exertion
    rpe_values = exercise_sets.where.not(rpe: nil).pluck(:rpe)
    return nil if rpe_values.empty?
    
    (rpe_values.sum.to_f / rpe_values.size).round(1)
  end
end

