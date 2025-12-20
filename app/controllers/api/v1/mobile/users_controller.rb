# frozen_string_literal: true

module Api
  module V1
    module Mobile
      class UsersController < Api::V1::Mobile::BaseController
        skip_before_action :authenticate_mobile_user!, only: [:create]

        # POST /api/v1/mobile/signup
        def create
          @user = User.new(user_params)

          if @user.save
            # Generate JWT token for mobile
            token = ::AuthToken.for_user(@user)
            expires_at = ::AuthToken.expires_at(token)

            render json: {
              data: {
                user: serialize_user(@user),
                token: token,
                expires_at: expires_at,
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
end

