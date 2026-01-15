class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: [ :new, :create, :destroy ]

  # GET /login
  def new
    # Redirect if already logged in
    redirect_to dashboard_path if logged_in?
  end

  # POST /login
  def create
    user = User.find_for_database_authentication(email: params[:email]&.downcase)

    # Check if account is locked
    if user&.locked?
      flash.now[:alert] = "Account is locked due to too many failed login attempts. Please try again later."
      render :new, status: :unprocessable_entity
      return
    end

    # Authenticate user
    if user&.valid_password?(params[:password].to_s)
      # Successful login
      reset_session  # Prevent session fixation attacks
      sign_in(:user, user)
      session[:user_id] = user.id  # maintain compatibility with existing helpers
      user.reset_failed_login!
      user.update_column(:last_login_at, Time.current)

      redirect_to dashboard_path, notice: "Welcome back, #{user.first_name}!"
    else
      # Failed login
      user&.increment_failed_login!
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /logout
  def destroy
    sign_out(:user)
    reset_session
    redirect_to root_path, notice: "Logged out successfully"
  end
end
