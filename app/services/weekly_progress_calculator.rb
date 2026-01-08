class WeeklyProgressCalculator
  def initialize(user)
    @user = user
    @start_date = 1.week.ago.beginning_of_day
    @end_date = Time.current.end_of_day
  end

  def calculate
    workouts = @user.workouts
                    .where(workout_date: @start_date..@end_date)
                    .includes(workout_exercises: [:exercise, :exercise_sets])

    {
      total_workouts: workouts.count,
      total_sets: calculate_total_sets(workouts),
      total_volume: calculate_total_volume(workouts),
      total_duration: calculate_total_duration(workouts),
      streak: calculate_streak(workouts),
      most_common_exercise: find_most_common_exercise(workouts)
    }
  end

  private

  def calculate_total_sets(workouts)
    workouts.sum do |workout|
      workout.workout_exercises.sum { |we| we.exercise_sets.count }
    end
  end

  def calculate_total_volume(workouts)
    workouts.sum do |workout|
      workout.workout_exercises.sum do |we|
        we.exercise_sets.sum { |set| (set.weight || 0) * (set.reps || 0) }
      end
    end
  end

  def calculate_total_duration(workouts)
    workouts.sum { |w| w.duration_minutes || 0 }
  end

  def calculate_streak(workouts)
    return 0 if workouts.empty?

    workout_dates = workouts.map { |w| w.workout_date.to_date }.uniq.sort.reverse
    streak = 0
    current_date = Date.current

    workout_dates.each do |date|
      break if date < current_date - streak.days
      streak += 1 if date == current_date - streak.days
    end

    streak
  end

  def find_most_common_exercise(workouts)
    exercise_counts = Hash.new(0)

    workouts.each do |workout|
      workout.workout_exercises.each do |we|
        exercise_counts[we.exercise.name] += 1
      end
    end

    return nil if exercise_counts.empty?
    exercise_counts.max_by { |_name, count| count }&.first
  end
end

