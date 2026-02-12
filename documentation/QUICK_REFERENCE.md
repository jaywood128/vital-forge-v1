# 🚀 VitalForge Quick Reference

**Common commands and workflows for daily development (Hybrid Docker + Native approach)**

---

## ⚡ First Time Setup

**One-liner setup:**
```bash
docker-compose up -d db redis && bundle install && bin/rails db:prepare && bin/rails db:seed && bin/dev
```

Or step-by-step:
```bash
# 1. Install Docker Desktop (one-time)
brew install --cask docker
# Open Docker Desktop and wait for it to start

# 2. Copy environment variables
cp .env.example .env
# Edit .env with your values (DATABASE_PASSWORD, API keys, etc.)

# 3. Start Docker infrastructure
docker-compose up -d db redis

# 4. Install Ruby dependencies
bundle install

# 5. Create and migrate databases
bin/rails db:prepare

# 6. Seed sample data
bin/rails db:seed

# 7. Start Rails
bin/dev

# ✅ Visit http://localhost:3000
```

---

## 🏃 Starting Development

```bash
# 1. Start Docker infrastructure (if not running)
docker-compose up -d db redis

# 2. Start Rails server (native)
bin/dev

# 3. In another terminal: Start UI (if needed)
cd ../vital-forge-ui-v1
npm run dev

# Rails console
bundle exec rails c

# Check Docker services status
docker-compose ps
```

---

## 🐳 Docker Commands

```bash
# Start PostgreSQL + Redis only
docker-compose up -d db redis

# Stop Docker services
docker-compose stop

# Stop and remove containers
docker-compose down

# View logs
docker-compose logs -f db redis

# Restart after .env changes
docker-compose restart db redis

# Check container status
docker-compose ps

# Access PostgreSQL shell
docker-compose exec db psql -U postgres

# Optional: Start pgAdmin (database GUI)
docker-compose --profile tools up -d pgadmin
# Then visit http://localhost:5050
```

---

## 🧪 Testing

```bash
# Run all tests
bundle exec rspec

# Run specific file
bundle exec rspec spec/requests/api/v1/auth_spec.rb

# Run specific test (by line number)
bundle exec rspec spec/requests/api/v1/auth_spec.rb:15

# Run with documentation format
bundle exec rspec --format documentation

# View coverage report
open coverage/index.html
```

---

## 📖 API Documentation

```bash
# Generate Swagger docs from tests
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize

# View interactive docs
open http://localhost:3000/api-docs

# Export OpenAPI spec
curl http://localhost:3000/api-docs/v1/swagger.yaml > openapi.yaml

# Generate TypeScript types (requires openapi-typescript)
npx openapi-typescript http://localhost:3000/api-docs/v1/swagger.yaml -o types/api.ts
```

---

## 🔍 Code Quality

```bash
# Run RuboCop linter
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a

# Generate JSON report for SonarCloud
bundle exec rubocop --format json --out rubocop-result.json

# Run security scanner
bin/brakeman

# Check test coverage
bundle exec rspec
open coverage/index.html
```

---

## 💾 Database

**Using Docker PostgreSQL** - The database runs in Docker, so no local Postgres installation needed!

**One-liner for fresh database:**
```bash
docker-compose up -d db redis && bin/rails db:prepare && bin/rails db:seed
```

**Individual commands:**
```bash
# Create database (first time only)
bin/rails db:prepare

# Run migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Seed database
bin/rails db:seed

# Reset database (DESTROYS ALL DATA!)
bin/rails db:reset

# Check database status
bin/rails db:version

# Access PostgreSQL shell (via Docker)
docker-compose exec db psql -U postgres

# List databases
docker-compose exec db psql -U postgres -l

# Connect to specific database
docker-compose exec db psql -U postgres -d vital_forge_v1_development

# Backup database
docker-compose exec db pg_dump -U postgres vital_forge_v1_development > backup.sql

# Restore database
docker-compose exec -T db psql -U postgres vital_forge_v1_development < backup.sql
```

**Queue schema:** `db/queue_schema.rb` is auto-generated. To regenerate from the solid_queue gem: `bin/rails solid_queue:install` then `bin/rails db:migrate`. The queue DB uses `db/queue_migrate` (see `config/database.yml`).
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Rollback specific migration
bin/rails db:migrate:down VERSION=20251026180606

# Check migration status
bin/rails db:migrate:status

# Seed database
bin/rails db:seed

# Reset database (⚠️ DELETES ALL DATA)
bin/rails db:reset

# Check current schema version
bundle exec rails db:version

# Open database console
bundle exec rails dbconsole
```

---

## 🔐 Authentication Testing (Bruno/Postman)

### 1. Get CSRF Token
```http
GET http://localhost:3000/api/v1/csrf
```
**Response:** Sets `CSRF-TOKEN` cookie

---

### 2. Login
```http
POST http://localhost:3000/api/v1/login
Content-Type: application/json
X-CSRF-Token: <value-from-cookie>

{
  "user": {
    "email": "test@example.com",
    "password": "Password123!"
  }
}
```
**Response:** Sets `_vital_forge_session` cookie

---

### 3. Get Current User
```http
GET http://localhost:3000/api/v1/current_user
Cookie: _vital_forge_session=<session-value>
```

---

### 4. Logout
```http
DELETE http://localhost:3000/api/v1/logout
X-CSRF-Token: <value-from-cookie>
Cookie: _vital_forge_session=<session-value>
```

---

## 🌐 Routes

```bash
# View all routes
bundle exec rails routes

