class SendWeeklyProgressEmailJob
  include Sidekiq::Job
  queue_as :default

  # Retry with exponential backoff
  sidekiq_options retry: 3

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    week_start = Date.current.beginning_of_week

    # Find or create feedback record for idempotency tracking
    feedback = WeeklyFeedback.find_or_create_by!(
      user: user,
      week_start: week_start
    ) do |record|
      # If creating new record, initialize with defaults
      record.feedback_text = "Pending AI generation"
      record.generated_at = Time.current
      record.stats_snapshot = {}
      record.email_sent = false
    end

    # Skip if email already sent (idempotent check)
    if feedback.email_sent?
      Rails.logger.info "Email already sent for user #{user.id} week #{week_start}"
      return
    end

    # Calculate weekly stats
    stats = WeeklyProgressCalculator.new(user).calculate

    # Only send if user had at least one workout this week
    if stats[:total_workouts] > 0
      WorkoutMailer.weekly_progress(user, stats).deliver_now

      # Mark email as sent
      feedback.update!(email_sent: true)

      Rails.logger.info "Sent weekly progress email to user #{user.id} (#{user.email})"
    else
      Rails.logger.info "Skipped weekly progress email for user #{user.id} - no workouts this week"
    end
  rescue ActiveRecord::RecordNotUnique
    # Another job already created the feedback record - retry to check email_sent flag
    Rails.logger.info "Feedback record race condition for user #{user_id} - retrying"
    retry
  rescue StandardError => e
    Rails.logger.error "Failed to send weekly progress email to user #{user_id}: #{e.message}"
    raise # Re-raise to trigger retry
  end
end
