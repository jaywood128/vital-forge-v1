# frozen_string_literal: true

# Workouts controller - supports both session (web) and JWT (mobile) authentication
class Api::V1::WorkoutsController < ApplicationController
  include DualAuthenticatable

  respond_to :json
  skip_before_action :require_authentication
  skip_before_action :verify_authenticity_token, if: -> { authenticated_via_jwt? }

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  # GET /api/v1/workouts
  def index
    workouts = current_user.workouts.order(workout_date: :desc)

    render json: {
      data: workouts.map { |workout| serialize_workout(workout) }
    }, status: :ok
  end

  # GET /api/v1/workouts/:id
  def show
    workout = current_user.workouts.find(params[:id])

    render json: {
      data: serialize_workout(workout)
    }, status: :ok
  end

  private

  def render_not_found
    render json: { error: "Workout not found" }, status: :not_found
  end

  def serialize_workout(workout)
    {
      id: workout.id,
      name: workout.name,
      description: workout.description,
      workout_date: workout.workout_date,
      duration_minutes: workout.duration_minutes,
      workout_type: workout.workout_type,
      calories_burned: workout.calories_burned,
      notes: workout.notes,
      intensity_level: workout.intensity_level,
      completed: workout.completed,
      created_at: workout.created_at,
      updated_at: workout.updated_at
    }
  end
end
