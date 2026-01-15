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
    return @current_user if defined?(@current_user)

    begin
      user_id = session.to_h.with_indifferent_access[:user_id]
      @current_user = User.find_by(id: user_id) if user_id
    rescue ArgumentError => e
      # Rack 3.2.3 bug: cookie parsing can fail with ArgumentError
      # This happens in test environment with certain cookie formats
      Rails.logger.debug "Session access failed: #{e.message}" unless Rails.env.test?
      @current_user = nil
    end

    @current_user
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
      # Secure cookies in production and staging (both use HTTPS)
      secure: !Rails.env.development?,
      # Allow CSRF tokens between subdomains since we own the domain.
      same_site: :lax
    }
  end
end
