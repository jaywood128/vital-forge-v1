# frozen_string_literal: true

# Mobile current user controller
# Returns authenticated user information for mobile apps
class Api::V1::Mobile::CurrentUsersController < Api::V1::Mobile::BaseController
  # GET /api/v1/mobile/current_user
  # Returns current authenticated user from JWT token
  def show
    render json: {
      data: {
        user: {
          id: current_user.id,
          email: current_user.email,
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          full_name: current_user.full_name,
          created_at: current_user.created_at,
          last_login_at: current_user.last_login_at
        }
      }
    }, status: :ok
  end
end
