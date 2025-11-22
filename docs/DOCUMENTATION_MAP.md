# 📚 VitalForge Documentation Map

**A visual guide to all project documentation**

---

## 🗺 Documentation Structure

```
VitalForge Documentation
│
├─ 🎯 START HERE (New to the project?)
│  │
│  ├─ README.md
│  │  └─ Project overview, quick start, features
│  │
│  ├─ PROJECT_SUMMARY.md
│  │  └─ What we built, why we built it, key achievements
│  │
│  └─ SETUP_GUIDE.md
│     └─ Architecture, learning resources, next steps
│
├─ ⚡ DAILY REFERENCE (Bookmark these!)
│  │
│  ├─ QUICK_REFERENCE.md
│  │  └─ Common commands, workflows, debugging
│  │
│  └─ .cursorrules
│     └─ Coding standards and best practices
│
├─ 🏗 ARCHITECTURE (Deep dives)
│  │
│  ├─ AUTH_ARCHITECTURE.md
│  │  └─ Session auth, CORS, CSRF, security
│  │
│  ├─ DATABASE_SCHEMA.md
│  │  └─ Database design, relationships, indexes
│  │
│  └─ API_DOCUMENTATION_GUIDE.md
│     └─ How to document APIs with Rswag
│
├─ 🛠 DEVELOPMENT (Building features)
│  │
│  ├─ DEVELOPMENT.md
│  │  └─ Workflow, commands, troubleshooting
│  │
│  ├─ MIGRATIONS_GUIDE.md
│  │  └─ Database migration patterns
│  │
│  ├─ CODE_QUALITY.md
│  │  └─ Testing, linting, coverage
│  │
│  └─ STYLING_UPDATE.md
│     └─ Design system, colors, CSS
│
└─ 📊 GENERATED (Auto-updated)
   │
   ├─ swagger/v1/swagger.yaml
   │  └─ OpenAPI specification (from tests)
   │
   ├─ coverage/index.html
   │  └─ Test coverage report (from SimpleCov)
   │
   └─ rubocop-result.json
      └─ Linting report (from RuboCop)
```

---

## 🎯 Which Document Should I Read?

### I'm new to the project
**Start here:**
1. `README.md` - Get the project running
2. `PROJECT_SUMMARY.md` - Understand what we built
3. `SETUP_GUIDE.md` - Learn the architecture

---

### I need to build a feature
**Read these:**
1. `QUICK_REFERENCE.md` - Common commands
2. `DEVELOPMENT.md` - Development workflow
3. `API_DOCUMENTATION_GUIDE.md` - How to document it
4. `.cursorrules` - Coding standards

---

### I'm working on authentication
**Read these:**
1. `AUTH_ARCHITECTURE.md` - How auth works
2. `spec/requests/api/v1/auth_swagger_spec.rb` - Test examples
3. `CODE_QUALITY.md` - How to test it

---

### I'm working with the database
**Read these:**
1. `DATABASE_SCHEMA.md` - Schema design
2. `MIGRATIONS_GUIDE.md` - Migration patterns
3. `QUICK_REFERENCE.md` - Database commands

---

### I'm writing tests
**Read these:**
1. `CODE_QUALITY.md` - Testing guide
2. `spec/requests/api/v1/auth_spec.rb` - Test examples
3. `QUICK_REFERENCE.md` - Test commands

---

### I'm stuck with an error
**Read these:**
1. `QUICK_REFERENCE.md` - Debugging section
2. `DEVELOPMENT.md` - Troubleshooting
3. `SETUP_GUIDE.md` - Common issues

---

### I'm doing code review
**Read these:**
1. `.cursorrules` - Coding standards
2. `CODE_QUALITY.md` - Quality checklist
3. `PROJECT_SUMMARY.md` - Project philosophy

---

## 📖 Documentation by Topic

### Security
- `AUTH_ARCHITECTURE.md` - Authentication system
- `.cursorrules` - Security best practices
- `CODE_QUALITY.md` - Security scanning

### API Design
- `API_DOCUMENTATION_GUIDE.md` - Rswag documentation
- `swagger/v1/swagger.yaml` - OpenAPI spec
- `spec/requests/api/v1/auth_swagger_spec.rb` - Examples

### Testing
- `CODE_QUALITY.md` - Testing guide
- `spec/` - All test files
- `coverage/index.html` - Coverage report

### Database
- `DATABASE_SCHEMA.md` - Schema design
- `MIGRATIONS_GUIDE.md` - Migration patterns
- `db/schema.rb` - Current schema

### Frontend
- `STYLING_UPDATE.md` - Design system
- `app/assets/stylesheets/application.css` - CSS

### Deployment
- `README.md` - Deployment checklist
- `DEVELOPMENT.md` - Environment setup
- `.cursorrules` - Production best practices

---

## 🔄 Documentation Workflow

### When Adding a New Feature

```
1. Read relevant docs
   ├─ QUICK_REFERENCE.md (commands)
   ├─ DEVELOPMENT.md (workflow)
   └─ .cursorrules (standards)

2. Write the feature
   ├─ Follow coding standards
   ├─ Write tests first (TDD)
   └─ Document with Rswag

3. Update docs (if needed)
   ├─ Add to QUICK_REFERENCE.md if new command
   ├─ Update DATABASE_SCHEMA.md if schema changes
   └─ Update README.md if major feature

4. Generate docs
   ├─ Run: RAILS_ENV=test bundle exec rake rswag:specs:swaggerize
   ├─ Run: bundle exec rspec (generates coverage)
   └─ Run: bundle exec rubocop (generates linting report)

5. Verify
   ├─ Check http://localhost:3000/api-docs
   ├─ Check coverage/index.html
   └─ Check rubocop-result.json
```

