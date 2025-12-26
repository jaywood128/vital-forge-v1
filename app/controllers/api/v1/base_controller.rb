class Api::V1::BaseController < ApplicationController
  respond_to :json
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? && request.get? }
  skip_before_action :require_authentication

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
  # Handle CSRF errors with JSON response instead of HTML
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_invalid_authenticity_token

  before_action :require_api_authentication

  private

  def require_api_authentication
    binnding.irb
    return if logged_in?

    render json: { error: "Authentication required" }, status: :unauthorized
  end

  def render_not_found(e)
    render json: { error: e.message }, status: :not_found
  end

  def render_unprocessable(e)
    render json: { errors: e.record.errors.to_hash(true) }, status: :unprocessable_entity
  end

  def render_invalid_authenticity_token
    render json: { error: "Invalid or missing CSRF token" }, status: :unprocessable_entity
  end
end
