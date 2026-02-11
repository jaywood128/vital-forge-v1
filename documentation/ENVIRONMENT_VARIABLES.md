# Environment Variables Setup

## Overview

VitalForge uses environment variables to manage configuration and secrets. This keeps sensitive information out of version control.

## Quick Setup

```bash
# 1. Copy the example file
cp .env.example .env

# 2. Edit with your values
nano .env  # or use your preferred editor

# 3. Never commit .env to git!
# (It's already in .gitignore)
```

## Required Environment Variables

### Database Configuration

```bash
DATABASE_HOST=localhost          # Use 'db' if running Rails in Docker
DATABASE_PORT=5432
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your_secure_password_here
```

### API Keys

#### OpenAI API
- **Purpose:** AI-powered workout feedback
- **Get it:** https://platform.openai.com/api-keys
- **Variable:** `OPENAI_API_KEY=sk-proj-...`

#### Honeybadger
- **Purpose:** Error monitoring and alerting
- **Get it:** https://app.honeybadger.io/
- **Variable:** `HONEYBADGER_API_KEY=hbp_...`
- **Environment:** Set to `development`, `staging`, or `production`

### Staging Database (Optional)

Only needed if you're deploying to staging:

```bash
STAGING_DATABASE_URL=postgresql://user:pass@host:5432/database
```

## File Structure

```
vital-forge-v1/
├── .env              # Your actual secrets (NOT in git)
├── .env.example      # Template (committed to git)
└── .gitignore        # Ensures .env is never committed
```

## Security Best Practices

### ✅ DO

- ✅ Copy `.env.example` to `.env` for your local setup
- ✅ Store production secrets in your deployment platform (Railway, Heroku, etc.)
- ✅ Use strong, unique passwords
- ✅ Rotate API keys regularly
- ✅ Keep `.env.example` updated when adding new variables

### ❌ DON'T

- ❌ Commit `.env` to git
- ❌ Share `.env` file via Slack/email
- ❌ Use the same password across environments
- ❌ Include real API keys in documentation
- ❌ Store secrets in code comments

## Docker Setup

When using Docker, environment variables are automatically loaded from `.env`:

```yaml
# docker-compose.yml
services:
  web:
    environment:
      DATABASE_PASSWORD: ${DATABASE_PASSWORD}
      OPENAI_API_KEY: ${OPENAI_API_KEY}
      # etc.
```

Docker Compose reads `.env` automatically and substitutes `${VAR}` references.

## Deployment

### Railway

Railway automatically detects `.env.example` and prompts you to set values in their dashboard.

1. Push your code to Railway
2. Go to Variables tab
3. Railway shows all variables from `.env.example`
4. Fill in your production values

### Other Platforms

For Heroku, Render, or other platforms:

```bash
# Set environment variables via CLI
heroku config:set OPENAI_API_KEY=sk-proj-...
heroku config:set DATABASE_PASSWORD=...

# Or use their web dashboard
```

## Troubleshooting

### "Database connection failed"

Check your `.env` file:
```bash
# Verify file exists
ls -la .env

# Check DATABASE_PASSWORD is set
grep DATABASE_PASSWORD .env
```

### "Missing API key" errors

```bash
# Check all required keys are set
grep -E "OPENAI_API_KEY|HONEYBADGER_API_KEY" .env
```

### Environment not loading

```bash
# Restart your server after changing .env
# Docker:
docker-compose restart web

# Local:
# Stop the server (Ctrl+C) and restart with bin/dev
```

## Adding New Environment Variables

When you add a new environment variable:

1. **Update `.env.example`** with placeholder value
2. **Update this documentation** with purpose and how to get it
3. **Update relevant config files** (docker-compose.yml, etc.)
4. **Notify your team** to update their local `.env`

Example:
```bash
# .env.example
NEW_SERVICE_API_KEY=your_new_service_key_here
```

## Related Documentation

- [Docker Setup Guide](DOCKER_SETUP_MAC.md) - Docker environment setup
- [Setup Guide](SETUP_GUIDE.md) - Complete project setup
- [README](../README.md) - Quick start guide
