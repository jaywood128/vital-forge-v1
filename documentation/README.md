# VitalForge 💪

A modern fitness tracking application built with Ruby on Rails 8, PostgreSQL, and React + TypeScript.

## 🚀 Features

### Current Features (v1.0)
- ✅ **User Authentication** - Secure session-based authentication with Devise + bcrypt
- ✅ **Cross-Origin API** - CORS-enabled API for Next.js frontend integration
- ✅ **CSRF Protection** - Secure token-based CSRF protection for API requests
- ✅ **API Documentation** - Auto-generated Swagger/OpenAPI docs at `/api-docs`
- ✅ **Account Security** - Account lockout after failed login attempts
- ✅ **Modern UI** - Glassmorphism design with VitalForge brand colors
- ✅ **Responsive Design** - Mobile-first approach
- ✅ **Test Coverage** - 38% coverage with RSpec (13 passing tests)
- ✅ **Code Quality** - RuboCop linting, Brakeman security scanning
- ✅ **Password Reset** - Secure password reset tokens (database ready)

### Planned Features
- 🔄 **Workout Tracking** - Log exercises, sets, reps, and weight
- 🔄 **Progress Analytics** - Visual charts and progress tracking
- 🔄 **Goal Setting** - Set and track fitness goals
- 🔄 **React Components** - Interactive workout logging interface
- 🔄 **Social Features** - Share workouts and achievements

## 🛠 Technology Stack

### Backend
- **Ruby** 3.2.6
- **Rails** 8.0.2
- **PostgreSQL** - Primary database
- **bcrypt** - Password encryption
- **Devise** - Authentication framework

### Frontend
- **React** 18.2+ (planned)
- **TypeScript** (planned)
- **ESBuild** - JavaScript bundler (planned)
- **ViewComponent** - React mounting (planned)

### Rails 8 Features
- **Solid Queue** - Background job processing
- **Solid Cache** - Database-backed caching
- **Solid Cable** - WebSocket connections
- **Importmap** - JavaScript dependencies

## 📊 Database Schema

VitalForge uses a normalized PostgreSQL schema optimized for fitness tracking:

```
User → Workouts → WorkoutExercises → ExerciseSets
                        ↓
                    Exercises (catalog)
```

### Key Entities:
- **Users** - User accounts with secure authentication
- **Workouts** - Individual workout sessions with metadata
- **Exercises** - Master catalog of exercises (reusable across users)
- **WorkoutExercises** - Join table linking workouts to exercises
- **ExerciseSets** - Individual set performance (reps, weight, RPE)

### Design Highlights:
- ✅ Normalized schema prevents data duplication
- ✅ Composite indexes for optimal query performance
- ✅ Foreign key constraints ensure referential integrity
- ✅ Cascade deletes prevent orphaned records
- ✅ Supports progressive overload tracking (different weights per set)

**For detailed schema documentation, see [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)**

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Ruby** 3.2.6 (use RVM recommended)
- **Rails** 8.0.2
- **PostgreSQL** 14+
- **Node.js** 18+ (for JavaScript tooling)
- **Yarn** or **npm** (for JavaScript packages)
- **Git**

### Check Your Versions
```bash
ruby -v        # Should show: ruby 3.2.6
rails -v       # Should show: Rails 8.0.2
psql --version # Should show: psql 14.x or higher
node -v        # Should show: v18.x or higher
```

### Quick Start (5 minutes)
```bash
# 1. Install dependencies
bundle install

# 2. Setup database
bin/rails db:create db:migrate db:seed

# 3. Start server
bin/dev

# 4. Visit http://localhost:3000
# 5. View API docs at http://localhost:3000/api-docs
```

**For detailed setup and architecture guide, see [SETUP_GUIDE.md](SETUP_GUIDE.md)** 🎓

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone <repository-url>
cd vital-forge-v1
```

### 2. Install Dependencies

#### Ruby Dependencies
```bash
# Ensure you're using Ruby 3.2.6
source ~/.zshrc  # or source ~/.bashrc
ruby -v

