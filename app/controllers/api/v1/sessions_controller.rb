class Api::V1::SessionsController < Devise::SessionsController
  respond_to :json
  skip_before_action :require_authentication
  protect_from_forgery with: :exception

  def create

    #binding.irb
    # Ensure params are in Devise's expected structure for Warden
    unless params[:user].is_a?(ActionController::Parameters)
      params[:user] = ActionController::Parameters.new(email: params[:email], password: params[:password])
    end

    user = warden.authenticate(scope: :user)
    return render json: { error: "Invalid email or password" }, status: :unauthorized unless user

    reset_session
    sign_in(:user, user)
    session[:user_id] = user.id
    set_fresh_csrf_cookie
    render json: { data: { user: serialize_user(user) } }, status: :ok
  end

  def destroy
    sign_out(resource_name) if signed_in?(resource_name)
    session.delete(:user_id)
    @current_user = nil
    reset_session
    set_fresh_csrf_cookie
    head :no_content
  end

  private

  def set_fresh_csrf_cookie
    cookies["CSRF-TOKEN"] = {
      value: form_authenticity_token,
      secure: Rails.env.production?,
      # We use :none in production to allow the cookie to be sent in cross-site requests
      # (e.g. from Next.js frontend to Rails API).
      # In development, :lax is sufficient and safer for localhost.
      same_site: Rails.env.production? ? :none : :lax
    }
  end

  def serialize_user(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name
    }
  end
end


