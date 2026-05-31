# frozen_string_literal: true

require Rails.root.join("lib/epley1_rm")

class Api::V1::WorkoutsController < ApplicationController
  include DualAuthenticatable
  include ::Epley1Rm

  respond_to :json
  skip_before_action :require_authentication
  skip_before_action :verify_authenticity_token, if: -> { request.headers["Authorization"].present? }

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  # GET /api/v1/workouts
  # Query params: start_date, end_date (for date range filtering)
  def index
    workouts = current_user.workouts
              .includes(workout_exercises: [ :exercise, :exercise_sets ])

    # Apply date range filter if provided
    if params[:start_date].present? && params[:end_date].present?
      workouts = workouts.where(workout_date: params[:start_date]..params[:end_date])
    elsif params[:start_date].present?
      workouts = workouts.where("workout_date >= ?", params[:start_date])
    elsif params[:end_date].present?
      workouts = workouts.where("workout_date <= ?", params[:end_date])
    end

    workouts = workouts.order(workout_date: :desc)

    render json: {
      data: workouts.map { |workout| serialize_workout_with_exercises(workout) }
    }, status: :ok
  end

  # GET /api/v1/workouts/:id
  def show
    workout = current_user.workouts
                         .includes(workout_exercises: [ :exercise, :exercise_sets ])
                         .find(params[:id])

    render json: {
      data: serialize_workout_with_exercises(workout)
    }, status: :ok
  end

  # POST /api/v1/workout_templates/:id/start
  # Body params: scheduled_time (optional, format: "HH:MM")
  def start_from_template
    template = WorkoutTemplate.find(params[:id])

    # Check for duplicate active workout from same template
    existing = current_user.workouts
      .where(workout_template_id: template.id, completed: false)
      .first

    if existing
      return render json: {
        error: "You already have an active workout from this template. Complete it first or view your in-progress workouts.",
        active_workout_id: existing.id
      }, status: :conflict
    end

    workout = WorkoutTemplateStarter.new(
      user: current_user,
      workout_template: template,
      day_number: params[:day_number]&.to_i || 1,
      scheduled_time: params[:scheduled_time]
    ).call

    render json: {
      workout: serialize_workout_with_exercises(workout)
    }, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Template not found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # PATCH /api/v1/workouts/:id/start
  def start
    workout = current_user.workouts.find(params[:id])
    workout.start!
    render json: { workout: serialize_workout(workout) }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Workout not found" }, status: :not_found
  rescue Workout::InvalidTransition => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.to_hash(true) }, status: :unprocessable_entity
  end

  # PATCH /api/v1/workouts/:id/complete
  def complete
    workout = current_user.workouts.find(params[:id])
    new_prs = nil
    # Wrap completion + PR creation in a transaction so a PR validation failure
    # rolls back the workout completion rather than leaving it completed with no PRs.
    ActiveRecord::Base.transaction do
      workout.complete! unless workout.completed?
      new_prs = persist_prs(workout)
    end
    render json: {
      workout: serialize_workout(workout),
      new_personal_records: new_prs
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Workout not found" }, status: :not_found
  rescue Workout::InvalidTransition => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.to_hash(true) }, status: :unprocessable_entity
  end

  private

  def render_not_found
    render json: { error: "Workout not found" }, status: :not_found
  end

  def persist_prs(workout)
    exercise_ids = workout.workout_exercises.map(&:exercise_id)
    current_bests = PersonalRecord
      .where(user_id: workout.user_id, exercise_id: exercise_ids)
      .group_by(&:exercise_id)
      .transform_values { |prs| prs.max_by(&:estimated_1rm) }

    new_prs = []

    workout.workout_exercises
           .includes(:exercise, :exercise_sets)
           .each do |we|
      best_set = we.exercise_sets
                   .select { |s| s.completed? && s.weight.present? && s.weight > 0 && s.reps.present? && s.reps > 0 }
                   .max_by { |s| epley_1rm(s.weight, s.reps) }
      next unless best_set

      new_1rm = epley_1rm(best_set.weight, best_set.reps)
      current_best = current_bests[we.exercise_id]
      next if current_best && new_1rm <= current_best.estimated_1rm

      PersonalRecord.create!(
        user_id:         workout.user_id,
        exercise_id:     we.exercise_id,
        exercise_set_id: best_set.id,
        estimated_1rm:   new_1rm.round(2),
        weight:          best_set.weight,
        reps:            best_set.reps,
        recorded_at:     workout.completed_at || Time.current
      )

      new_prs << {
        exercise_name: we.exercise.name,
        weight:        best_set.weight.to_f,
        reps:          best_set.reps,
        estimated_1rm: new_1rm.round(2),
        previous_best: current_best&.estimated_1rm&.to_f
      }
    end

    new_prs
  end

  def serialize_workout(workout)
    {
      id: workout.id,
      name: workout.name,
      description: workout.description,
      workout_date: workout.workout_date,
      scheduled_time: workout.scheduled_time&.strftime("%H:%M"),  # Format as "HH:MM"
      workout_template_id: workout.workout_template_id,
      started_at: workout.started_at,
      completed_at: workout.completed_at,
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

  def serialize_workout_with_exercises(workout)
    workout_data = serialize_workout(workout)
    workout_data[:workout_exercises] = workout.workout_exercises.map do |we|
      {
        id: we.id,
        order_position: we.order_position,
        notes: we.notes,
        rest_between_sets: we.rest_between_sets,
        completed: we.completed,
        exercise: {
          id: we.exercise.id,
          name: we.exercise.name,
          muscle_group: we.exercise.muscle_group,
          equipment: we.exercise.equipment,
          exercise_type: we.exercise.exercise_type
        },
        exercise_sets: we.exercise_sets.map do |es|
          {
            id: es.id,
            set_number: es.set_number,
            reps: es.reps,
            weight: es.weight,
            weight_unit: es.weight_unit,
            rpe: es.rpe,
            to_failure: es.to_failure,
            notes: es.notes,
            completed: es.completed
          }
        end
      }
    end
    workout_data
  end
end
