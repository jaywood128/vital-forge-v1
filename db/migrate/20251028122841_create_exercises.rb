class CreateExercises < ActiveRecord::Migration[8.0]
  # Master catalog of all exercises (reusable across all users)
  # Examples: "Bench Press", "Squat", "Deadlift", "Pull-ups"
  def change
    create_table :exercises do |t|
      t.string :name, null: false
      t.text :description
      t.string :exercise_type, null: false  # Strength, Cardio, Mobility, etc.
      t.string :equipment, null: false      # Bodyweight, Dumbbells, Barbell, etc.
      t.string :muscle_group                # Chest, Legs, Back, Arms, Core, Full Body
      t.string :difficulty_level            # Beginner, Intermediate, Advanced
      t.text :instructions                  # How to perform the exercise
      #t.string :video_url                   # Link to demo video
      
      t.timestamps
    end
    
    # Index for filtering by type and equipment
    add_index :exercises, :exercise_type
    add_index :exercises, :equipment
    add_index :exercises, :muscle_group
    
    # Unique constraint - can't have duplicate exercise names
    add_index :exercises, :name, unique: true
  end
end