# Install gems
bundle install
```

#### JavaScript Dependencies (Future)
```bash
# When React is integrated
yarn install
# or
npm install
```

### 3. Database Setup

#### Configure Database
```bash
# Copy environment variables (if needed)
cp .env.example .env

# Edit .env with your database credentials
# DATABASE_HOST=localhost
# DATABASE_USERNAME=postgres
# DATABASE_PASSWORD=your_password
```

#### Create and Migrate Database
```bash
# Create databases
bin/rails db:create

# Run migrations
bin/rails db:migrate

# (Optional) Seed data
bin/rails db:seed
```

### 4. Start the Server

#### Option 1: Using Custom Script (Recommended)
```bash
./bin/dev-server
```

#### Option 2: Standard Rails Server
```bash
# Ensure Ruby version is loaded
source ~/.zshrc && bin/rails server
```

#### Option 3: With Environment
```bash
bin/rails server
```

### 5. Visit the Application

Open your browser and navigate to:
```
http://localhost:3000
```

You should see the VitalForge landing page! 🎉

## 📖 Documentation

**📚 [Documentation Map](docs/DOCUMENTATION_MAP.md)** - Visual guide to all documentation

Comprehensive documentation is available in the project:

### 🎯 Start Here
- **[ONBOARDING_CHECKLIST.md](ONBOARDING_CHECKLIST.md)** - ✅ 4-week roadmap for new developers
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - 📊 High-level overview of what we built and why
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - 🎓 Complete architecture guide, learning resources, and next steps
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - ⚡ Common commands and workflows (bookmark this!)
- **[ENVIRONMENT_VARIABLES.md](ENVIRONMENT_VARIABLES.md)** - 🔑 Environment setup and secrets management

### 🐳 Docker & Deployment
- **[DOCKER_SETUP_MAC.md](DOCKER_SETUP_MAC.md)** - 🐳 Complete Docker setup guide for macOS

### 📚 Deep Dives
- **[AUTH_ARCHITECTURE.md](AUTH_ARCHITECTURE.md)** - Web authentication system deep-dive
- **[DUAL_AUTH_GUIDE.md](DUAL_AUTH_GUIDE.md)** - 🔐 Dual authentication (Web + Mobile)
- **[SWAGGER_JWT_UPDATE.md](SWAGGER_JWT_UPDATE.md)** - 📖 Swagger UI with JWT testing
- **[API_DOCUMENTATION_GUIDE.md](API_DOCUMENTATION_GUIDE.md)** - How to document APIs with Rswag
- **[CODE_QUALITY.md](CODE_QUALITY.md)** - Testing, linting, and quality tools

### 🛠 Development
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Development workflow and commands
- **[MIGRATIONS_GUIDE.md](MIGRATIONS_GUIDE.md)** - Database migration patterns
- **[STYLING_UPDATE.md](STYLING_UPDATE.md)** - Design system and colors
- **[.cursorrules](.cursorrules)** - Project coding standards

## 🔐 Auth Quickstart (Next.js SPA)

Session-based auth with CSRF, for a separate Next.js origin:

- Seed CSRF: `GET http://localhost:3000/api/v1/csrf` (send cookies)
- Login: `POST http://localhost:3000/api/v1/session`
  - Headers: `Content-Type: application/json`, `X-CSRF-Token: <CSRF-TOKEN cookie>`
  - Body: `{ "user": { "email": "user@example.com", "password": "Password123!" } }`
  - credentials: `include`
- Check session: `GET /api/v1/current_user` (credentials: include)
- Logout: `DELETE /api/v1/session` (credentials: include, `X-CSRF-Token`)

Notes:
- For all non-GET requests, include `X-CSRF-Token` with the value of the `CSRF-TOKEN` cookie.
- Always send `credentials: 'include'` so the browser sends the session cookie.

## 🎨 Design System

VitalForge uses a carefully crafted color palette designed for fitness motivation:

### Primary Colors
- **Electric Blue** `#2563EB` - Trust, focus, reliability
- **Energetic Orange** `#F97316` - Motivation, enthusiasm, energy

