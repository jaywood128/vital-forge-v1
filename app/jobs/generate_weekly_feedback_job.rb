class GenerateWeeklyFeedbackJob
  include Sidekiq::Job
  sidekiq_options queue: :ai, retry: 3

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    week_start = Date.current.beginning_of_week

    # Check if feedback already exists for this week (idempotent)
    existing_feedback = WeeklyFeedback.find_by(
      user: user,
      week_start: week_start
    )

    if existing_feedback.present?
      Rails.logger.info "Skipping AI feedback for user #{user.id} - feedback already exists for week starting #{week_start}"
      return
    end

    Rails.logger.info "Generating AI feedback for user #{user.id}"

    # Calculate stats once
    stats = WeeklyProgressCalculator.new(user).calculate

    # Pass stats to service (prevents recalculation)
    feedback = AiServices::WeeklyWorkoutFeedbackService.new(user, stats: stats).generate

    # Save both feedback and stats
    WeeklyFeedback.create!(
      user: user,
      feedback_text: feedback,
      week_start: week_start,
      generated_at: Time.current,
      stats_snapshot: stats
    )

    Rails.logger.info "Successfully saved AI feedback for user #{user.id} (#{user.email})"
  rescue StandardError => e
    Rails.logger.error "Failed to save weekly feedback for user #{user_id}: #{e.message}"
    raise
  end
end
