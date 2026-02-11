# Hybrid Docker Approach - Migration Complete

## What Changed

We've migrated from a full Docker setup to a **hybrid approach** where:
- ✅ PostgreSQL and Redis run in Docker
- ✅ Rails, Sidekiq, and the Next.js UI run natively on your Mac

## Benefits

1. **Faster Development**
   - Native Rails has instant hot-reloading
   - No Docker file system overhead
   - Better Rails console performance

2. **Less Memory Usage**
   - Only database services in Docker (~500 MB)
   - Previously: Full stack in Docker (~2-3 GB)

3. **Same Deployment**
   - Dockerfile still exists for Railway
   - No changes needed for production

4. **No Local Installs**
   - PostgreSQL and Redis managed by Docker
   - Don't need Homebrew postgres/redis

## Files Updated

### Documentation
- **README.md** - Updated prerequisites and getting started guide
- **QUICK_REFERENCE.md** - Added Docker commands and hybrid workflow
- **.env.example** - Added comments about Docker setup
- **docker-compose.yml** - Added header explaining hybrid approach

### Configuration
- **config/database.yml** - Already configured correctly (DATABASE_HOST=localhost works with Docker port forwarding)

## Daily Workflow

**Quick start (one-liner):**
```bash
docker-compose up -d db redis && bin/dev
```

**Individual steps:**
### Starting Work
```bash
# Terminal 1: Start Docker services
docker-compose up -d db redis

# Terminal 2: Start Rails
bin/dev

# Terminal 3: Start UI (optional)
cd ../vital-forge-ui-v1
npm run dev
```

### Stopping Work
```bash
# Stop Rails (Ctrl+C)
# Stop Docker (optional - uses minimal resources when idle)
docker-compose stop
```

## What You DON'T Use Anymore

You no longer need to run:
- ❌ `docker-compose up web` (Rails runs natively now)
- ❌ `docker-compose exec web rails console` (just use `bundle exec rails console`)
- ❌ `docker-compose restart web` (just Ctrl+C and restart Rails)

## What You DO Use

Docker commands you'll use:
- ✅ `docker-compose up -d db redis` - Start infrastructure
- ✅ `docker-compose stop` - Stop when done
- ✅ `docker-compose logs -f db redis` - View logs
- ✅ `docker-compose ps` - Check status
- ✅ `docker-compose exec db psql -U postgres` - Access database

Native Rails commands:
- ✅ `bin/dev` - Start Rails server
- ✅ `bundle exec rails console` - Rails console
- ✅ `bundle exec rspec` - Run tests
- ✅ `bin/rails db:migrate` - Run migrations

## Railway Deployment

**No changes needed!** Railway will still use your Dockerfile for production deployment.

The hybrid approach is purely for local development speed and comfort.

## Next Steps

1. Stop any running Docker containers:
   ```bash
   docker-compose down
   ```

2. Start just the infrastructure:
   ```bash
   docker-compose up -d db redis
   ```

3. Start Rails natively:
   ```bash
   bin/dev
   ```

4. Verify it works by visiting http://localhost:3000

5. Check the AI feature is disabled:
   - Ensure `ENABLE_AI_FEATURES=false` in your `.env`
   - Restart Rails if needed
   - Create a test user and check logs for "Skipping AI feedback generation"

## Troubleshooting

**"Can't connect to database"**
```bash
# Check Docker is running
docker-compose ps

# Should show db and redis as "healthy"
# If not, start them:
docker-compose up -d db redis
```

**"Port 5432 already in use"**
```bash
# You might have local Postgres running
brew services stop postgresql@14

# Or check what's using the port
lsof -i :5432
```

**Environment variables not loading**
```bash
# Rails needs to be restarted to pick up .env changes
# Ctrl+C to stop, then bin/dev to restart
```

## Questions?

- See **README.md** for the complete getting started guide
- See **QUICK_REFERENCE.md** for common commands
- See **DOCKER_SETUP_MAC.md** for full Docker documentation (if you ever want to run everything in Docker)
