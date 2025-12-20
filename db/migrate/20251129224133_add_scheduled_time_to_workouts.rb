class AddScheduledTimeToWorkouts < ActiveRecord::Migration[8.0]
  # Add scheduled_time to track when a workout is planned for a specific time of day
  # This is optional - users can schedule workouts or just have a date
  # Format: HH:MM:SS (e.g., "06:00:00" for 6:00 AM)
  # Used for calendar display and ICS file generation
  def change
    add_column :workouts, :scheduled_time, :time, comment: "Optional time of day when workout is scheduled"
  end
end
