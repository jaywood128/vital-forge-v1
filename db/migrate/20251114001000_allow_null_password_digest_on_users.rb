class AllowNullPasswordDigestOnUsers < ActiveRecord::Migration[8.0]
  def up
    change_column_null :users, :password_digest, true
  end

  def down
    change_column_null :users, :password_digest, false
  end
end
