class WeeklyProgressReportJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 2

  def perform
    Rails.logger.info "Starting weekly progress report generation for all users"

    total_users = 0
    queued_jobs = 0

    User.find_each do |user|
      total_users += 1
      # Queue individual email jobs to process in parallel
      SendWeeklyProgressEmailJob.perform_async(user.id)
      queued_jobs += 1
    end

    Rails.logger.info "Queued #{queued_jobs} weekly progress email jobs for #{total_users} users"
  rescue StandardError => e
    Rails.logger.error "Failed to generate weekly progress reports: #{e.message}"
    raise
  end
end
