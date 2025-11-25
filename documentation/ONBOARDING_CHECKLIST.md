# ✅ VitalForge Onboarding Checklist

**Your roadmap to becoming productive on this project**

---

## 📋 Week 1: Setup & Understanding

### Day 1: Environment Setup
- [ ] Clone the repository
- [ ] Install Ruby 3.2.6 with RVM
- [ ] Run `bundle install` successfully
- [ ] Create and migrate database: `bin/rails db:create db:migrate db:seed`
- [ ] Start server: `bin/dev`
- [ ] Visit `http://localhost:3000` and see the landing page
- [ ] Visit `http://localhost:3000/api-docs` and see Swagger UI

**Stuck?** See `QUICK_REFERENCE.md` → "Starting Development"

---

### Day 2: Documentation Review
- [ ] Read `README.md` (project overview)
- [ ] Read `PROJECT_SUMMARY.md` (what we built and why)
- [ ] Bookmark `QUICK_REFERENCE.md` (you'll use this daily)
- [ ] Skim `docs/DOCUMENTATION_MAP.md` (know where to find things)

**Goal:** Understand the project structure and where to find information

---

### Day 3: Testing & Quality
- [ ] Run tests: `bundle exec rspec`
- [ ] View coverage: `open coverage/index.html`
- [ ] Run linter: `bundle exec rubocop`
- [ ] Read `CODE_QUALITY.md`
- [ ] Understand what 38% coverage means

**Exercise:** Pick one untested method and write a test for it

---

### Day 4: API Exploration
- [ ] Read `API_DOCUMENTATION_GUIDE.md`
- [ ] Open Swagger UI: `http://localhost:3000/api-docs`
- [ ] Test `GET /api/v1/csrf` endpoint
- [ ] Test `POST /api/v1/login` endpoint (use seed user)
- [ ] Test `GET /api/v1/current_user` endpoint
- [ ] Test `DELETE /api/v1/logout` endpoint

**Seed user credentials:**
- Email: `test@example.com`
- Password: `Password123!`

---

### Day 5: Authentication Deep Dive
- [ ] Read `AUTH_ARCHITECTURE.md` thoroughly
- [ ] Understand why we use session cookies (not JWT)
- [ ] Understand what CSRF tokens prevent
- [ ] Understand what CORS whitelist does
- [ ] Review `config/initializers/cors.rb`
- [ ] Review `app/controllers/api/v1/sessions_controller.rb`

**Exercise:** Try to break the authentication
- What happens without CSRF token?
- What happens from unauthorized origin?
- Can you access session cookie from JavaScript?

---

## 📋 Week 2: Building Features

### Day 1: Your First Endpoint
- [ ] Read `DEVELOPMENT.md` (development workflow)
- [ ] Read `.cursorrules` (coding standards)
- [ ] Create a new branch: `git checkout -b feature/workouts-endpoint`
- [ ] Add route: `resources :workouts, only: [:index]` in `config/routes.rb`
- [ ] Create controller: `app/controllers/api/v1/workouts_controller.rb`
- [ ] Implement `index` action

**Code to write:**
```ruby
class Api::V1::WorkoutsController < Api::V1::BaseController
  def index
    workouts = current_user.workouts.order(performed_at: :desc)
    render json: { data: workouts }, status: :ok
  end
end
```

---

### Day 2: Testing Your Endpoint
- [ ] Create test file: `spec/requests/api/v1/workouts_spec.rb`
- [ ] Write test for successful request
- [ ] Write test for unauthorized request
- [ ] Run tests: `bundle exec rspec spec/requests/api/v1/workouts_spec.rb`
- [ ] Ensure all tests pass

**Test example:**
```ruby
RSpec.describe "API V1 Workouts", type: :request do
  let(:user) { User.create!(email: "test@example.com", password: "Password123!") }
  
  describe "GET /api/v1/workouts" do
    it "returns workouts for authenticated user" do
      # Sign in user first
      # Make request
      # Assert response
    end
  end
end
```

---

### Day 3: Documenting Your Endpoint
- [ ] Create Rswag spec: `spec/requests/api/v1/workouts_swagger_spec.rb`
- [ ] Follow pattern from `auth_swagger_spec.rb`
- [ ] Generate docs: `RAILS_ENV=test bundle exec rake rswag:specs:swaggerize`
- [ ] View in Swagger UI: `http://localhost:3000/api-docs`
- [ ] Test endpoint interactively in Swagger UI

**Goal:** Your endpoint should appear in Swagger UI with request/response examples

---

### Day 4: Code Review & Refinement
- [ ] Run RuboCop: `bundle exec rubocop`
- [ ] Fix any violations: `bundle exec rubocop -a`
- [ ] Run security scanner: `bin/brakeman`
- [ ] Check test coverage: `open coverage/index.html`
- [ ] Ensure coverage didn't decrease

**Checklist:**
- [ ] Tests pass
- [ ] RuboCop clean
- [ ] Brakeman clean
- [ ] Documented in Swagger
- [ ] Coverage maintained or increased

---

### Day 5: Pull Request
- [ ] Commit changes: `git commit -m "Add GET /api/v1/workouts endpoint"`
- [ ] Push branch: `git push origin feature/workouts-endpoint`
- [ ] Create pull request
- [ ] Add description explaining what you built and why
- [ ] Request code review

**PR Description Template:**
```
## What
Added GET /api/v1/workouts endpoint

## Why
Users need to view their workout history

## How
- Created WorkoutsController with index action
- Added tests with 100% coverage
- Documented with Rswag
- Follows REST conventions

## Testing
- [ ] All tests pass
- [ ] RuboCop clean
- [ ] Brakeman clean
- [ ] Swagger docs updated
```

---

## 📋 Week 3: Database & Migrations

### Day 1: Understanding the Schema
- [ ] Read `DATABASE_SCHEMA.md`
- [ ] Open `db/schema.rb` and review tables
- [ ] Run Rails console: `bundle exec rails c`
- [ ] Explore relationships:
  ```ruby
  user = User.first
  user.workouts
  workout = user.workouts.first
  workout.exercises
  ```

**Exercise:** Draw the database schema on paper

---

### Day 2: Creating a Migration
- [ ] Read `MIGRATIONS_GUIDE.md`
- [ ] Generate migration: `bin/rails g migration AddNotesToWorkouts notes:text`
- [ ] Review generated file in `db/migrate/`
- [ ] Run migration: `bin/rails db:migrate`
- [ ] Verify in console: `Workout.column_names`

**Important:** Always test rollback!
```bash
bin/rails db:rollback
bin/rails db:migrate
```

---

### Day 3: Adding an Index
- [ ] Generate migration: `bin/rails g migration AddIndexToWorkoutsPerformedAt`
- [ ] Add index:
  ```ruby
  def change
    add_index :workouts, :performed_at
  end
  ```
- [ ] Run migration
- [ ] Verify: `bundle exec rails dbconsole`
  ```sql
  \d workouts
  ```

**Why?** Indexes speed up queries with `WHERE` or `ORDER BY`

---

### Day 4: Complex Migration
- [ ] Read about foreign keys in `MIGRATIONS_GUIDE.md`
- [ ] Create a migration with foreign key constraint
- [ ] Test referential integrity (try to delete referenced record)
- [ ] Document why you added the constraint

**Exercise:** Add a `deleted_at` column for soft deletes

---

### Day 5: Data Migration
- [ ] Learn about data migrations vs schema migrations
- [ ] Create a migration that updates existing data
- [ ] Test on development database
- [ ] Ensure it's reversible

**Example:** Backfill `notes` column with default value

---

## 📋 Week 4: Advanced Topics

### Day 1: Performance Optimization
- [ ] Learn about N+1 queries
- [ ] Find N+1 queries in codebase (use Bullet gem)
- [ ] Fix with `includes` or `eager_load`
- [ ] Measure before/after performance

**Exercise:** Optimize workouts endpoint to include exercises

---

### Day 2: Error Handling
- [ ] Review error handling in `Api::V1::BaseController`
- [ ] Add custom error handling for your endpoint
- [ ] Test error scenarios (invalid data, not found, etc.)
- [ ] Return proper HTTP status codes

**Status codes to know:**
- 200 OK
- 201 Created
- 401 Unauthorized
- 404 Not Found
- 422 Unprocessable Entity
- 500 Internal Server Error

---

### Day 3: Background Jobs (Future)
- [ ] Read about Solid Queue (Rails 8)
- [ ] Understand when to use background jobs
- [ ] Create a simple job
- [ ] Test it works

**Use cases:**
- Sending emails
- Processing large datasets
- External API calls
- Generating reports

---

### Day 4: Caching (Future)
- [ ] Read about Solid Cache (Rails 8)
- [ ] Understand when to use caching
- [ ] Add caching to an expensive query
- [ ] Measure performance improvement

**Cache these:**
- Expensive calculations
- External API responses
- Frequently accessed data
- Rarely changing data

---

### Day 5: Deployment Preparation
- [ ] Read deployment checklist in `README.md`
- [ ] Ensure all tests pass
- [ ] Ensure RuboCop clean
- [ ] Ensure Brakeman clean
- [ ] Set up environment variables

**Environment variables needed:**
- `DATABASE_HOST`
- `DATABASE_USERNAME`
- `DATABASE_PASSWORD`
- `SECRET_KEY_BASE`
- `ALLOWED_ORIGINS`

---

## 🎯 Milestones

### Milestone 1: Environment Setup ✅
**You can:**
- [ ] Run the project locally
- [ ] Run tests
- [ ] View API documentation
- [ ] Navigate the codebase

**Time:** 1 week

---

### Milestone 2: First Feature ✅
**You can:**
- [ ] Build a new API endpoint
- [ ] Write tests for it
- [ ] Document it with Rswag
- [ ] Submit a pull request

**Time:** 2 weeks

---

### Milestone 3: Database Mastery ✅
**You can:**
- [ ] Create migrations
- [ ] Add indexes
- [ ] Understand relationships
- [ ] Optimize queries

**Time:** 3 weeks

---

### Milestone 4: Production Ready ✅
**You can:**
- [ ] Handle errors gracefully
- [ ] Optimize performance
- [ ] Deploy to staging
- [ ] Monitor production

**Time:** 4 weeks

---

## 📚 Learning Resources by Topic

### Ruby & Rails
- [ ] [Ruby on Rails Tutorial](https://www.railstutorial.org/) (FREE)
- [ ] [GoRails](https://gorails.com/) (Video tutorials)
- [ ] [Rails Guides](https://guides.rubyonrails.org/) (Official docs)

### Testing
- [ ] [Everyday Rails Testing with RSpec](https://leanpub.com/everydayrailsrspec)
- [ ] [Better Specs](https://www.betterspecs.org/)
- [ ] [RSpec Documentation](https://rspec.info/)

### API Design
- [ ] [RESTful API Design](https://stackoverflow.blog/2020/03/02/best-practices-for-rest-api-design/)
- [ ] [OpenAPI Specification](https://swagger.io/specification/)
- [ ] [API Security Checklist](https://github.com/shieldfy/API-Security-Checklist)

### Security
- [ ] [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [ ] [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [ ] [Brakeman Scanner](https://brakemanscanner.org/)

---

## 🤝 Getting Help

### When You're Stuck

**Step 1: Check the docs**
- `QUICK_REFERENCE.md` for commands
- `DEVELOPMENT.md` for troubleshooting
- `docs/DOCUMENTATION_MAP.md` to find the right doc

**Step 2: Read the error**
- Rails errors are usually very helpful
- Google the exact error message
- Check Stack Overflow

**Step 3: Debug**
- Use Rails console: `bundle exec rails c`
- Add `binding.pry` in your code
- Check logs: `tail -f log/development.log`

**Step 4: Ask for help**
- Provide context (what you're trying to do)
- Share the error message
- Show what you've tried
- Ask specific questions

---

## 🎉 Congratulations!

After completing this checklist, you will:

✅ **Understand the codebase**
- Architecture and design decisions
- Security layers and why they matter
- Database schema and relationships

✅ **Be productive**
- Build new API endpoints
- Write comprehensive tests
- Document your work
- Follow coding standards

✅ **Know the tools**
- RSpec for testing
- RuboCop for linting
- Rswag for documentation
- Rails console for debugging

✅ **Follow best practices**
- Security first
- Test-driven development
- Documentation as code
- Code quality standards

---

## 🚀 What's Next?

### Short Term (Next Month)
- [ ] Build complete CRUD for workouts
- [ ] Add pagination
- [ ] Add filtering and search
- [ ] Increase test coverage to 60%+

### Medium Term (Next 3 Months)
- [ ] Build Next.js frontend
- [ ] Generate TypeScript types
- [ ] Add real-time features
- [ ] Deploy to production

### Long Term (Next 6 Months)
- [ ] Add background jobs
- [ ] Implement caching
- [ ] Build mobile app
- [ ] Scale to 10,000+ users

---

## 📊 Self-Assessment

### After Week 1
**Can you:**
- [ ] Start the server?
- [ ] Run tests?
- [ ] Find documentation?
- [ ] Understand authentication flow?

**If no:** Review Week 1 checklist

---

### After Week 2
**Can you:**
- [ ] Build a new endpoint?
- [ ] Write tests for it?
- [ ] Document with Rswag?
- [ ] Submit a PR?

**If no:** Review Week 2 checklist

---

### After Week 3
**Can you:**
- [ ] Create migrations?
- [ ] Add indexes?
- [ ] Optimize queries?
- [ ] Understand relationships?

**If no:** Review Week 3 checklist

---

### After Week 4
**Can you:**
- [ ] Handle errors?
- [ ] Optimize performance?
- [ ] Deploy to staging?
- [ ] Work independently?

**If no:** Review Week 4 checklist

---

## 💡 Tips for Success

### 1. **Don't Rush**
Take time to understand WHY, not just WHAT. The goal is learning, not just completing tasks.

### 2. **Ask Questions**
No question is too basic. If you're confused, others probably are too.

### 3. **Read the Docs**
We've documented everything for a reason. Read before asking.

### 4. **Practice Daily**
Code every day, even if just for 30 minutes. Consistency matters.

### 5. **Learn by Doing**
Don't just read—build things. Break things. Fix things.

### 6. **Review Your Work**
Before submitting, review your own code. Would you approve this PR?

### 7. **Celebrate Progress**
Check off items as you complete them. Acknowledge your progress!

---

**Welcome to VitalForge! 🎉**

*Last updated: November 2025*

