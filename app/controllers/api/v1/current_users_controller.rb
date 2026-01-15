class Api::V1::CurrentUsersController < Api::V1::BaseController
  skip_before_action :require_api_authentication, only: :show

  def show
    if current_user
      render json: { data: { user: serialize_user(current_user) } }, status: :ok
    else
      render json: { error: "Not signed in" }, status: :unauthorized
    end
  end

  private

  def serialize_user(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name
    }
  end
end
