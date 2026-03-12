# frozen_string_literal: true

module Api
  module V1
    class UserPreferencesController < Api::V1::BaseController
      include DualAuthenticatable

      skip_before_action :require_api_authentication
      skip_before_action :verify_authenticity_token, if: -> { request.headers["Authorization"].present? }

      before_action :set_user_preference, only: [ :show, :update ]

      # GET /api/v1/user_preference
      def show
        if @user_preference
          render json: { data: serialize_preference(@user_preference) }, status: :ok
        else
          render json: { error: "User preferences not found" }, status: :not_found
        end
      end

      # POST /api/v1/user_preference — upserts so re-running onboarding doesn't fail
      def create
        @user_preference = current_user.user_preference || current_user.build_user_preference
        @user_preference.assign_attributes(user_preference_params)

        # Auto-complete onboarding if primary_goal and training_days are set
        if @user_preference.primary_goal.present? && @user_preference.training_days_per_week.present?
          @user_preference.onboarding_completed = true
          @user_preference.onboarding_completed_at = Time.current
        end

        previously_existed = @user_preference.persisted?

        if @user_preference.save
          status = previously_existed ? :ok : :created
          render json: { data: serialize_preference(@user_preference) }, status: status
        else
          render json: { errors: @user_preference.errors }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/user_preference
      def update
        if @user_preference.update(user_preference_params)
          render json: { data: serialize_preference(@user_preference) }, status: :ok
        else
          render json: { errors: @user_preference.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_user_preference
        @user_preference = current_user.user_preference
      end

      def user_preference_params
        params.require(:user_preference).permit(
          :primary_goal,
          :training_days_per_week,
          :preferred_workout_duration,
          :experience_level,
          :selected_workout_template_id
        )
      end

      def serialize_preference(preference)
        {
          id: preference.id,
          user_id: preference.user_id,
          primary_goal: preference.primary_goal,
          training_days_per_week: preference.training_days_per_week,
          preferred_workout_duration: preference.preferred_workout_duration,
          experience_level: preference.experience_level,
          onboarding_completed: preference.onboarding_completed,
          onboarding_completed_at: preference.onboarding_completed_at,
          selected_workout_template_id: preference.selected_workout_template_id,
          selected_workout_template_name: preference.selected_workout_template&.name,
          created_at: preference.created_at,
          updated_at: preference.updated_at
        }
      end
    end
  end
end
