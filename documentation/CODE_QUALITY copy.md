# 📊 Code Quality Setup Guide

This guide explains how to use the code quality tools integrated into VitalForge.

## 🎯 Overview

We use three main tools for code quality:
1. **RSpec** - Automated testing
2. **SimpleCov** - Test coverage analysis
3. **RuboCop** - Ruby code linting (Rails Omakase style)
4. **SonarQube/SonarCloud** - Centralized code quality dashboard (optional)

---

## 🧪 Running Tests

### Run All Tests
```bash
bundle exec rspec
```

### Run Specific Test File
```bash
bundle exec rspec spec/requests/api/v1/auth_spec.rb
```

### Run Specific Test
```bash
bundle exec rspec spec/requests/api/v1/auth_spec.rb:24
```

### Test Output
- **Green**: All tests passed ✅
- **Red**: Tests failed ❌
- **Yellow**: Pending tests (marked with `xit` or `pending`)

---

## 📈 Test Coverage

### Viewing Coverage
After running `bundle exec rspec`, coverage is automatically generated.

**Coverage Report Location:**
- JSON: `coverage/coverage.json` (for SonarCloud)
- HTML: `coverage/index.html` (open in browser for visual report)

### Current Coverage
- **38.31% code coverage** (113 / 295 lines)

### Coverage Goals
- **Minimum**: 60% for production readiness
- **Target**: 80% for high-quality applications
- **Ideal**: 90%+ for critical business logic

### What to Test
✅ **DO Test:**
- Model validations
- Business logic methods
- API endpoints (request specs)
- Authentication/authorization flows
- Database constraints

❌ **DON'T Test:**
- Rails framework code
- Third-party gem internals
- Trivial getters/setters

---

## 🔍 RuboCop (Code Linting)

### Run RuboCop
```bash
bundle exec rubocop
```

### Auto-Fix Issues
```bash
bundle exec rubocop -a
```

### Generate JSON Report (for SonarCloud)
```bash
bundle exec rubocop --format json --out rubocop-result.json
```

### Configuration
We use **Rails Omakase** style guide (opinionated defaults by DHH).

**Config File:** `.rubocop.yml`

```yaml
# Omakase Ruby styling for Rails
inherit_gem: { rubocop-rails-omakase: rubocop.yml }

# Add custom overrides here if needed
```

### Common RuboCop Violations

#### 1. Line Too Long
```ruby
# ❌ Bad (>120 characters)
def some_method_with_a_really_long_name_that_exceeds_the_maximum_allowed_line_length_for_rubocop_omakase_style_guide
  # ...
end

# ✅ Good
def some_method_with_reasonable_name
  # ...
end
```

#### 2. Missing Frozen String Literal
```ruby
# ❌ Bad
# (no magic comment)

# ✅ Good
# frozen_string_literal: true
```

#### 3. Trailing Whitespace
```ruby
# ❌ Bad
def method_name  
  # Extra spaces after name
end

# ✅ Good
def method_name
  # No trailing spaces
end
```

---

## 🌐 SonarQube/SonarCloud Setup (Optional)

SonarCloud provides a centralized dashboard for code quality metrics.

