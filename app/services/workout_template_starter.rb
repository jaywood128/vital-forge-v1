# frozen_string_literal: true

# Service object to create a workout from a template
# Converts a workout template into an active workout with exercises and empty sets
class WorkoutTemplateStarter
  def initialize(user:, workout_template:, day_number: 1, scheduled_time: nil)
    @user = user
    @template = workout_template
    @day_number = day_number
    @scheduled_time = scheduled_time
  end

  def call
    ActiveRecord::Base.transaction do
      workout = create_workout
      create_exercises_and_sets(workout)
      workout
    end
  end

  private

  def create_workout
    @user.workouts.create!(
      name: @template.name,
      description: @template.description,
      workout_date: Date.current,
      scheduled_time: parse_scheduled_time,
      workout_type: map_goal_to_workout_type(@template.goal_type),
      workout_template_id: @template.id,
      completed: false,
      started_at: Time.current
    )
  end

  def create_exercises_and_sets(workout)
    day = @template.workout_template_days.find_by!(day_number: @day_number)
    day.workout_template_exercises.each do |template_exercise|
      workout_exercise = workout.workout_exercises.create!(
        exercise_id: template_exercise.exercise_id,
        order_position: template_exercise.order_position,
        notes: template_exercise.notes,
        rest_between_sets: template_exercise.rest_seconds,
        completed: false
      )

      # Create empty sets based on template recommendations
      template_exercise.recommended_sets.times do |i|
        workout_exercise.exercise_sets.create!(
          set_number: i + 1,
          reps: parse_reps(template_exercise.recommended_reps),
          weight: nil, # User fills this in during workout
          completed: false
        )
      end
    end
  end

  def parse_reps(reps_string)
    # Handle "8-12", "5", "AMRAP" formats
    return 10 if reps_string == "AMRAP"
    reps_string.to_s.split("-").first.to_i
  end

  def parse_scheduled_time
    return nil if @scheduled_time.blank?

    # Handle "HH:MM" format from frontend
    # Rails will automatically convert to time type
    @scheduled_time
  end

  def map_goal_to_workout_type(goal_type)
    # Map template goal types to valid workout types
    case goal_type
    when "physique"
      "Strength"  # Physique building uses strength training
    when "strength"
      "Strength"
    else
      "Other"
    end
  end
end
