class DashboardController < ApplicationController
  # Inherits require_authentication from ApplicationController

  def index
    # This will be where we mount React components later
    @user = current_user
  end
end

