# frozen_string_literal: true

# Concern for controllers that support both session (web) and JWT (mobile) authentication.
# - Hooks a before_action to authenticate via Authorization header first (JWT), then session[:user_id].
# - Sets @current_user and an auth_method flag (:jwt or :session) for downstream use.
# - Renders 401 JSON if neither credential succeeds.
# To allow anonymous access while still hydrating current_user when present, add
# `skip_before_action :authenticate_user_dual!` in the controller and implement
# a permissive helper that calls the lookup logic without rendering.
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
