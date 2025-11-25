# 🎓 VitalForge Setup & Architecture Guide

**A comprehensive guide to understanding what we built, why we built it, and how to expand your knowledge.**

---

## 📋 Table of Contents

1. [What We Built](#what-we-built)
2. [Why We Made These Choices](#why-we-made-these-choices)
3. [Architecture Overview](#architecture-overview)
4. [Learning Resources](#learning-resources)
5. [Next Steps](#next-steps)
6. [Troubleshooting](#troubleshooting)

---

## 🏗 What We Built

### 1. **Cross-Origin Authentication System**
**Files:** `app/controllers/api/v1/sessions_controller.rb`, `config/initializers/cors.rb`, `config/initializers/session_store.rb`

**What it does:**
- Allows a **separate Next.js frontend** (running on `localhost:3001`) to authenticate with the Rails API (running on `localhost:3000`)
- Uses **session cookies** (not JWT) for security
- Implements **CSRF protection** to prevent cross-site attacks
- Configures **CORS** to allow cross-origin requests with credentials

**Key features:**
- ✅ HttpOnly cookies (JavaScript can't access them → prevents XSS attacks)
- ✅ CSRF tokens (prevents unauthorized requests from other sites)
- ✅ Environment-based CORS whitelist (only approved domains can connect)
- ✅ Proper `SameSite` cookie policies (`:lax` in dev, `:none` in production)

**Documentation:** See `AUTH_ARCHITECTURE.md`

---

### 2. **API Documentation with Rswag (Swagger/OpenAPI)**
**Files:** `spec/requests/api/v1/auth_swagger_spec.rb`, `swagger/v1/swagger.yaml`

**What it does:**
- **Auto-generates** API documentation from your RSpec tests
- Provides an **interactive testing UI** at `http://localhost:3000/api-docs`
- Exports **OpenAPI 3.0 spec** that can generate TypeScript types for Next.js
- Keeps docs **in sync with code** (if tests pass, docs are accurate)

**Key features:**
- ✅ Interactive Swagger UI for testing endpoints
- ✅ Request/response examples with schemas
- ✅ TypeScript type generation for frontend
- ✅ Import into Postman/Bruno for API testing

**Documentation:** See `API_DOCUMENTATION_GUIDE.md`

---

### 3. **Code Quality & Testing Infrastructure**
**Files:** `spec/spec_helper.rb`, `.rubocop.yml`, `sonar-project.properties`

**What it does:**
- **RSpec** - Automated testing framework
- **SimpleCov** - Measures test coverage (currently 38.31%)
- **RuboCop** - Code linter (enforces Rails Omakase style)
- **SonarCloud** - Centralized code quality dashboard (optional)

**Key features:**
- ✅ 13 passing tests (authentication flow fully tested)
- ✅ Coverage reports in JSON format for CI/CD
- ✅ RuboCop auto-fix for style issues
- ✅ Ready for GitHub Actions integration

**Documentation:** See `CODE_QUALITY.md`

---

### 4. **Ruby Environment Setup**
**Files:** `.ruby-version`, `Gemfile`

**What it does:**
- Uses **Ruby 3.2.6** with **RVM** (Ruby Version Manager)
- Cleaned up conflicting version managers (`mise`)
- Configured project to use correct Ruby version automatically

**Key features:**
- ✅ RVM automatically switches to Ruby 3.2.6 when entering project directory
- ✅ All gems installed and working
- ✅ Database migrations up to date
- ✅ Rails 8.0.2 running smoothly

---

## 🤔 Why We Made These Choices

### Why Session-Based Auth (Not JWT)?

**Reason:** Security and simplicity.

| Feature | Session Cookies | JWT |
|---------|----------------|-----|
| **Storage** | HttpOnly cookie (JS can't access) | LocalStorage (JS can access) |
| **XSS Protection** | ✅ Yes | ❌ No |
| **Revocation** | ✅ Instant (destroy session) | ❌ Must wait for expiry |
| **Size** | Small (session ID only) | Large (entire payload) |
| **Best for** | Traditional web apps, SPAs on same domain | Microservices, mobile apps |

**Our use case:** Next.js SPA on a different origin → Session cookies with CORS work perfectly.

**Learn more:**
- [OWASP Session Management](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [JWT vs Sessions](https://stackoverflow.com/questions/43452896/authentication-jwt-usage-vs-session)

---

### Why Rswag (Not Manual API Docs)?

**Reason:** Documentation that stays in sync with code.

**The problem with manual docs:**
- ❌ Docs get outdated as code changes
- ❌ Developers forget to update them
- ❌ No way to verify docs are accurate

**How Rswag solves this:**
- ✅ Docs are **generated from tests**
- ✅ If tests pass, docs are accurate
- ✅ One source of truth (the code)
- ✅ Interactive testing UI for free

**Learn more:**
- [Rswag GitHub](https://github.com/rswag/rswag)
- [OpenAPI Specification](https://swagger.io/specification/)
- [API Design Best Practices](https://swagger.io/resources/articles/best-practices-in-api-design/)

---

### Why RuboCop Rails Omakase?

**Reason:** Opinionated defaults from Rails creator DHH.

**Philosophy:**
- Don't waste time debating style
- Use proven conventions from Rails core team
- Focus on building features, not arguing about tabs vs spaces

**Learn more:**
- [RuboCop Rails Omakase](https://github.com/rails/rubocop-rails-omakase)
- [The Rails Doctrine](https://rubyonrails.org/doctrine)

---

### Why SimpleCov + SonarCloud?

**Reason:** Measure and improve code quality over time.

**What they do:**
- **SimpleCov** - Shows which lines of code are tested
- **SonarCloud** - Tracks quality metrics over time (bugs, code smells, security issues)

**Why it matters:**
- ✅ Catch bugs before they reach production
- ✅ Ensure new code is tested
- ✅ Track technical debt
- ✅ Enforce quality standards in CI/CD

**Learn more:**
- [SimpleCov Documentation](https://github.com/simplecov-ruby/simplecov)
- [SonarCloud for Ruby](https://docs.sonarcloud.io/advanced-setup/languages/ruby/)

---

## 🏛 Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Next.js Frontend                        │
│                   (localhost:3001)                           │
│                                                              │
│  - React Components                                          │
│  - TypeScript                                                │
│  - Auto-generated API types from OpenAPI spec                │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      │ HTTP Requests
                      │ (with credentials: 'include')
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                   CORS Middleware                            │
│  - Checks ALLOWED_ORIGINS env var                           │
│  - Allows credentials (cookies)                              │
│  - Exposes CSRF-TOKEN header                                 │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                Rails 8 API Backend                           │
│                   (localhost:3000)                           │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  API Controllers (app/controllers/api/v1/)             │ │
│  │  - SessionsController (login/logout)                   │ │
│  │  - CurrentUsersController (get current user)           │ │
│  │  - CsrfController (get CSRF token)                     │ │
│  └────────────────────────────────────────────────────────┘ │
│                      │                                       │
│  ┌────────────────────▼──────────────────────────────────┐  │
│  │  Business Logic (app/models/)                         │  │
│  │  - User model (authentication, validations)           │  │
│  │  - Workout, Exercise models (future)                  │  │
│  └────────────────────┬──────────────────────────────────┘  │
│                      │                                       │
│  ┌────────────────────▼──────────────────────────────────┐  │
│  │  PostgreSQL Database                                  │  │
│  │  - Users, Workouts, Exercises, etc.                   │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Authentication Flow

```
┌─────────┐                                      ┌─────────┐
│ Next.js │                                      │  Rails  │
│Frontend │                                      │   API   │
└────┬────┘                                      └────┬────┘
     │                                                │
     │  1. GET /api/v1/csrf                          │
     ├──────────────────────────────────────────────>│
     │                                                │
     │  2. Set-Cookie: CSRF-TOKEN=abc123             │
     │<──────────────────────────────────────────────┤
     │                                                │
     │  3. POST /api/v1/login                        │
     │     Headers: X-CSRF-Token: abc123             │
     │     Body: { user: { email, password } }       │
     ├──────────────────────────────────────────────>│
     │                                                │
     │  4. Set-Cookie: _vital_forge_session=xyz      │
     │     Response: { data: { user: {...} } }       │
     │<──────────────────────────────────────────────┤
     │                                                │
     │  5. GET /api/v1/workouts                      │
     │     Cookie: _vital_forge_session=xyz          │
     ├──────────────────────────────────────────────>│
     │                                                │
     │  6. Response: { data: [...workouts] }         │
     │<──────────────────────────────────────────────┤
     │                                                │
```

### Security Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Layers                           │
└─────────────────────────────────────────────────────────────┘

1. CORS Whitelist (config/initializers/cors.rb)
   ├─ Checks ALLOWED_ORIGINS environment variable
   ├─ Rejects requests from unauthorized domains
   └─ Only allows credentials from whitelisted origins

2. CSRF Protection (app/controllers/application_controller.rb)
   ├─ Generates unique token per session
   ├─ Validates X-CSRF-Token header on non-GET requests
   └─ Prevents unauthorized requests even with stolen cookies

3. Session Authentication (app/controllers/api/v1/base_controller.rb)
   ├─ Checks for valid session cookie
   ├─ Verifies user exists in database
   └─ Returns 401 if not authenticated

4. Authorization (future)
   ├─ Check user permissions
   ├─ Verify resource ownership
   └─ Return 403 if not authorized
```

**Key Insight:** These layers work together. Even if an attacker gets past one layer, the others protect your users.

---

## 📚 Learning Resources

### Ruby & Rails Fundamentals

**Books:**
- [Ruby on Rails Tutorial](https://www.railstutorial.org/) by Michael Hartl (FREE online)
- [Agile Web Development with Rails 7](https://pragprog.com/titles/rails7/agile-web-development-with-rails-7/)
- [The Rails 8 Way](https://leanpub.com/therails8way) (when released)

**Courses:**
- [GoRails](https://gorails.com/) - Excellent video tutorials
- [Drifting Ruby](https://www.driftingruby.com/) - Weekly screencasts
- [Rails Guides](https://guides.rubyonrails.org/) - Official documentation

**Podcasts:**
- [The Ruby on Rails Podcast](https://www.therubyonrailspodcast.com/)
- [Remote Ruby](https://remoteruby.com/)

---

### API Design & Documentation

**Resources:**
- [RESTful API Design Best Practices](https://stackoverflow.blog/2020/03/02/best-practices-for-rest-api-design/)
- [OpenAPI 3.0 Tutorial](https://swagger.io/docs/specification/about/)
- [API Security Checklist](https://github.com/shieldfy/API-Security-Checklist)

**Tools:**
- [Postman](https://www.postman.com/) - API testing
- [Bruno](https://www.usebruno.com/) - Open-source Postman alternative
- [Insomnia](https://insomnia.rest/) - API client

---

### Testing & TDD

**Books:**
- [Everyday Rails Testing with RSpec](https://leanpub.com/everydayrailsrspec)
- [The RSpec Book](https://pragprog.com/titles/achbd/the-rspec-book/)

**Resources:**
- [RSpec Documentation](https://rspec.info/)
- [Better Specs](https://www.betterspecs.org/) - RSpec best practices
- [Test-Driven Development with Rails](https://thoughtbot.com/upcase/test-driven-rails)

---

### Security

**Resources:**
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [Brakeman Scanner](https://brakemanscanner.org/) - Security tool we use

**Key Topics to Study:**
- SQL Injection prevention
- XSS (Cross-Site Scripting) protection
- CSRF (Cross-Site Request Forgery) protection
- Session fixation attacks
- Password hashing (bcrypt)

---

### Next.js + Rails Integration

**Resources:**
- [Next.js Documentation](https://nextjs.org/docs)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [openapi-typescript](https://github.com/drwpow/openapi-typescript) - Generate types from OpenAPI

**Example Projects:**
- [Rails + Next.js Starter](https://github.com/mscccc/rails-nextjs-starter)
- [Hotwire + React](https://github.com/thoughtbot/hotwire-example-template)

---

## 🚀 Next Steps

### Immediate Next Steps (For Junior Developer)

#### 1. **Understand the Authentication Flow** (1-2 hours)
- [ ] Read `AUTH_ARCHITECTURE.md` thoroughly
- [ ] Test the API endpoints in Swagger UI (`http://localhost:3000/api-docs`)
- [ ] Use Bruno/Postman to manually test the login flow
- [ ] Understand why we use HttpOnly cookies vs JWT

**Exercise:**
Try to break the authentication:
- What happens if you send a request without CSRF token?
- What happens if you send a request from an unauthorized origin?
- Can you access the session cookie from JavaScript? (You shouldn't be able to!)

---

#### 2. **Run the Test Suite** (30 minutes)
```bash
# Run all tests
bundle exec rspec

# View coverage report
open coverage/index.html

# Run linter
bundle exec rubocop
```

**Exercise:**
- Identify which parts of the code are NOT tested (look at coverage report)
- Pick one untested method and write a test for it
- Fix any RuboCop violations: `bundle exec rubocop -a`

---

#### 3. **Generate API Documentation** (15 minutes)
```bash
# Generate Swagger docs
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize

# View docs
open http://localhost:3000/api-docs
```

**Exercise:**
- Test each endpoint in Swagger UI
- Export the OpenAPI spec and import it into Postman
- Try generating TypeScript types: `npx openapi-typescript http://localhost:3000/api-docs/v1/swagger.yaml -o types/api.ts`

---

#### 4. **Build Your First API Endpoint** (2-3 hours)

**Goal:** Create a `GET /api/v1/workouts` endpoint

**Steps:**
1. Create the controller:
```ruby
# app/controllers/api/v1/workouts_controller.rb
class Api::V1::WorkoutsController < Api::V1::BaseController
  def index
    workouts = current_user.workouts.order(performed_at: :desc)
    render json: { data: workouts }, status: :ok
  end
end
```

2. Add the route:
```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    # ... existing routes ...
    resources :workouts, only: [:index]
  end
end
```

3. Write the Rswag spec (follow the pattern in `spec/requests/api/v1/auth_swagger_spec.rb`)

4. Generate docs: `RAILS_ENV=test bundle exec rake rswag:specs:swaggerize`

5. Test in Swagger UI!

---

### Medium-Term Goals (Next 2-4 Weeks)

#### 1. **Complete Workout API** (Week 1-2)
- [ ] `POST /api/v1/workouts` - Create workout
- [ ] `GET /api/v1/workouts/:id` - Get workout details
- [ ] `PATCH /api/v1/workouts/:id` - Update workout
- [ ] `DELETE /api/v1/workouts/:id` - Delete workout
- [ ] Write tests for all endpoints
- [ ] Document with Rswag

**Learning Focus:**
- RESTful API design
- Strong parameters
- Error handling
- JSON serialization

---

#### 2. **Build Next.js Frontend** (Week 2-3)
- [ ] Set up Next.js project
- [ ] Generate TypeScript types from OpenAPI spec
- [ ] Implement login page
- [ ] Implement workout list page
- [ ] Handle CSRF tokens correctly
- [ ] Implement error handling

**Learning Focus:**
- Next.js App Router
- TypeScript
- Fetch API with credentials
- Cookie handling in browser

---

#### 3. **Improve Test Coverage** (Week 3-4)
- [ ] Get coverage to 60%+ (currently 38%)
- [ ] Add tests for edge cases
- [ ] Add tests for error scenarios
- [ ] Set up GitHub Actions CI/CD
- [ ] Integrate SonarCloud

**Learning Focus:**
- Test-Driven Development (TDD)
- RSpec best practices
- CI/CD pipelines
- Code quality metrics

---

### Long-Term Goals (Next 2-3 Months)

#### 1. **Advanced Features**
- [ ] Pagination for workout lists
- [ ] Filtering and search
- [ ] File uploads (workout photos)
- [ ] Real-time updates (Action Cable)
- [ ] Background jobs (Solid Queue)

#### 2. **Performance Optimization**
- [ ] Add database indexes
- [ ] Implement caching (Solid Cache)
- [ ] Optimize N+1 queries
- [ ] Add request rate limiting
- [ ] Implement API versioning

#### 3. **Production Deployment**
- [ ] Set up staging environment
- [ ] Configure production database
- [ ] Set up error tracking (Sentry)
- [ ] Configure monitoring (New Relic/Datadog)
- [ ] Set up automated backups
- [ ] Deploy to production (Heroku/Render/Fly.io)

---

## 🐛 Troubleshooting

### Common Issues

#### Issue: Tests fail with "Ruby version mismatch"

**Solution:**
```bash
# Ensure RVM is loaded
source ~/.zshrc

# Verify Ruby version
ruby -v  # Should show 3.2.6

# If not, use RVM
rvm use 3.2.6

# Run tests again
bundle exec rspec
```

---

#### Issue: Swagger UI shows "Failed to fetch"

**Solution:**
1. Ensure Rails server is running: `bin/dev`
2. Check `swagger/v1/swagger.yaml` exists
3. Regenerate docs: `RAILS_ENV=test bundle exec rake rswag:specs:swaggerize`
4. Clear browser cache and refresh

---

#### Issue: CORS errors in browser console

**Solution:**
1. Check `ALLOWED_ORIGINS` environment variable is set
2. Verify `config/initializers/cors.rb` includes your frontend origin
3. Ensure you're sending `credentials: 'include'` in fetch requests
4. Check browser console for specific CORS error message

---

#### Issue: CSRF token invalid

**Solution:**
1. Get fresh token: `GET /api/v1/csrf`
2. Read token from `CSRF-TOKEN` cookie
3. Send token in `X-CSRF-Token` header
4. Ensure cookies are being sent (`credentials: 'include'`)

---

## 📖 Documentation Index

All documentation is organized by topic:

| Document | Purpose | When to Read |
|----------|---------|--------------|
| `README.md` | Project overview and setup | First time setup |
| `SETUP_GUIDE.md` (this file) | Architecture and learning guide | Understanding the "why" |
| `QUICK_REFERENCE.md` | Common commands and workflows | Daily development (bookmark!) |
| `AUTH_ARCHITECTURE.md` | Authentication deep-dive | Building auth features |
| `API_DOCUMENTATION_GUIDE.md` | How to document APIs with Rswag | Adding new endpoints |
| `CODE_QUALITY.md` | Testing and linting guide | Writing tests |
| `DEVELOPMENT.md` | Development workflow | Daily development |
| `MIGRATIONS_GUIDE.md` | Database migration patterns | Working with database |
| `STYLING_UPDATE.md` | Design system and colors | Frontend styling |
| `.cursorrules` | Coding standards | Before writing code |

---

## 🎯 Key Takeaways

### What Makes This Setup Professional?

1. **Security First**
   - HttpOnly cookies prevent XSS
   - CSRF tokens prevent unauthorized requests
   - CORS whitelist prevents unauthorized origins
   - bcrypt for password hashing

2. **Documentation as Code**
   - API docs generated from tests
   - Always in sync with implementation
   - TypeScript types auto-generated

3. **Quality Assurance**
   - Automated testing (RSpec)
   - Code coverage tracking (SimpleCov)
   - Style enforcement (RuboCop)
   - Security scanning (Brakeman)

4. **Developer Experience**
   - Interactive API testing (Swagger UI)
   - Clear error messages
   - Comprehensive documentation
   - Consistent coding standards

---

## 🤝 Getting Help

### When You're Stuck

1. **Check the docs** - We've documented everything for a reason!
2. **Read the error message** - Rails errors are usually very helpful
3. **Use the Rails console** - `bundle exec rails c` lets you test code interactively
4. **Check the logs** - `tail -f log/development.log`
5. **Google the error** - Someone has probably solved it before
6. **Ask specific questions** - "Why does X happen when I do Y?" is better than "It doesn't work"

### Useful Commands for Debugging

```bash
# Rails console (test code interactively)
bundle exec rails c

# Check routes
bundle exec rails routes | grep api

# Database console
bundle exec rails dbconsole

# View logs in real-time
tail -f log/development.log

# Check what's running
lsof -i :3000  # Check if port 3000 is in use
```

---

## 🌟 Final Thoughts

You now have a **production-ready Rails API** with:
- ✅ Secure authentication
- ✅ Auto-generated documentation
- ✅ Comprehensive testing
- ✅ Code quality tools
- ✅ Clear architecture

**The best way to learn is by doing.** Start with the "Next Steps" section and build features incrementally. Don't try to understand everything at once—focus on one concept at a time.

**Remember:** Every expert was once a beginner. The Rails community is welcoming and helpful. Don't be afraid to ask questions!

---

**Happy coding! 🚀**

*Last updated: November 2025*

