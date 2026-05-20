# frozen_string_literal: true

class Api::V1::Mobile::PasswordResetsController < Api::V1::Mobile::BaseController
  skip_before_action :authenticate_mobile_user!

  # POST /api/v1/mobile/forgot_password
  def create
    user = User.find_by(email: params[:email].to_s.downcase.strip)
    if user
      user.generate_password_reset_token!
      UserMailer.password_reset(user).deliver_now
    end
    render json: { message: "If that address is registered, a reset link is on its way." }, status: :ok
  end

  # POST /api/v1/mobile/reset_password
  def update
    user = User.find_by(password_reset_token: params[:token].to_s)

    if user.nil? || user.password_reset_expired?
      user&.update_columns(password_reset_token: nil, password_reset_sent_at: nil)
      return render json: { error: "Reset link is invalid or has expired." }, status: :unprocessable_entity
    end

    if user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      user.update_columns(password_reset_token: nil, password_reset_sent_at: nil)
      render json: { message: "Password updated successfully." }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
