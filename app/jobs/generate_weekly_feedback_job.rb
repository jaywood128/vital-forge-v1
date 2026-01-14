class GenerateWeeklyFeedbackJob
  include Sidekiq::Job
  sidekiq_options queue: :ai, retry: 3

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    week_start = Date.current.beginning_of_week

    Rails.logger.info "Generating AI feedback for user #{user.id}"

    # Calculate stats once
    stats = WeeklyProgressCalculator.new(user).calculate

    # Pass stats to service (prevents recalculation)
    feedback = AiServices::WeeklyWorkoutFeedbackService.new(user, stats: stats).generate

    # Atomic find_or_create prevents race conditions
    WeeklyFeedback.find_or_create_by!(
      user: user,
      week_start: week_start
    ) do |record|
      record.feedback_text = feedback
      record.generated_at = Time.current
      record.stats_snapshot = stats
      record.email_sent = false
    end

    Rails.logger.info "Successfully saved AI feedback for user #{user.id} (#{user.email})"
  rescue ActiveRecord::RecordNotUnique
    # Another job already created it - that's fine!
    Rails.logger.info "Feedback already exists for user #{user.id} week #{week_start} (race condition handled)"
  rescue StandardError => e
    Rails.logger.error "Failed to save weekly feedback for user #{user_id}: #{e.message}"
    raise
  end
end
