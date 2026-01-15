class WeeklyFeedback < ApplicationRecord
  belongs_to :user

  validates :week_start, presence: true
  validates :feedback_text, presence: true
  validates :generated_at, presence: true
  validates :week_start, uniqueness: { scope: :user_id, message: "feedback already exists for this week" }
end
