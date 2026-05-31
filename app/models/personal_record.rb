# frozen_string_literal: true

class PersonalRecord < ApplicationRecord
  belongs_to :user
  belongs_to :exercise
  belongs_to :exercise_set

  validates :estimated_1rm, :weight, :reps, :recorded_at, presence: true

  def self.current_best_for(user_id:, exercise_id:)
    where(user_id: user_id, exercise_id: exercise_id)
      .order(estimated_1rm: :desc)
      .first
  end
end
