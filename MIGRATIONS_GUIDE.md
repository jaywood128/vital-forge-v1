# Rails Migrations Guide

## What Are Migrations?

Migrations are Ruby files that describe changes to your database schema. They're version-controlled and can be run forward (up) or backward (down).

## Essential Commands

### Check Migration Status
```bash
bin/rails db:migrate:status
```
Shows which migrations have been run (`up`) or pending (`down`)

### Run Migrations
```bash
# Run all pending migrations
bin/rails db:migrate

# Run migrations for a specific environment
bin/rails db:migrate RAILS_ENV=production
```

### Rollback Migrations
```bash
# Rollback last migration
bin/rails db:rollback

# Rollback last 3 migrations
bin/rails db:rollback STEP=3

# Rollback to specific version
bin/rails db:migrate:down VERSION=20251026180606
```

### Database Management
```bash
# Create database
bin/rails db:create

# Drop database (⚠️ DELETES EVERYTHING)
bin/rails db:drop

# Reset database (drop + create + migrate)
bin/rails db:reset

# Load seed data
bin/rails db:seed

# Complete setup (create + migrate + seed)
bin/rails db:setup
```

## Column Types

```ruby
# Strings
t.string :name              # VARCHAR(255)
t.string :code, limit: 10   # VARCHAR(10)
t.text :description         # TEXT (unlimited)

# Numbers
t.integer :count
t.bigint :large_number
t.float :temperature
t.decimal :price, precision: 10, scale: 2  # 12345678.90

# Boolean
t.boolean :active, default: false

# Date & Time
t.date :birth_date
t.datetime :published_at
t.time :opens_at
t.timestamps  # Creates created_at & updated_at

# References (Foreign Keys)
t.references :user, foreign_key: true
# Creates: user_id + foreign key constraint

# PostgreSQL Specific
t.jsonb :metadata
t.array :tags, array: true, default: []
t.uuid :guid, default: "gen_random_uuid()"
```

## Common Migration Patterns

### Creating a Table
```ruby
class CreateWorkouts < ActiveRecord::Migration[8.0]
  def change
    create_table :workouts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :notes
      t.datetime :performed_at, null: false
      t.timestamps
    end
    
    # Indexes for better query performance
    add_index :workouts, [:user_id, :performed_at]
    add_index :workouts, :name
  end
end
```

### Adding Columns
```ruby
class AddAgeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :age, :integer
    add_column :users, :city, :string, default: "Unknown"
  end
end
```

### Removing Columns
```ruby
class RemoveAgeFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :age, :integer
  end
end
```

### Renaming Columns
```ruby
class RenamePasswordToPasswordDigest < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :password, :password_digest
  end
end
```

### Changing Column Types
```ruby
class ChangeDescriptionType < ActiveRecord::Migration[8.0]
  def change
    change_column :workouts, :description, :text
  end
end
```

### Adding Indexes
```ruby
class AddIndexToUsersEmail < ActiveRecord::Migration[8.0]
  def change
    add_index :users, :email, unique: true
    add_index :workouts, [:user_id, :created_at]
  end
end
```

### Adding Foreign Keys
```ruby
class AddForeignKeyToWorkouts < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :workouts, :users
  end
end
```

### Complex Migration with Up/Down
```ruby
class ConvertPriceToDecimal < ActiveRecord::Migration[8.0]
  def up
    change_column :products, :price, :decimal, precision: 10, scale: 2
  end
  
  def down
    change_column :products, :price, :integer
  end
end
```

## Generating Migrations

```bash
# Empty migration
bin/rails generate migration AddAgeToUsers

# Add single column
bin/rails generate migration AddAgeToUsers age:integer

# Add multiple columns
bin/rails generate migration AddDetailsToUsers age:integer city:string active:boolean

# Add column with index
bin/rails generate migration AddEmailToUsers email:string:uniq

# Add foreign key
bin/rails generate migration AddUserToWorkouts user:references

# Remove column
bin/rails generate migration RemoveAgeFromUsers age:integer
```

## Best Practices

### 1. ✅ Always Add Database Constraints
```ruby
# Good - Database enforces rules
t.string :email, null: false
add_index :users, :email, unique: true

# Bad - Only model validation (can be bypassed)
t.string :email
```

