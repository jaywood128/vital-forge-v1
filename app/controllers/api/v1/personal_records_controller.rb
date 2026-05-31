# frozen_string_literal: true

class Api::V1::PersonalRecordsController < ApplicationController
  include DualAuthenticatable

  respond_to :json
  skip_before_action :require_authentication
  skip_before_action :verify_authenticity_token, if: -> { request.headers["Authorization"].present? }

  # GET /api/v1/personal_records
  # Optional query param: exercise_id
  def index
    records = current_user.personal_records
    records = records.where(exercise_id: params[:exercise_id]) if params[:exercise_id].present?

    render json: records.map { |pr| serialize_pr(pr) }, status: :ok
  end

  private

  def serialize_pr(pr)
    {
      exercise_id:     pr.exercise_id,
      exercise_set_id: pr.exercise_set_id,
      estimated_1rm:   pr.estimated_1rm.to_f,
      weight:          pr.weight.to_f,
      reps:            pr.reps,
      recorded_at:     pr.recorded_at
    }
  end
end
