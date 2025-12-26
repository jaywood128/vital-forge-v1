# frozen_string_literal: true

# Mobile authentication controller
# Handles login/logout for mobile apps using JWT tokens
class Api::V1::Mobile::SessionsController < Api::V1::Mobile::BaseController
  skip_before_action :authenticate_mobile_user!, only: [ :create ]

  # POST /api/v1/mobile/login
  # Returns JWT token for mobile authentication
  def create
    user = User.find_by(email: params[:user][:email])

    unless user&.valid_password?(params[:user][:password])
      return render json: { error: "Invalid email or password" }, status: :unauthorized
    end

    if user.locked?
      return render json: { error: "Account is locked due to too many failed login attempts" }, status: :locked
    end

    # Reset failed login attempts on successful login
    user.reset_failed_login!
    user.update_column(:last_login_at, Time.current)

    token = ::AuthToken.for_user(user)

    render json: {
      data: {
        user: serialize_user(user),
        token: token,
        expires_at: ::AuthToken.expires_at(token).iso8601
      }
    }, status: :ok
  end

  # DELETE /api/v1/mobile/logout
  # Logs out mobile user (client should discard token)
  def destroy
    # For stateless JWT, client simply discards the token
    # If you implement a token denylist, add the token here
    head :no_content
  end

  private

  def serialize_user(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      full_name: user.full_name
    }
  end
end
