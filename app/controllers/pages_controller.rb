class PagesController < ApplicationController
  skip_before_action :require_authentication, only: [ :home ]

  def home
    # Redirect to dashboard if already logged in
    redirect_to dashboard_path if logged_in?
  end
end
