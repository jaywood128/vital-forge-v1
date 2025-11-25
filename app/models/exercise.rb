class Exercise < ApplicationRecord
  # Associations
  has_many :workout_exercises, dependent: :restrict_with_error
  has_many :workouts, through: :workout_exercises

  # Validations
  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :exercise_type, presence: true, inclusion: {
    in: %w[Strength Cardio Mobility Hypertrophy Stability Endurance Flexibility]
  }
  validates :equipment, presence: true, inclusion: {
    in: %w[Bodyweight Dumbbells Barbell Kettlebells MedicineBall Cable Machine Bench Bands Other]
  }
  validates :muscle_group, inclusion: {
    in: %w[Chest Back Legs Shoulders Arms Core FullBody],
    allow_nil: true
  }
  validates :difficulty_level, inclusion: {
    in: %w[Beginner Intermediate Advanced],
    allow_nil: true
  }

  # Scopes
  scope :by_type, ->(type) { where(exercise_type: type) }
  scope :by_equipment, ->(equipment) { where(equipment: equipment) }
  scope :by_muscle, ->(muscle_group) { where(muscle_group: muscle_group) }
  scope :by_difficulty, ->(level) { where(difficulty_level: level) }
  scope :alphabetical, -> { order(:name) }

  # Helper methods
  def display_name
    "#{name} (#{equipment})"
  end
end