---

## 📊 Documentation Statistics

### Total Documents: 15

**Start Here:** 3 files
- README.md
- PROJECT_SUMMARY.md
- SETUP_GUIDE.md

**Daily Reference:** 2 files
- QUICK_REFERENCE.md
- .cursorrules

**Architecture:** 3 files
- AUTH_ARCHITECTURE.md
- DATABASE_SCHEMA.md
- API_DOCUMENTATION_GUIDE.md

**Development:** 4 files
- DEVELOPMENT.md
- MIGRATIONS_GUIDE.md
- CODE_QUALITY.md
- STYLING_UPDATE.md

**Generated:** 3 files
- swagger/v1/swagger.yaml
- coverage/index.html
- rubocop-result.json

---

## 🎓 Learning Path

### Week 1: Foundations
**Read:**
1. README.md
2. PROJECT_SUMMARY.md
3. SETUP_GUIDE.md
4. QUICK_REFERENCE.md

**Do:**
- Get project running locally
- Test all API endpoints in Swagger UI
- Run the test suite
- Understand authentication flow

---

### Week 2: Building Features
**Read:**
1. DEVELOPMENT.md
2. API_DOCUMENTATION_GUIDE.md
3. CODE_QUALITY.md
4. .cursorrules

**Do:**
- Build your first endpoint
- Write tests for it
- Document with Rswag
- Do a code review

---

### Week 3: Database & Migrations
**Read:**
1. DATABASE_SCHEMA.md
2. MIGRATIONS_GUIDE.md
3. QUICK_REFERENCE.md (database section)

**Do:**
- Create a migration
- Add an index
- Test rollback
- Update schema docs

---

### Week 4: Advanced Topics
**Read:**
1. AUTH_ARCHITECTURE.md
2. STYLING_UPDATE.md
3. All remaining docs

**Do:**
- Understand security layers
- Customize the design
- Improve test coverage
- Deploy to staging

---

## 🔍 Quick Search

### Find by Keyword

**Authentication:**
- AUTH_ARCHITECTURE.md
- app/controllers/api/v1/sessions_controller.rb
- spec/requests/api/v1/auth_spec.rb

**CORS:**
- AUTH_ARCHITECTURE.md
- config/initializers/cors.rb

**CSRF:**
- AUTH_ARCHITECTURE.md
- app/controllers/application_controller.rb

**Testing:**
- CODE_QUALITY.md
- spec/
- coverage/

**API Documentation:**
- API_DOCUMENTATION_GUIDE.md
- swagger/v1/swagger.yaml
- spec/requests/api/v1/auth_swagger_spec.rb

**Database:**
- DATABASE_SCHEMA.md
- MIGRATIONS_GUIDE.md
- db/schema.rb

**Styling:**
- STYLING_UPDATE.md
- app/assets/stylesheets/application.css

**Commands:**
- QUICK_REFERENCE.md
- DEVELOPMENT.md

---

## 📝 Documentation Maintenance

### When to Update Docs

**Always update:**
- ✅ When adding new API endpoints → Update Rswag specs
- ✅ When changing database schema → Update DATABASE_SCHEMA.md
- ✅ When adding new commands → Update QUICK_REFERENCE.md
- ✅ When changing auth flow → Update AUTH_ARCHITECTURE.md

**Sometimes update:**
- 🤔 When adding minor features → Consider updating README.md
- 🤔 When changing workflow → Consider updating DEVELOPMENT.md
- 🤔 When adding new tools → Consider updating CODE_QUALITY.md

**Never update:**
- ❌ Generated files (swagger.yaml, coverage, rubocop-result.json)
- ❌ These update automatically from tests/linting

---

## 🎯 Documentation Goals

### Current State ✅
- [x] Comprehensive coverage of all major topics
- [x] Clear learning path for junior developers
- [x] Quick reference for daily tasks
- [x] Auto-generated API docs
- [x] Architecture explanations

### Future Goals 🔄
- [ ] Video tutorials for setup
- [ ] Animated diagrams for auth flow
- [ ] Blog posts sharing learnings
- [ ] Contribution guidelines
- [ ] Onboarding checklist

---

## 🤝 Contributing to Documentation

### Documentation Standards

**Good documentation:**
- ✅ Explains WHY, not just WHAT
- ✅ Includes examples
- ✅ Has clear structure
- ✅ Uses diagrams when helpful
- ✅ Stays up to date

**Bad documentation:**
- ❌ Only explains WHAT (code already does that)
- ❌ No examples
- ❌ Wall of text
- ❌ Gets outdated
- ❌ Assumes too much knowledge

### Before Submitting PR

**Check:**
1. ✅ Did I update relevant docs?
2. ✅ Did I add examples?
3. ✅ Did I explain WHY?
4. ✅ Did I test the commands?
5. ✅ Did I check for typos?

---

## 📚 External Resources

### Official Documentation
- [Rails Guides](https://guides.rubyonrails.org/)
- [Ruby Documentation](https://ruby-doc.org/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [RSpec Documentation](https://rspec.info/)

### Learning Resources
- [GoRails](https://gorails.com/)
- [Drifting Ruby](https://www.driftingruby.com/)
- [The Ruby on Rails Tutorial](https://www.railstutorial.org/)

### Tools
- [Swagger Editor](https://editor.swagger.io/)
- [Postman](https://www.postman.com/)
- [Bruno](https://www.usebruno.com/)

---

**💡 Tip:** Bookmark this page to quickly find the right documentation!

*Last updated: November 2025*

