class AddWorkoutTemplateTracking < ActiveRecord::Migration[8.0]
  def change
    # Link workouts to their template source (nullable for custom workouts)
    add_reference :workouts, :workout_template, foreign_key: true, null: true

    # Track actual start/end times (not just workout_date)
    add_column :workouts, :started_at, :datetime
    add_column :workouts, :completed_at, :datetime

    # Change exercise_sets.completed default to false (for new workouts from templates)
    change_column_default :exercise_sets, :completed, from: true, to: false

    # Add index for querying active workouts
    add_index :workouts, [ :user_id, :started_at, :completed_at ],
              name: 'index_workouts_on_user_active'
  end
end