### Secondary Colors
- **Deep Navy** `#1E293B` - Professional, stable
- **Fresh Green** `#10B981` - Growth, progress, health
- **Warm Gray** `#F1F5F9` - Clean, neutral

### Usage
All colors are defined as CSS custom properties in `app/assets/stylesheets/application.css`:
```css
:root {
  --electric-blue: #2563EB;
  --energetic-orange: #F97316;
  /* ... more colors */
}
```

See [STYLING_UPDATE.md](STYLING_UPDATE.md) for complete design system documentation.

## 🏗 Project Structure

```
vital-forge-v1/
├── app/
│   ├── assets/stylesheets/      # CSS with VitalForge design system
│   ├── controllers/             # Rails controllers
│   │   ├── sessions_controller.rb   # Login/logout
│   │   ├── users_controller.rb      # User registration
│   │   ├── pages_controller.rb      # Landing page
│   │   └── dashboard_controller.rb  # Protected dashboard
│   ├── models/
│   │   └── user.rb              # User model with authentication
│   ├── views/
│   │   ├── sessions/            # Login views
│   │   ├── users/               # Registration views
│   │   ├── pages/               # Public pages
│   │   └── dashboard/           # Dashboard views
│   └── components/              # ViewComponents (future)
├── config/
│   ├── database.yml             # Database configuration
│   ├── routes.rb                # Application routes
│   └── initializers/
│       └── session_store.rb     # Session security config
├── db/
│   └── migrate/                 # Database migrations
├── .cursor/
│   └── rules/
│       ├── frontend/            # Frontend rules & color palette
│       └── backend/             # Backend rules
├── .cursorrules                 # Project coding standards
├── .ruby-version                # Ruby 3.2.2
├── DEVELOPMENT.md               # Development guide
├── MIGRATIONS_GUIDE.md          # Migration patterns
└── README.md                    # This file
```

## 🔐 Environment Variables

Required environment variables for production:

```bash
# Database
DATABASE_HOST=your-database-host
DATABASE_PORT=5432
DATABASE_USERNAME=your-username
DATABASE_PASSWORD=your-password

# Rails
RAILS_ENV=production
SECRET_KEY_BASE=your-secret-key

# CORS (for Next.js frontend)
ALLOWED_ORIGINS=https://your-nextjs-app.com,https://staging.your-nextjs-app.com

# Email (future)
SMTP_HOST=smtp.example.com
SMTP_USERNAME=your-username
SMTP_PASSWORD=your-password
```

**For development:**
- `ALLOWED_ORIGINS` defaults to `http://localhost:3001`
- Database credentials can be set in `.env` (not committed to git)

## 🧪 Testing

```bash
# Run all tests (RSpec)
bundle exec rspec

# Run specific test file
bundle exec rspec spec/requests/api/v1/auth_spec.rb

# Run with documentation format
bundle exec rspec --format documentation

# View test coverage
open coverage/index.html
```

**Current test coverage: 38.31%** (13 passing tests)

**For detailed testing guide, see [CODE_QUALITY.md](CODE_QUALITY.md)**

## 🔍 Code Quality

### Linting
```bash
# Run RuboCop (Rails Omakase style)
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a

# Generate JSON report for SonarCloud
bundle exec rubocop --format json --out rubocop-result.json
```

### Security Scanning
```bash
# Run Brakeman security scanner
bin/brakeman
```

### API Documentation
```bash
# Generate Swagger/OpenAPI docs from tests
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize

# View interactive docs
open http://localhost:3000/api-docs
```

**For detailed code quality guide, see [CODE_QUALITY.md](CODE_QUALITY.md)**

## 📊 Database Commands

```bash
# Create database
bin/rails db:create

# Run migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Check migration status
bin/rails db:migrate:status

# Reset database (⚠️ Deletes all data)
bin/rails db:reset

# Open Rails console
bin/rails console
```

## 🚢 Deployment

### Production Checklist

Before deploying to production:

