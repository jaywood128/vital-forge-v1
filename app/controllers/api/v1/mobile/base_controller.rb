# frozen_string_literal: true

# Base controller for mobile API endpoints
# Uses JWT token authentication instead of sessions
class Api::V1::Mobile::BaseController < ApplicationController
  respond_to :json
  skip_before_action :verify_authenticity_token  # No CSRF for mobile
  skip_before_action :require_authentication     # Use mobile auth instead
  before_action :authenticate_mobile_user!

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable

  private

  def authenticate_mobile_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    return render json: { error: "Missing authentication token" }, status: :unauthorized unless token

    @current_user = ::AuthToken.verify(token)
    
    unless @current_user
      render json: { error: "Invalid or expired token" }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def render_not_found(e)
    render json: { error: e.message }, status: :not_found
  end

  def render_unprocessable(e)
    render json: { errors: e.record.errors.to_hash(true) }, status: :unprocessable_entity
  end
end

