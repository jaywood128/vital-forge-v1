class AddEmailSentToWeeklyFeedbacks < ActiveRecord::Migration[8.0]
  def change
    add_column :weekly_feedbacks, :email_sent, :boolean, default: false, null: false
    add_index :weekly_feedbacks, [:user_id, :week_start, :email_sent], name: 'index_weekly_feedbacks_on_user_week_email'
  end
end
