# frozen_string_literal: true

require Rails.root.join("lib/epley1_rm")

module Api
  module V1
    class ExerciseSetsController < Api::V1::BaseController
      include DualAuthenticatable
      include ::Epley1Rm

      skip_before_action :require_api_authentication
      skip_before_action :verify_authenticity_token, if: -> { request.headers["Authorization"].present? }

      # PATCH /api/v1/exercise_sets/:id
      def update
        exercise_set = find_exercise_set
        return unless exercise_set.is_a?(ExerciseSet)

        if exercise_set.update(exercise_set_params)
          render json: {
            exercise_set: serialize_exercise_set(exercise_set),
            personal_record: pr_info(exercise_set)
          }, status: :ok
        else
          render json: { errors: exercise_set.errors }, status: :unprocessable_entity
        end
      end

      private

      def pr_info(set)
        unless set.completed? &&
               set.weight.present? && set.weight > 0 &&
               set.reps.present? && set.reps > 0
          return { is_new_pr: false, new_estimated_1rm: nil, previous_estimated_1rm: nil }
        end

        new_1rm = epley_1rm(set.weight, set.reps)
        current_best = PersonalRecord.current_best_for(
          user_id: current_user.id,
          exercise_id: set.workout_exercise.exercise_id
        )
        is_new = current_best.nil? || new_1rm > current_best.estimated_1rm
        {
          is_new_pr: is_new,
          new_estimated_1rm: is_new ? new_1rm.round(2) : nil,
          previous_estimated_1rm: current_best&.estimated_1rm
        }
      end

      def find_exercise_set
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
          weight: exercise_set.weight&.to_f,
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
