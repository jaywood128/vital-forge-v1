class AddDayToWorkoutTemplateExercises < ActiveRecord::Migration[8.0]
  def up
    # Step 1: Add the column as nullable so existing rows are not immediately rejected
    add_reference :workout_template_exercises, :workout_template_day,
                  null: true,
                  foreign_key: true

    # Step 2: Data migration — for every existing template, create a Day 1 record
    # and assign all of that template's exercises to it.
    # We use SQL-level classes to avoid dependency on app models (which may change).
    execute <<~SQL
      INSERT INTO workout_template_days (workout_template_id, day_number, name, created_at, updated_at)
      SELECT DISTINCT workout_template_id, 1, 'Day 1', NOW(), NOW()
      FROM workout_template_exercises
      ON CONFLICT DO NOTHING
    SQL

    execute <<~SQL
      UPDATE workout_template_exercises wte
      SET workout_template_day_id = wtd.id
      FROM workout_template_days wtd
      WHERE wtd.workout_template_id = wte.workout_template_id
        AND wtd.day_number = 1
        AND wte.workout_template_day_id IS NULL
    SQL

    # Step 3: Now that every row has a value, enforce NOT NULL
    change_column_null :workout_template_exercises, :workout_template_day_id, false
  end

  def down
    remove_reference :workout_template_exercises, :workout_template_day, foreign_key: true
  end
end
