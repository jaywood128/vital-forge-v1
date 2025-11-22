class CreateExerciseSets < ActiveRecord::Migration[8.0]
  # Individual sets within a workout exercise
  # This is where WEIGHT and REPS are tracked
  def change
    create_table :exercise_sets do |t|
      # Foreign key
      t.references :workout_exercise, null: false, foreign_key: { on_delete: :cascade }
      
      # Set performance data - THIS IS WHERE WEIGHT GOES!
      t.integer :set_number, null: false           # 1, 2, 3, etc.
      t.integer :reps, null: false                 # Number of repetitions
      t.decimal :weight, precision: 6, scale: 2    # Weight lifted (135.50 lbs)
      t.string :weight_unit, default: 'lbs'        # 'lbs' or 'kg'
      
      # Optional tracking
      t.integer :rest_after_seconds                # Actual rest taken after this set
      t.integer :rpe                               # Rate of Perceived Exertion (1-10)
      t.boolean :to_failure, default: false        # Did this set go to failure?
      t.text :notes                                # Set-specific notes
      t.boolean :completed, default: true          # Did user complete this set?
      
      t.timestamps
    end
    
    # Composite index - query: "get all sets for this exercise"
    add_index :exercise_sets, [:workout_exercise_id, :set_number], 
              name: 'index_exercise_sets_on_workout_exercise_and_number'
    
    # Unique constraint - can't have duplicate set numbers for same exercise
    add_index :exercise_sets, [:workout_exercise_id, :set_number], 
              unique: true, 
              name: 'unique_set_number_per_exercise'
  end
end