### 2. ✅ Make Migrations Reversible
```ruby
# Good - Rails can reverse automatically
def change
  add_column :users, :age, :integer
end

# Bad - Not reversible (use up/down instead)
def change
  User.update_all(active: true)
end

# Good - Explicit up/down
def up
  User.update_all(active: true)
end

def down
  User.update_all(active: false)
end
```

### 3. ✅ Add Indexes for Performance
```ruby
# Always index foreign keys
t.references :user, foreign_key: true, index: true

# Index frequently queried columns
add_index :users, :email
add_index :workouts, [:user_id, :performed_at]
```

### 4. ✅ Use Appropriate Data Types
```ruby
# Good
t.decimal :price, precision: 10, scale: 2  # For money
t.boolean :active, default: false
t.datetime :published_at

# Bad
t.string :price        # Don't store money as string
t.integer :active      # Use boolean, not integer
t.string :published_at # Don't store dates as string
```

### 5. ❌ Never Edit Existing Migrations (After Production)
Once a migration runs in production, create a new migration to fix issues:

```bash
# Don't edit: db/migrate/20251026180606_create_users.rb
# Instead create new:
bin/rails generate migration AddIndexToUsersEmail
```

### 6. ✅ Use Transactions for Data Changes
```ruby
def up
  reversible do |dir|
    dir.up do
      User.transaction do
        User.where(role: nil).update_all(role: 'member')
      end
    end
    
    dir.down do
      # Reverse the change
    end
  end
end
```

## Common Errors and Solutions

### Error: "PG::NotNullViolation: ERROR: column cannot be null"
**Problem**: Trying to add NOT NULL column to table with existing records

**Solution**: 
```ruby
# Step 1: Add column without null constraint
def change
  add_column :users, :email, :string
  
  # Step 2: Set default values for existing records
  reversible do |dir|
    dir.up do
      User.update_all(email: 'unknown@example.com')
    end
  end
  
  # Step 3: Add null constraint
  change_column_null :users, :email, false
end
```

### Error: "PG::UndefinedTable: ERROR: relation does not exist"
**Problem**: Migration depends on a table that hasn't been created yet

**Solution**: Check migration timestamps - they run in order by timestamp

### Error: "ActiveRecord::IrreversibleMigration"
**Problem**: Migration can't be reversed automatically

**Solution**: Define explicit `up` and `down` methods

## Checking Your Database

### View Database Schema
```ruby
# See all columns in a model
User.column_names

# See column types
User.columns_hash["email"]

# Count records
User.count
```

### Rails Console Queries
```bash
bin/rails console

# View all users
User.all

# View table structure
ActiveRecord::Base.connection.columns(:users)

# Check indexes
ActiveRecord::Base.connection.indexes(:users)
```

## Migration Workflow Example

```bash
# 1. Generate migration
bin/rails generate migration CreateWorkouts user:references name:string performed_at:datetime

# 2. Edit migration file (add constraints, indexes)
# db/migrate/XXXXXX_create_workouts.rb

# 3. Check what will change
bin/rails db:migrate:status

# 4. Run migration
bin/rails db:migrate

# 5. Verify in console
bin/rails console
Workout.column_names

# 6. If something's wrong, rollback
bin/rails db:rollback

# 7. Fix migration and run again
bin/rails db:migrate
```

## PostgreSQL Specific Features

### JSONB Columns
```ruby
def change
  add_column :users, :preferences, :jsonb, default: {}
  add_index :users, :preferences, using: :gin
end

# Usage in model:
user.preferences = { theme: 'dark', notifications: true }
user.save
```

### Array Columns
```ruby
def change
  add_column :users, :tags, :string, array: true, default: []
  add_index :users, :tags, using: :gin
end

# Usage:
user.tags = ['fitness', 'health', 'wellness']
```

### Full-Text Search
```ruby
def change
  execute <<-SQL
    ALTER TABLE workouts
    ADD COLUMN search_vector tsvector;
    
    CREATE INDEX index_workouts_on_search_vector 
    ON workouts USING gin(search_vector);
  SQL
end
```

## Resources

- [Rails Migrations Guide](https://guides.rubyonrails.org/active_record_migrations.html)
- [PostgreSQL Data Types](https://www.postgresql.org/docs/current/datatype.html)
- [Rails API: Migrations](https://api.rubyonrails.org/classes/ActiveRecord/Migration.html)

