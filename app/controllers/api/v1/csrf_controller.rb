class Api::V1::CsrfController < ApplicationController
  respond_to :json
  skip_before_action :require_authentication

  def show
    token = form_authenticity_token
    cookies["CSRF-TOKEN"] = {
      value: token,
      # Secure cookies in production and staging (both use HTTPS)
      secure: !Rails.env.development?,
      same_site: :lax
    }
    render json: { csrfToken: token }, status: :ok
  end
end
