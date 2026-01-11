class CreateWorkoutTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_templates do |t|
      t.string :name, null: false
      t.text :description
      t.string :goal_type, null: false
      t.string :difficulty_level
      t.integer :days_per_week, null: false
      t.integer :estimated_duration_minutes
      t.integer :total_exercises
      t.string :source
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    # Add indexes for common queries
    add_index :workout_templates, :goal_type
    add_index :workout_templates, :difficulty_level
    add_index :workout_templates, :days_per_week
    add_index :workout_templates, :is_active
  end
end