- [ ] All tests pass: `bin/rails test`
- [ ] No security issues: `bin/brakeman`
- [ ] Code style passes: `bin/rubocop`
- [ ] Environment variables configured
- [ ] Database backups enabled
- [ ] SSL/HTTPS configured
- [ ] Error tracking setup (Sentry, Rollbar, etc.)
- [ ] Performance monitoring enabled
- [ ] Migrations tested

### Deployment Steps

```bash
# 1. Pull latest code
git pull origin main

# 2. Install dependencies
bundle install

# 3. Run migrations
RAILS_ENV=production bin/rails db:migrate

# 4. Precompile assets
RAILS_ENV=production bin/rails assets:precompile

# 5. Restart server
# (Depends on your hosting platform)
```

## 🤝 Contributing

### Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow coding standards in `.cursorrules`
   - Write tests for new features
   - Update documentation as needed

3. **Test your changes**
   ```bash
   bin/rails test
   bin/rubocop
   bin/brakeman
   ```

4. **Commit your changes**
   ```bash
   git commit -m "Add feature: description of what you added"
   ```

5. **Push and create pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

### Coding Standards

- Follow Ruby and Rails conventions
- Use meaningful variable and method names
- Comment WHY, not WHAT
- Keep methods under 15 lines
- Write tests for new features
- Update documentation when changing features

See [.cursorrules](.cursorrules) for complete coding standards.

## 🐛 Troubleshooting

### Ruby Version Issues

**Problem:** Server starts with wrong Ruby version

**Solution:**
```bash
source ~/.zshrc
ruby -v  # Verify it shows 3.2.6
bin/rails server
```

### Database Connection Errors

**Problem:** Can't connect to PostgreSQL

**Solutions:**
```bash
# Check if PostgreSQL is running
brew services list

# Start PostgreSQL
brew services start postgresql@14

# Check environment variables
echo $DATABASE_HOST
```

### Bundle Install Fails

**Problem:** Gems won't install

**Solution:**
```bash
# Ensure correct Ruby version
source ~/.zshrc
ruby -v

# Update bundler
gem install bundler

# Try again
bundle install
```

### Migration Errors

**Problem:** Migration fails or can't rollback

**Solution:**
```bash
# Check migration status
bin/rails db:migrate:status

# Rollback to specific version
bin/rails db:migrate:down VERSION=20251026180606

# Reset database (⚠️ Deletes all data)
bin/rails db:reset
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for more troubleshooting help.

## 📝 License

This project is private and proprietary.

## 👥 Team

- **Developer:** [Your Name]
- **Project:** VitalForge Fitness Tracking App
- **Started:** October 2025

## 📧 Support

For questions or issues:
- Check [DEVELOPMENT.md](DEVELOPMENT.md) for development help
- Check [.cursorrules](.cursorrules) for coding standards
- Review existing documentation before asking

## 🎯 Roadmap

### Phase 1: Authentication (✅ Complete)
- [x] User registration and login
- [x] Password encryption with bcrypt
- [x] Account lockout security
- [x] Session management
- [x] Modern UI with brand colors

### Phase 2: Workout Tracking (In Progress)
- [ ] Create workout models and migrations
- [ ] Build React workout logging components
- [ ] Add exercise database
- [ ] Implement workout history

### Phase 3: Progress Tracking
- [ ] Add analytics dashboard
- [ ] Visual progress charts
- [ ] Goal setting and tracking
- [ ] Achievement system

### Phase 4: Social Features
- [ ] User profiles
- [ ] Workout sharing
- [ ] Follow other users
- [ ] Activity feed

### Phase 5: Mobile App
- [ ] React Native mobile app
- [ ] Offline workout logging
- [ ] Push notifications
- [ ] Wearable integration

## 🌟 Acknowledgments

- Rails 8 team for the amazing framework
- Ryan Bigg for the Rails + React integration pattern
- VitalForge design system inspiration from fitness industry best practices

---

**Built with ❤️ using Ruby on Rails 8**

For detailed development documentation, see [DEVELOPMENT.md](DEVELOPMENT.md)
