class CreateUserPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :user_preferences do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.string :primary_goal
      t.integer :training_days_per_week
      t.integer :preferred_workout_duration
      t.string :experience_level
      t.boolean :onboarding_completed, default: false, null: false
      t.datetime :onboarding_completed_at

      t.timestamps
    end
  end
end
