# VitalForge Development Guide

## Quick Start

### Starting the Server

```bash
# Option 1: Use the custom dev-server script (recommended)
./bin/dev-server

# Option 2: Manually ensure Ruby version and start
source ~/.zshrc && bin/rails server

# Option 3: Standard rails server (if Ruby version is already loaded)
bin/rails server
```

### Check Your Ruby Version

```bash
ruby -v
# Should output: ruby 3.2.2 (2023-03-30 revision e51014f9c0)
```

If you see Ruby 2.6.1, run:
```bash
source ~/.zshrc
ruby -v  # Should now show 3.2.2
```

## Project Structure

```
vital-forge-v1/
├── .cursorrules              # Project coding standards and best practices
├── .ruby-version             # Ruby 3.2.2
├── .envrc                    # Auto-loads correct Ruby version
├── app/
│   ├── controllers/
│   │   ├── sessions_controller.rb    # Login/logout
│   │   ├── users_controller.rb       # Registration
│   │   ├── pages_controller.rb       # Landing page
│   │   └── dashboard_controller.rb   # Protected dashboard
│   ├── models/
│   │   └── user.rb                   # User model with Devise
│   └── views/
│       ├── sessions/new.html.erb     # Login form
│       ├── users/new.html.erb        # Signup form
│       ├── pages/home.html.erb       # Landing page
│       └── dashboard/index.html.erb  # Dashboard
└── db/
    └── migrate/
        └── XXXXX_create_users.rb     # User table migration
```

## Authentication System

### How It Works

1. **Session-Based Authentication**: Uses Rails sessions (not JWT)
2. **Password Encryption**: Uses Devise (bcrypt)
3. **Security Features**:
   - Account lockout after 5 failed attempts (30-minute duration)
   - Session fixation prevention
   - CSRF protection enabled
   - Secure session cookies (HTTPOnly, SameSite)

### API Authentication (Devise + Warden)

- JSON login endpoint: `POST /api/v1/session`
- Request body:
  ```json
  { "user": { "email": "test@example.com", "password": "Password123!" } }
  ```
- Success: `200 OK` with `{ "data": { "user": { ... } } }`
- Failure: `401 Unauthorized` with `{ "error": "Invalid email or password" }`
- Logout: `DELETE /api/v1/session` → `204 No Content`
- Current user: `GET /api/v1/current_user` → `200` with user JSON, or `401` if not signed in
- CSRF: HTML is protected; API JSON endpoints currently skip CSRF. If enabled, include header `X-CSRF-Token` (value from `CSRF-TOKEN` cookie).

#### curl examples
```bash
# Login
curl -i -X POST http://localhost:3000/api/v1/session \
  -H 'Content-Type: application/json' \
  -d '{"user":{"email":"test@example.com","password":"Password123!"}}'

# Current user (after login; cookie handled by your client)
curl -i http://localhost:3000/api/v1/current_user

# Logout
curl -i -X DELETE http://localhost:3000/api/v1/session
```

### Authentication Endpoints

```
GET  /              → Landing page (public)
GET  /login         → Login form
POST /login         → Process login
GET  /signup        → Signup form
POST /users         → Create account
DELETE /logout      → Logout
GET  /dashboard     → Protected dashboard (requires login)
```

### Testing Authentication

```bash
# Start server
./bin/dev-server

# Visit http://localhost:3000
# 1. Click "Sign Up"
# 2. Fill in: First Name, Last Name, Email, Password (8+ chars)
# 3. Should redirect to dashboard
# 4. Click "Logout"
# 5. Try to access /dashboard directly - should redirect to login
```

## Database Commands

```bash
# Create database
bin/rails db:create

# Run migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Check migration status
bin/rails db:migrate:status

# Reset database (CAUTION: deletes all data)
bin/rails db:drop db:create db:migrate
```

## Rails Console

```bash
# Start console
bin/rails console

# Create a test user
User.create!(
  first_name: "Test",
  last_name: "User",
  email: "test@example.com",
  password: "password123",
  password_confirmation: "password123"
)

# Find user
User.find_by(email: "test@example.com")

# Check user count
User.count
```

## Code Quality

### Run Linters

```bash
# RuboCop (Ruby style checker)
bin/rubocop

# Auto-fix RuboCop issues
bin/rubocop -a

# Check for security vulnerabilities
bin/brakeman
```

### Run Tests

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/user_test.rb

# Run with verbose output
bin/rails test -v
```

## Project Rules & Best Practices

See `.cursorrules` file for comprehensive coding standards including:

- ✅ Ruby 3.2.2 & Rails 8 best practices
- ✅ PostgreSQL database design patterns
- ✅ Migration guidelines
- ✅ Security requirements
- ✅ React + Rails integration patterns
- ✅ DRY principles
- ✅ Performance optimization
- ✅ Testing requirements

## Common Tasks

### Adding a New Model

```bash
# Generate model with migration
bin/rails generate model Workout user:references name:string performed_at:datetime

# Review migration file in db/migrate/
# Run migration
bin/rails db:migrate
```

### Adding a New Controller

```bash
# Generate controller
bin/rails generate controller Workouts index show new create edit update destroy

# Or manually create in app/controllers/
```

### Database Constraints (Best Practice)

Always add both database constraints AND model validations:

```ruby
# Migration
add_column :users, :email, :string, null: false
add_index :users, :email, unique: true

# Model
validates :email, presence: true, uniqueness: true
```

## Troubleshooting

### Ruby Version Issues

**Problem**: Server starts with Ruby 2.6.1 instead of 3.2.2

**Solution**:
```bash
source ~/.zshrc
ruby -v  # Verify it shows 3.2.2
bin/rails server
```

### Database Connection Errors

**Problem**: Can't connect to PostgreSQL

**Solutions**:
```bash
# Check if PostgreSQL is running
brew services list

# Start PostgreSQL
brew services start postgresql@14

# Check environment variables
echo $DATABASE_HOST
echo $DATABASE_PASSWORD
```

### Bundle Install Fails

**Problem**: Gems won't install

**Solution**:
```bash
# Ensure correct Ruby version
source ~/.zshrc
ruby -v

# Update bundler
gem install bundler

# Try installing again
bundle install
```

## Next Steps

1. ✅ **Authentication is complete** - Users can signup, login, logout
2. 🔄 **Add React Components** - Follow Ryan Bigg's guide for mounting React
3. 🔄 **Build Workout Models** - Create Workout and Exercise models
4. 🔄 **Add API Endpoints** - Create API controllers for React components
5. 🔄 **User Preferences** - Extend user settings (unit system, notifications)

## Resources

- [Rails Guides](https://guides.rubyonrails.org/)
- [Rails API Docs](https://api.rubyonrails.org/)
- [Ryan Bigg's Rails + React Guide](https://ryanbigg.com/2023/06/rails-7-react-typescript-setup)
- [Devise Getting Started](https://github.com/heartcombo/devise#getting-started)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## Getting Help

- Check `.cursorrules` for coding standards
- Review Rails logs in `log/development.log`
- Use `bin/rails console` to debug
- Run `bin/rails routes` to see all routes

