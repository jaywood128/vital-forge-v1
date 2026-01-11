class GenerateWeeklyFeedbackJob
  include Sidekiq::Job
  sidekiq_options queue: :ai, retry: 3  # Separate queue for AI jobs

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    Rails.logger.info "Generating AI feedback for user #{user.id}"

    # Calculate stats once
    stats = WeeklyProgressCalculator.new(user).calculate

    # Pass stats to service (prevents recalculation)
    feedback = AiServices::WeeklyWorkoutFeedbackService.new(user, stats: stats).generate

    # Save both feedback and stats
    WeeklyFeedback.create!(
      user: user,
      feedback_text: feedback,
      week_start: Date.current.beginning_of_week,
      generated_at: Time.current,
      stats_snapshot: stats
    )

    Rails.logger.info "Successfully saved AI feedback for user #{user.id} (#{user.email})"
  rescue StandardError => e
    Rails.logger.error "Failed to save weekly feedback for user #{user.id}: #{e.message}"
    raise
  end
end
