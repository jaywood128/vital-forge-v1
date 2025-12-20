# frozen_string_literal: true

module Api
  module V1
    class UsersController < Api::V1::BaseController
      skip_before_action :require_api_authentication, only: [:create]

      # POST /api/v1/signup
      def create
        @user = User.new(user_params)

        if @user.save
          # Auto-login after registration
          reset_session
          session[:user_id] = @user.id

          render json: {
            data: {
              user: serialize_user(@user),
              message: "Account created successfully! Welcome, #{@user.first_name}!"
            }
          }, status: :created
        else
          render json: {
            errors: @user.errors.to_hash(true)
          }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
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
  end
end

