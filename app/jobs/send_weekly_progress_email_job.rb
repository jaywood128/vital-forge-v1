class SendWeeklyProgressEmailJob
  include Sidekiq::Job
  queue_as :default

  # Retry with exponential backoff
  sidekiq_options retry: 3

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    # Calculate weekly stats
    stats = WeeklyProgressCalculator.new(user).calculate

    # Only send if user had at least one workout this week
    if stats[:total_workouts] > 0
      WorkoutMailer.weekly_progress(user, stats).deliver_now
      Rails.logger.info "Sent weekly progress email to user #{user.id} (#{user.email})"
    else
      Rails.logger.info "Skipped weekly progress email for user #{user.id} - no workouts this week"
    end
  rescue StandardError => e
    Rails.logger.error "Failed to send weekly progress email to user #{user_id}: #{e.message}"
    raise # Re-raise to trigger retry
  end
end
