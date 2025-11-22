class AddDeviseToUsers < ActiveRecord::Migration[8.0]
  # Add minimal Devise columns while keeping existing has_secure_password columns.
  def up
    change_table :users, bulk: true do |t|
      # Devise database_authenticatable
      add_column :users, :encrypted_password, :string, null: false, default: ""

      # Optional rememberable (handy, no mailers)
      add_column :users, :remember_created_at, :datetime
    end

    # Backfill encrypted_password from existing password_digest if present
    execute <<~SQL.squish
      UPDATE users
      SET encrypted_password = password_digest
      WHERE password_digest IS NOT NULL AND password_digest <> '';
    SQL
  end

  def down
    remove_column :users, :remember_created_at, :datetime if column_exists?(:users, :remember_created_at)
    remove_column :users, :encrypted_password, :string if column_exists?(:users, :encrypted_password)
  end
end


