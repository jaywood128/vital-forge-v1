class CreateWeeklyFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :weekly_feedbacks do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.date :week_start, null: false
      t.text :feedback_text, null: false
      t.jsonb :stats_snapshot
      t.datetime :generated_at, null: false

      t.timestamps
    end

    # Add unique constraint - one feedback per user per week
    add_index :weekly_feedbacks, [ :user_id, :week_start ], unique: true

    # Add index for querying current week's feedback
    add_index :weekly_feedbacks, :week_start
  end
end
