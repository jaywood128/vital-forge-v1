class CreateWorkoutExercises < ActiveRecord::Migration[8.0]
  # Junction table linking workouts to exercises
  # Represents "Exercise X was performed in Workout Y"
  def change
    create_table :workout_exercises do |t|
      # Foreign keys (these ALREADY create indexes automatically!)
      t.references :workout, null: false, foreign_key: { on_delete: :cascade }
      t.references :exercise, null: false, foreign_key: true
      
      # Exercise details for this specific workout
      t.integer :order_position, null: false, default: 0  # Order in workout (1st, 2nd, 3rd exercise)
      t.text :notes                                       # User notes for this exercise instance
      t.integer :rest_between_sets                        # Default rest time in seconds
      t.boolean :completed, default: false, null: false
      
      t.timestamps
    end
    
    # Composite index - most common query: "get exercises for this workout"
    add_index :workout_exercises, [:workout_id, :order_position], 
              name: 'index_workout_exercises_on_workout_and_order'

  end
end
