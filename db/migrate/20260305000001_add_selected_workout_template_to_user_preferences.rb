class AddSelectedWorkoutTemplateToUserPreferences < ActiveRecord::Migration[8.0]
  def change
    add_reference :user_preferences, :selected_workout_template,
                  foreign_key: { to_table: :workout_templates },
                  null: true,
                  index: true
  end
end
