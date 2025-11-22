class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Protect from CSRF attacks
  protect_from_forgery with: :exception
  after_action :set_csrf_cookie

  # Require authentication for all actions by default
  before_action :require_authentication

  # Make these methods available to views
  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_authentication
    unless logged_in?
      flash[:alert] = "You must be logged in to access this page"
      redirect_to login_path
    end
  end

  def set_csrf_cookie
    return unless protect_against_forgery?
    cookies["CSRF-TOKEN"] = {
      value: form_authenticity_token,
      secure: Rails.env.production?,
      same_site: :lax
    }
  end
end
