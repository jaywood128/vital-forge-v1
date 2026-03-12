class CreateWorkoutTemplateDays < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_template_days do |t|
      t.references :workout_template, null: false, foreign_key: true
      t.integer :day_number, null: false
      t.string :name, null: false
      t.integer :estimated_duration_minutes
      t.string :muscle_focus

      t.timestamps
    end

    add_index :workout_template_days, [ :workout_template_id, :day_number ], unique: true, name: "index_workout_template_days_on_template_and_day"
  end
end
