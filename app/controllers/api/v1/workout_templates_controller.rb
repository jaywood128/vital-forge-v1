# frozen_string_literal: true

module Api
  module V1
    class WorkoutTemplatesController < Api::V1::BaseController
      include DualAuthenticatable

      # Keep index/show public but hydrate current_user if present
      skip_before_action :require_api_authentication, only: [ :index, :show ]
      skip_before_action :authenticate_user_dual!, only: [ :index, :show ]
      before_action :set_current_user_if_present, only: [ :index, :show ]
      before_action :set_workout_template, only: [ :show ]

      # GET /api/v1/workout_templates
      def index
        @templates = WorkoutTemplate.active.includes(:exercises)

        # Map of template_id => active workout_id for the current user
        active_workouts_by_template = if current_user
          current_user.workouts
            .where(completed: false)
            .where.not(workout_template_id: nil)
            .pluck(:workout_template_id, :id)
            .to_h
        else
          {}
        end

        render json: {
          data: @templates.map { |template|
            serialize_template(template, active_workouts_by_template)
          }
        }, status: :ok
      end

      # GET /api/v1/workout_templates/:id
      def show
        # If user is authenticated, find their active workout for this template
        active_workout = if current_user
          current_user.workouts
            .where(workout_template_id: @workout_template.id, completed: false)
            .first
        end

        render json: {
          data: serialize_template_with_exercises(
            @workout_template,
            has_active: active_workout.present?,
            active_workout_id: active_workout&.id
          )
        }, status: :ok
      end

      private

      def set_workout_template
        @workout_template = WorkoutTemplate.active
          .includes(workout_template_exercises: :exercise)
          .find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Workout template not found" }, status: :not_found
      end

      # Soft-auth: populate @current_user/@auth_method without rejecting anonymous users.
      # This mirrors DualAuthenticatable but does not render 401 when no auth is present.
      def set_current_user_if_present
        @current_user = nil
        @auth_method = nil

        # Try JWT first
        if request.headers["Authorization"].present?
          token = request.headers["Authorization"]&.split(" ")&.last
          if token.present?
            @current_user = ::AuthToken.verify(token)
            @auth_method = :jwt if @current_user
          end
        end
        # Fall back to session
        if @current_user.nil? && session[:user_id].present?
          @current_user = User.find_by(id: session[:user_id])
          @auth_method = :session if @current_user
        end
      end

      # Include the active workout id (if any) so the UI can resume a started workout.
      def serialize_template(template, active_workouts_by_template = {})
        {
          id: template.id,
          name: template.name,
          description: template.description,
          goal_type: template.goal_type,
          difficulty_level: template.difficulty_level,
          days_per_week: template.days_per_week,
          estimated_duration_minutes: template.estimated_duration_minutes,
          total_exercises: template.total_exercises,
          source: template.source,
          has_active_workout: active_workouts_by_template.key?(template.id),
          active_workout_id: active_workouts_by_template[template.id],
          created_at: template.created_at,
          updated_at: template.updated_at
        }
      end

      def serialize_template_with_exercises(template, has_active: false, active_workout_id: nil)
        {
          id: template.id,
          name: template.name,
          description: template.description,
          goal_type: template.goal_type,
          difficulty_level: template.difficulty_level,
          days_per_week: template.days_per_week,
          estimated_duration_minutes: template.estimated_duration_minutes,
          total_exercises: template.total_exercises,
          source: template.source,
          has_active_workout: has_active,
          active_workout_id: active_workout_id,
          exercises: template.workout_template_exercises.map do |wte|
            {
              id: wte.id,
              exercise_id: wte.exercise_id,
              order_position: wte.order_position,
              recommended_sets: wte.recommended_sets,
              recommended_reps: wte.recommended_reps,
              rest_seconds: wte.rest_seconds,
              notes: wte.notes,
              exercise: {
                id: wte.exercise.id,
                name: wte.exercise.name,
                description: wte.exercise.description,
                exercise_type: wte.exercise.exercise_type,
                equipment: wte.exercise.equipment,
                muscle_group: wte.exercise.muscle_group,
                difficulty_level: wte.exercise.difficulty_level,
                instructions: wte.exercise.instructions
              }
            }
          end,
          created_at: template.created_at,
          updated_at: template.updated_at
        }
      end
    end
  end
end