### 1. Sign Up for SonarCloud
1. Go to [sonarcloud.io](https://sonarcloud.io)
2. Sign in with GitHub
3. Create a new organization (or use existing)
4. Add your repository

### 2. Get Your Project Key
SonarCloud will generate a project key like:
```
your-org_vital-forge-v1
```

### 3. Update `sonar-project.properties`
```properties
# Uncomment and update these lines:
sonar.projectKey=your-org_vital-forge-v1
sonar.organization=your-org
```

### 4. Get SonarCloud Token
1. Go to **My Account** → **Security** → **Generate Token**
2. Copy the token
3. Add to your CI/CD environment variables as `SONAR_TOKEN`

### 5. Run SonarCloud Scan
```bash
# Install SonarScanner (one-time)
brew install sonar-scanner

# Run scan
sonar-scanner \
  -Dsonar.projectKey=your-org_vital-forge-v1 \
  -Dsonar.organization=your-org \
  -Dsonar.host.url=https://sonarcloud.io \
  -Dsonar.token=YOUR_TOKEN_HERE
```

### 6. View Dashboard
Go to [sonarcloud.io/projects](https://sonarcloud.io/projects) to see:
- Code coverage %
- Code smells
- Bugs
- Security vulnerabilities
- Technical debt

---

## 🚀 CI/CD Integration (GitHub Actions)

### Example Workflow

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2.6
          bundler-cache: true
      
      - name: Setup Database
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        run: |
          bundle exec rails db:create
          bundle exec rails db:migrate
      
      - name: Run Tests
        run: bundle exec rspec
      
      - name: Run RuboCop
        run: bundle exec rubocop --format json --out rubocop-result.json
      
      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

---

## 📝 Best Practices

### 1. Run Tests Before Committing
```bash
# Add to your pre-commit hook
bundle exec rspec && bundle exec rubocop
```

### 2. Fix RuboCop Issues Incrementally
Don't try to fix all violations at once. Focus on:
1. Security issues first
2. Bugs second
3. Code smells third
4. Style issues last

### 3. Write Tests for New Features
**Test-Driven Development (TDD):**
1. Write a failing test
2. Write minimal code to pass
3. Refactor
4. Repeat

### 4. Review Coverage Reports
After adding features, check:
```bash
open coverage/index.html
```

Look for:
- Untested methods (red)
- Partially tested methods (yellow)
- Well-tested methods (green)

---

## 🛠 Troubleshooting

### SimpleCov Not Generating Coverage
**Problem:** No `coverage/` directory after running tests.

**Solution:**
1. Check `spec/spec_helper.rb` has SimpleCov configured
2. Ensure `simplecov` gem is installed: `bundle install`
3. Delete `tmp/cache` and re-run: `rm -rf tmp/cache && bundle exec rspec`

### RuboCop Fails with "Unknown Cop"
**Problem:** RuboCop doesn't recognize a cop name.

**Solution:**
1. Update RuboCop: `bundle update rubocop rubocop-rails-omakase`
2. Check `.rubocop.yml` for typos

### SonarCloud Scan Fails
**Problem:** "Project key not found" or authentication error.

**Solution:**
1. Verify `sonar.projectKey` matches SonarCloud
2. Check `SONAR_TOKEN` is valid and not expired
3. Ensure `coverage.json` and `rubocop-result.json` exist

### Tests Pass Locally But Fail in CI
**Problem:** Environment differences.

**Solution:**
1. Check Ruby version matches (`.ruby-version`)
2. Verify database is set up correctly in CI
3. Ensure environment variables are set
4. Check for time-zone or locale issues

---

## 📊 Code Quality Metrics

### Current Status
- **Test Coverage**: 38.31%
- **Tests**: 13 passing, 1 pending
- **RuboCop**: Check `rubocop-result.json` for violations

### Goals
- [ ] Increase coverage to 60%
- [ ] Fix all RuboCop security issues
- [ ] Add tests for all API endpoints
- [ ] Set up SonarCloud dashboard
- [ ] Add CI/CD pipeline

---

## 🎓 Learning Resources

### RSpec
- [RSpec Documentation](https://rspec.info/)
- [Better Specs](https://www.betterspecs.org/)
- [Everyday Rails Testing with RSpec](https://leanpub.com/everydayrailsrspec)

### RuboCop
- [RuboCop Documentation](https://docs.rubocop.org/)
- [Rails Omakase Style Guide](https://github.com/rails/rubocop-rails-omakase)

### SimpleCov
- [SimpleCov GitHub](https://github.com/simplecov-ruby/simplecov)

### SonarQube
- [SonarCloud Documentation](https://docs.sonarcloud.io/)

---

## 🚦 Quick Commands Reference

```bash
# Run all tests
bundle exec rspec

# Run tests with coverage
bundle exec rspec

# Run linter
bundle exec rubocop

# Auto-fix linting issues
bundle exec rubocop -a

# Generate reports for SonarCloud
bundle exec rspec  # Generates coverage/coverage.json
bundle exec rubocop --format json --out rubocop-result.json

# View coverage report
open coverage/index.html
```

---

**Happy Testing! 🎉**

