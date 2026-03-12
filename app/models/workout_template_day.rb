class WorkoutTemplateDay < ApplicationRecord
  # Associations
  belongs_to :workout_template
  has_many :workout_template_exercises, -> { order(:order_position) }, dependent: :destroy
  has_many :exercises, through: :workout_template_exercises

  # Validations
  validates :workout_template_id, presence: true
  validates :day_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :name, presence: true, length: { maximum: 100 }
  validates :day_number, uniqueness: { scope: :workout_template_id }

  # Scopes
  scope :in_order, -> { order(:day_number) }
end
