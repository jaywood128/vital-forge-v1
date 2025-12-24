class CreateWorkoutTemplateExercises < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_template_exercises do |t|
      t.references :workout_template, null: false, foreign_key: { on_delete: :cascade }
      t.references :exercise, null: false, foreign_key: true
      t.integer :order_position, null: false, default: 0
      t.integer :recommended_sets, null: false
      t.string :recommended_reps, null: false
      t.integer :rest_seconds
      t.text :notes

      t.timestamps
    end

    # Add indexes for common queries
    add_index :workout_template_exercises, [ :workout_template_id, :order_position ],
              name: 'index_template_exercises_on_template_and_order'
  end
end
