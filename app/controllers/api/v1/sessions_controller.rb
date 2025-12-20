class Api::V1::SessionsController < Api::V1::BaseController
  skip_before_action :require_api_authentication, only: [ :create ]
  skip_before_action :verify_authenticity_token, only: [ :create ]

  def create
    user = User.find_by(email: params.dig(:user, :email)&.downcase)
    if user&.valid_password?(params.dig(:user, :password))
      # Check if account is locked
      if user.locked?
        return render json: {
          error: "Account is locked due to too many failed login attempts. Please try again later."
        }, status: :locked
      end

      # Reset failed login attempts on successful login
      user.reset_failed_login!
      user.update(last_login_at: Time.current)

      # Create session
      reset_session
      session[:user_id] = user.id
      set_fresh_csrf_cookie

      render json: { data: { user: serialize_user(user) } }, status: :ok
    else
      # Increment failed login attempts
      user&.increment_failed_login!

      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def destroy
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

  def verify_signed_out_user
    return unless signed_in?(resource_name)
    render json: { error: "User is already signed out" }, status: :unauthorized
  end

  def verify_signed_out_user
    return unless signed_in?(resource_name)
    render json: { error: "User is already signed out" }, status: :unauthorized
  end
end
