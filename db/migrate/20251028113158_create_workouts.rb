class CreateWorkouts < ActiveRecord::Migration[8.0]
  # Creates workouts table to track user fitness activities
  # Each workout belongs to a user and records exercise session details
  def change
    create_table :workouts do |t|
      # Foreign key relationship
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      
      # Core workout data
      t.string :name, null: false
      t.text :description
      t.datetime :workout_date, null: false
      t.integer :duration_minutes  # Total workout duration
      t.string :workout_type        # e.g., "Strength", "Cardio", "HIIT", "Yoga", "Hypertropy", "Core", "Endurance", "Flexibility", "Balance", "Stability", "Mobility", "Recovery"
      t.integer :calories_burned
      t.text :notes                 # User notes about the session
      
      # Workout intensity and completion
      t.integer :intensity_level    # 1-10 scale
      t.boolean :completed, default: false, null: false
      
      t.timestamps
    end
    
    # Index for querying user's workouts by date (most common query pattern)
    add_index :workouts, [:user_id, :workout_date], name: 'index_workouts_on_user_and_date'
    
    # Index for filtering by workout type
    add_index :workouts, :workout_type
    
    # Index for completed workouts queries
    add_index :workouts, :completed
  end
end
