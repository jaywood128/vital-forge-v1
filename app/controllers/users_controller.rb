class UsersController < ApplicationController
  skip_before_action :require_authentication, only: [ :new, :create ]

  # GET /signup
  def new
    @user = User.new
  end

  # POST /users
  def create
    @user = User.new(user_params)

    if @user.save
      # Auto-login after registration
      reset_session
      session[:user_id] = @user.id
      redirect_to dashboard_path, notice: "Account created successfully! Welcome, #{@user.first_name}!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :phone_number)
  end
end
