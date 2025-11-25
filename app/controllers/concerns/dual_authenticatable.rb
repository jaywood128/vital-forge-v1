# frozen_string_literal: true

# Concern for controllers that need to support both session and JWT authentication
# Used by shared resource endpoints (workouts, exercises, etc.)
module DualAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user_dual!
  end

  private

  # Authenticates user from either JWT token (mobile) or session (web)
  def authenticate_user_dual!
    @current_user = nil
    @auth_method = nil

    # Try JWT authentication first (mobile)
    if request.headers["Authorization"].present?
      token = request.headers["Authorization"]&.split(" ")&.last
      if token.present?
        @current_user = ::AuthToken.verify(token)
        @auth_method = :jwt if @current_user
      end
    end

    # Fall back to session authentication (web) if JWT didn't work
    if @current_user.nil? && session[:user_id].present?
      @current_user = User.find_by(id: session[:user_id])
      @auth_method = :session if @current_user
    end

    # Render error if no authentication succeeded
    unless @current_user
      render json: { error: "Authentication required" }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def auth_method
    @auth_method
  end

  def authenticated_via_jwt?
    @auth_method == :jwt
  end

  def authenticated_via_session?
    @auth_method == :session
  end
end

