# frozen_string_literal: true

module Api
  module V1
    class ExerciseSetsController < Api::V1::BaseController
      include DualAuthenticatable

      skip_before_action :require_api_authentication

      # PATCH /api/v1/exercise_sets/:id
      def update
        exercise_set = find_exercise_set
        return unless exercise_set.is_a?(ExerciseSet)

        if exercise_set.update(exercise_set_params)
          render json: { exercise_set: serialize_exercise_set(exercise_set) }, status: :ok
        else
          render json: { errors: exercise_set.errors }, status: :unprocessable_entity
        end
      end

      private

      def find_exercise_set
        # Find exercise_set through user's workouts for security
        ExerciseSet
          .joins(workout_exercise: { workout: :user })
          .where(workouts: { user_id: current_user.id })
          .find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Exercise set not found" }, status: :not_found
        nil
      end

      def exercise_set_params
        params.require(:exercise_set).permit(
          :reps,
          :weight,
          :weight_unit,
          :rest_after_seconds,
          :rpe,
          :to_failure,
          :notes,
          :completed
        )
      end

      def serialize_exercise_set(exercise_set)
        {
          id: exercise_set.id,
          workout_exercise_id: exercise_set.workout_exercise_id,
          set_number: exercise_set.set_number,
          reps: exercise_set.reps,
          weight: exercise_set.weight,
          weight_unit: exercise_set.weight_unit,
          rest_after_seconds: exercise_set.rest_after_seconds,
          rpe: exercise_set.rpe,
          to_failure: exercise_set.to_failure,
          notes: exercise_set.notes,
          completed: exercise_set.completed,
          created_at: exercise_set.created_at,
          updated_at: exercise_set.updated_at
        }
      end
    end
  end
end
