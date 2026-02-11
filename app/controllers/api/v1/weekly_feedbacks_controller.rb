class Api::V1::WeeklyFeedbacksController < Api::V1::BaseController
  include DualAuthenticatable

  skip_before_action :require_api_authentication
  skip_before_action :verify_authenticity_token, if: -> { request.headers["Authorization"].present? }

  # GET /api/v1/weekly_feedbacks/current
  def current
    feedback = current_user.weekly_feedbacks
      .where("week_start >= ?", Date.current.beginning_of_week)
      .first

    if feedback
      render json: {
        data: {
          feedback: feedback.feedback_text,
          week_start: feedback.week_start,
          generated_at: feedback.generated_at,
          stats: feedback.stats_snapshot
        }
      }, status: :ok
    elsif ENV.fetch("ENABLE_AI_FEATURES", "false") == "true"
      # AI enabled - queue generation for this user
      GenerateWeeklyFeedbackJob.perform_async(current_user.id)

      render json: {
        status: "generating",
        message: "Your weekly feedback is being generated. Please check back in a moment."
      }, status: :accepted
    else
      # AI disabled - return a friendly static message
      render json: {
        data: {
          feedback: "Welcome to VitalForge! AI-powered weekly feedback is coming soon. Keep logging your workouts and check back later for personalized insights!",
          week_start: Date.current.beginning_of_week,
          generated_at: Time.current,
          stats: nil
        }
      }, status: :ok
    end
  rescue StandardError => e
    Rails.logger.error "Failed to retrieve weekly feedback for user #{current_user.id}: #{e.message}"
    render json: {
      error: "Unable to retrieve weekly feedback. Please try again later."
    }, status: :internal_server_error
  end
end
