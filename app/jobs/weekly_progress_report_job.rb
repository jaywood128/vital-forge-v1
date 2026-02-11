class WeeklyProgressReportJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 2

  def perform
    unless ENV.fetch("ENABLE_AI_FEATURES", "false") == "true"
      Rails.logger.info "Skipping weekly progress report - AI features disabled (set ENABLE_AI_FEATURES=true to enable)"
      return
    end

    Rails.logger.info "Starting weekly progress report generation for all users"

    queued_emails = 0
    queued_ai_feedback = 0
    active_users = 0

    # Define the week range (matching WeeklyProgressCalculator)
    start_date = 1.week.ago.beginning_of_day
    end_date = Time.current.end_of_day

    # Only process users who have workouts for the current week
    User.joins(:workouts)
        .where(workouts: { workout_date: start_date..end_date })
        .distinct
        .find_each do |user|
      active_users += 1
      # TEMPORARILY DISABLED - No mail server configured for Lightsail deployment
      # SendWeeklyProgressEmailJob.perform_async(user.id)
      # queued_emails += 1
      GenerateWeeklyFeedbackJob.perform_async(user.id)
      queued_ai_feedback += 1
    end

    # Calculate how many users were skipped
    total_user_count = User.count
    skipped_users = total_user_count - active_users

    # Comprehensive summary log
    Rails.logger.info "Weekly progress report complete: " \
                      "#{queued_emails} email jobs + #{queued_ai_feedback} AI feedback jobs queued " \
                      "for #{active_users} active users (#{skipped_users} users skipped - no workouts this week)"
  rescue StandardError => e
    Rails.logger.error "Failed to generate weekly progress reports: #{e.message}"
    raise
  end
end
