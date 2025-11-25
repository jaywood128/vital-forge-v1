class Api::V1::CsrfController < ApplicationController
  respond_to :json
  skip_before_action :require_authentication

  def show
    token = form_authenticity_token
    cookies["CSRF-TOKEN"] = {
      value: token,
      secure: Rails.env.production?,
      same_site: Rails.env.production? ? :none : :lax
    }
    render json: { csrfToken: token }, status: :ok
  end
end