# Search for specific route
bundle exec rails routes | grep api

# View routes for specific controller
bundle exec rails routes -c api/v1/sessions
```

---

## 🐛 Debugging

```bash
# View logs in real-time
tail -f log/development.log

# Clear logs
> log/development.log

# Check what's running on port 3000
lsof -i :3000

# Kill process on port 3000
kill -9 $(lsof -t -i:3000)

# Rails console debugging
bundle exec rails c
> User.find_by(email: "test@example.com")
> User.last.workouts.count
```

---

## 📦 Dependencies

```bash
# Install gems
bundle install

# Update all gems
bundle update

# Update specific gem
bundle update rails

# Check for outdated gems
bundle outdated

# Show gem dependency tree
bundle viz --format=svg --requirements
```

---

## 🔧 Ruby Version Management (RVM)

```bash
# List installed Ruby versions
rvm list

# Install Ruby 3.2.6
rvm install 3.2.6

# Use Ruby 3.2.6
rvm use 3.2.6

# Set default Ruby version
rvm use 3.2.6 --default

# Check current Ruby version
ruby -v

# Reload RVM
source ~/.zshrc
```

---

## 🚢 Git Workflow

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Stage changes
git add .

# Commit with meaningful message
git commit -m "Add feature: description"

# Push to remote
git push origin feature/your-feature-name

# Update from main
git checkout main
git pull origin main
git checkout feature/your-feature-name
git merge main
```

---

## 🔥 Emergency Commands

```bash
# Rails server won't start? Kill Spring
pkill -f spring

# Restart Rails server
bin/rails restart

# Clear Rails cache
bin/rails tmp:clear

# Rebuild database from scratch (⚠️ DELETES ALL DATA)
bin/rails db:drop db:create db:migrate db:seed

# Fix bundle issues
rm -rf .bundle vendor/bundle
bundle install

# Fix RVM issues
rvm get stable
rvm reload
rvm use 3.2.6
```

---

## 📊 Performance

```bash
# Check database query performance
bundle exec rails c
> User.includes(:workouts).limit(10).explain

# Benchmark code
bundle exec rails c
> require 'benchmark'
> Benchmark.measure { User.all.to_a }

# Profile memory usage (requires memory_profiler gem)
bundle exec rails c
> require 'memory_profiler'
> report = MemoryProfiler.report { User.all.to_a }
> report.pretty_print
```

---

## 🌍 Environment Variables

```bash
# View all environment variables
printenv

# Set environment variable (temporary)
export ALLOWED_ORIGINS="http://localhost:3001"

# Set environment variable (permanent)
echo 'export ALLOWED_ORIGINS="http://localhost:3001"' >> ~/.zshrc
source ~/.zshrc

# Use .env file (requires dotenv-rails gem)
echo 'ALLOWED_ORIGINS=http://localhost:3001' >> .env
```

---

## 📝 Code Generation

```bash
# Generate model
bin/rails g model Workout user:references performed_at:datetime

# Generate controller
bin/rails g controller Api::V1::Workouts

# Generate migration
bin/rails g migration AddIndexToUsersEmail

# Destroy generated files
bin/rails d model Workout
```

---

## 🎯 Common Workflows

### Adding a New API Endpoint

1. **Create route** (`config/routes.rb`)
   ```ruby
   namespace :api do
     namespace :v1 do
       resources :workouts, only: [:index, :show, :create]
     end
   end
   ```

2. **Create controller** (`app/controllers/api/v1/workouts_controller.rb`)
   ```ruby
   class Api::V1::WorkoutsController < Api::V1::BaseController
     def index
       workouts = current_user.workouts.order(performed_at: :desc)
       render json: { data: workouts }, status: :ok
     end
   end
   ```

3. **Write Rswag spec** (`spec/requests/api/v1/workouts_swagger_spec.rb`)
   - Follow pattern in `auth_swagger_spec.rb`

4. **Generate docs**
   ```bash
   RAILS_ENV=test bundle exec rake rswag:specs:swaggerize
   ```

5. **Test in Swagger UI**
   ```bash
   open http://localhost:3000/api-docs
   ```

---

### Running the Full Quality Check

```bash
# 1. Run tests
bundle exec rspec

# 2. Check coverage (should be > 60%)
open coverage/index.html

# 3. Run linter
bundle exec rubocop -a

# 4. Run security scanner
bin/brakeman

# 5. Generate API docs
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize

# 6. Verify docs
open http://localhost:3000/api-docs
```

---

## 🆘 Getting Help

```bash
# Rails help
bin/rails --help

# Rake tasks
bin/rails --tasks

# RSpec help
bundle exec rspec --help

# RuboCop help
bundle exec rubocop --help

# Database help
bin/rails db --help
```

---

## 📚 Documentation Links

- **Setup Guide:** [SETUP_GUIDE.md](SETUP_GUIDE.md)
- **Authentication:** [AUTH_ARCHITECTURE.md](AUTH_ARCHITECTURE.md)
- **API Docs:** [API_DOCUMENTATION_GUIDE.md](API_DOCUMENTATION_GUIDE.md)
- **Code Quality:** [CODE_QUALITY.md](CODE_QUALITY.md)
- **Development:** [DEVELOPMENT.md](DEVELOPMENT.md)
- **Migrations:** [MIGRATIONS_GUIDE.md](MIGRATIONS_GUIDE.md)
- **Styling:** [STYLING_UPDATE.md](STYLING_UPDATE.md)

---

**💡 Tip:** Bookmark this page for quick reference during development!

*Last updated: November 2025*

