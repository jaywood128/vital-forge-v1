class Api::V1::WeeklyFeedbacksController < Api::V1::BaseController
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
    else
      # No cached feedback found - queue generation for this user
      GenerateWeeklyFeedbackJob.perform_async(current_user.id)

      render json: {
        status: "generating",
        message: "Your weekly feedback is being generated. Please check back in a moment."
      }, status: :accepted
    end
  rescue StandardError => e
    Rails.logger.error "Failed to retrieve weekly feedback for user #{current_user.id}: #{e.message}"
    render json: {
      error: "Unable to retrieve weekly feedback. Please try again later."
    }, status: :internal_server_error
  end
end
