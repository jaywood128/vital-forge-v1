# 🐳 Running VitalForge with Docker on macOS

Complete guide for setting up and running VitalForge using Docker on macOS.

---

## 📋 Prerequisites

### 1. Install Docker Desktop for Mac

**Download and Install:**
```bash
# Option 1: Download from website
# Visit: https://www.docker.com/products/docker-desktop/

# Option 2: Install via Homebrew
brew install --cask docker
```

**Start Docker Desktop:**
- Open Docker Desktop from Applications
- Wait for Docker to fully start (whale icon in menu bar should be steady)
- Verify installation:

```bash
docker --version
docker-compose --version
```

Expected output:
```
Docker version 24.x.x or higher
Docker Compose version v2.x.x or higher
```

### 2. Install Node.js (for UI)

```bash
# Install Node Version Manager (nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Restart terminal or run:
source ~/.zshrc

# Install Node.js LTS (v20 or v22)
nvm install --lts
nvm use --lts

# Verify
node --version  # Should show v20.x.x or v22.x.x
npm --version
```

---

## 🚀 Initial Setup

**One-liner setup (after .env is configured):**
```bash
docker-compose up -d db redis && bundle install && bin/rails db:prepare && bin/rails db:seed
```

**Step-by-step:**

### Step 1: Clone and Navigate

```bash
cd /Users/johnathonwood/dev/vital-forge-v1-combined-workspace/vital-forge-v1
```

### Step 2: Set Up Environment Variables

**First time setup - Create your `.env` file:**

```bash
# Copy the example file
cp .env.example .env

# Edit with your actual values
nano .env
# or use your preferred editor: code .env, vim .env, etc.
```

**Required values in `.env`:**

```bash
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your_secure_postgres_password_here

# Get your OpenAI API key from: https://platform.openai.com/api-keys
OPENAI_API_KEY=sk-proj-your_openai_api_key_here

# Get your Honeybadger key from: https://app.honeybadger.io/
HONEYBADGER_API_KEY=hbp_your_honeybadger_api_key_here
HONEYBADGER_ENV=development
```

**Important:** 
- ✅ `.env.example` is committed to git (template for team)
- ❌ `.env` is in `.gitignore` (never commit your actual secrets!)
- 🔑 Get your API keys from the respective service dashboards

### Step 3: Start Docker Containers

```bash
# Start all services (DB, Redis, Web, Sidekiq)
docker-compose up -d

# Or with build (first time or after Gemfile changes)
docker-compose up --build -d

# With pgAdmin (database dashboard)
docker-compose --profile tools up -d
```

**What this does:**
- Creates and starts PostgreSQL container (port 5432)
- Creates and starts Redis container (port 6379)
- Builds Rails image from Dockerfile
- Starts Rails web server (port 3000)
- Starts Sidekiq background worker
- (Optional) Starts pgAdmin on port 5050 when using `--profile tools`

### Step 4: Create and Migrate Databases

**First time only:**
```bash
# Create all databases and run migrations
docker-compose exec web bin/rails db:prepare
```

This creates:
- `vital_forge_v1_development` (primary)
- `vital_forge_v1_development_cache`
- `vital_forge_v1_development_queue`
- `vital_forge_v1_development_cable`

### Step 5: Verify Everything is Running

```bash
# Check container status
docker-compose ps

# Should show:
# vital-forge-v1-db-1       running (healthy)   0.0.0.0:5432->5432/tcp
# vital-forge-v1-redis-1    running (healthy)   0.0.0.0:6379->6379/tcp
# vital-forge-v1-web-1      running             0.0.0.0:3000->3000/tcp
# vital-forge-v1-sidekiq-1  running

# Check logs
docker-compose logs -f web
```

### Step 6: Seed Data (Optional)

```bash
# Add sample data
docker-compose exec web bin/rails db:seed
```

---

## 🎯 Accessing Your Application

| Service | URL | Description |
|---------|-----|-------------|
| **Rails API** | http://localhost:3000 | Backend API server |
| **Swagger UI** | http://localhost:3000/api-docs | API documentation |
| **OpenAPI Spec** | http://localhost:3000/openapi/v1/swagger.yaml | Raw API spec |
| **pgAdmin** | http://localhost:5050 | Database GUI (with `--profile tools`) |

---

## 🔧 Common Commands

### Starting & Stopping

```bash
# Start all services
docker-compose up

# Start in background (detached mode)
docker-compose up -d

# Start with pgAdmin (database dashboard at localhost:5050)
docker-compose --profile tools up -d

# Start with specific services only
docker-compose up db redis

# Stop all services (data preserved)
docker-compose down

# Stop and remove volumes (destroys all data!)
docker-compose down -v

# Restart a specific service
docker-compose restart web
```

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f sidekiq

# Last 100 lines
docker-compose logs --tail=100 web
```

### Database Commands

```bash
# Rails console
docker-compose exec web bin/rails console

# Run migrations
docker-compose exec web bin/rails db:migrate

# Rollback migration
docker-compose exec web bin/rails db:rollback

# Reset database (destroys data!)
docker-compose exec web bin/rails db:reset

# Access PostgreSQL directly
docker-compose exec db psql -U postgres

# List all databases
docker-compose exec db psql -U postgres -l

# Backup database
docker-compose exec db pg_dump -U postgres vital_forge_v1_development > backup.sql

# Restore database
docker-compose exec -T db psql -U postgres vital_forge_v1_development < backup.sql
```

### Rails Commands

```bash
# Run any Rails command
docker-compose exec web bin/rails [command]

# Examples:
docker-compose exec web bin/rails routes
docker-compose exec web bin/rails db:seed
docker-compose exec web bin/rails test
docker-compose exec web bin/rails rswag:specs:swaggerize

# Run rake tasks
docker-compose exec web bin/rails test:weekly_email
docker-compose exec web bin/rails test:openai
```

### Bundle Commands

```bash
# Install new gems after Gemfile changes
docker-compose exec web bundle install

# Or rebuild the image
docker-compose up --build web

# Update gems
docker-compose exec web bundle update
```

### Debugging

```bash
# Access container shell
docker-compose exec web bash

# Inside container, you can run:
# - ls
# - cat config/database.yml
# - bundle exec rails console
# - etc.

# View environment variables
docker-compose exec web env

# Check disk usage
docker system df

# Clean up old images/containers
docker system prune -a
```

---

## 🗄️ Using pgAdmin (Database GUI)

### Option 1: Docker pgAdmin (Recommended)

**Start Docker with pgAdmin included:**
```bash
# Stop current containers if running
docker-compose down

# Start with pgAdmin (note the --profile tools flag)
docker-compose --profile tools up -d
```

**Access pgAdmin:**
1. Open http://localhost:5050
2. Login:
   - Email: `admin@vitalforge.local`
   - Password: `admin`

**Connect to Database:**
1. Right-click "Servers" → "Register" → "Server"
2. **General Tab:**
   - Name: `VitalForge Docker`
3. **Connection Tab:**
   - Host: `db` (important! use Docker service name)
   - Port: `5432`
   - Database: `postgres`
   - Username: `postgres`
   - Password: `[use password from your .env file]`
   - Save password: ✓

### Option 2: Local pgAdmin (If Installed)

If you have pgAdmin installed on your Mac:

**Connect to Database:**
- Host: `localhost` (or `127.0.0.1`)
- Port: `5432`
- Database: `postgres`
- Username: `postgres`
- Password: `[use password from your .env file]`

---

## 💡 Development Workflows

### Workflow 1: Full Docker (All Services)

**Best for:** Matching production environment exactly

```bash
# Start everything
docker-compose up

# View API docs
open http://localhost:3000/api-docs

# Make changes to code (hot reloading works via volumes)
# Check logs
docker-compose logs -f web
```

### Workflow 2: Hybrid (Recommended for Performance)

**Best for:** Fast development with hot-reloading

```bash
# Terminal 1: Start infrastructure only
cd vital-forge-v1
docker-compose up db redis

# Terminal 2: Run Rails locally
cd vital-forge-v1
bin/dev

# Terminal 3: Run Sidekiq locally (if needed)
cd vital-forge-v1
bundle exec sidekiq

# Terminal 4: Run Next.js UI
cd ../vital-forge-ui-v1
npm install
npm run dev
```

**Access:**
- UI: http://localhost:3001
- API: http://localhost:3000

### Workflow 3: Full Docker + Local UI

**Best for:** Testing with Docker backend

```bash
# Terminal 1: Docker backend
cd vital-forge-v1
docker-compose up

# Terminal 2: Local UI
cd vital-forge-ui-v1
npm run dev
```

---

## 🐛 Troubleshooting

### "Cannot connect to Docker daemon"

```bash
# Make sure Docker Desktop is running
open -a Docker

# Wait for whale icon to be steady in menu bar
```

### "Port already in use"

```bash
# Find process using port
lsof -ti:3000

# Kill process
kill -9 $(lsof -ti:3000)

# Or use different ports in docker-compose.yml
```

### "Database does not exist"

```bash
# Create databases
docker-compose exec web bin/rails db:create
docker-compose exec web bin/rails db:migrate

# Or use db:prepare (does everything)
docker-compose exec web bin/rails db:prepare
```

### "Failed to build image"

```bash
# Clean rebuild
docker-compose down
docker-compose build --no-cache
docker-compose up
```

### "Bundle install errors"

```bash
# Delete bundle cache and rebuild
docker-compose down
docker volume rm vital-forge-v1_bundle_cache
docker-compose up --build
```

### "Redis connection refused"

```bash
# Check Redis is running
docker-compose ps redis

# Check Redis health
docker-compose exec redis redis-cli ping
# Should return: PONG

# Restart Redis
docker-compose restart redis
```

### "Sidekiq not processing jobs"

```bash
# Check Sidekiq logs
docker-compose logs -f sidekiq

# Restart Sidekiq
docker-compose restart sidekiq

# Check Redis connection
docker-compose exec web bin/rails console
# In console: Sidekiq.redis { |c| c.ping }
```

### "Out of disk space"

```bash
# Check Docker disk usage
docker system df

# Clean up
docker system prune -a --volumes

# This removes:
# - All stopped containers
# - All unused images
# - All unused volumes (BE CAREFUL - this deletes data!)
```

### Container keeps restarting

```bash
# Check logs for errors
docker-compose logs web

# Common issues:
# 1. Database not ready - wait for health check
# 2. Missing environment variables - check .env
# 3. Port conflict - change ports
```

---

## 📦 Data Persistence

### Your Data is Persistent! ✅

Docker uses **named volumes** which persist across restarts:

```yaml
volumes:
  postgres_data:    # PostgreSQL data - PERSISTS
  bundle_cache:     # Ruby gems - PERSISTS
  redis_data:       # Redis data - PERSISTS
```

**What this means:**
- ✅ `docker-compose down` → Data preserved
- ✅ `docker-compose up` → Data still there
- ✅ Restart computer → Data still there
- ❌ `docker-compose down -v` → Data DESTROYED

### View Your Volumes

```bash
# List volumes
docker volume ls | grep vital-forge

# Inspect volume
docker volume inspect vital-forge-v1_postgres_data

# See volume location on disk
docker volume inspect vital-forge-v1_postgres_data | grep Mountpoint
```

### Backup Your Data

```bash
# Backup PostgreSQL
docker-compose exec db pg_dumpall -U postgres > backup_$(date +%Y%m%d).sql

# Restore
docker-compose exec -T db psql -U postgres < backup_20260206.sql
```

### Reset to Fresh State

```bash
# DANGER: This deletes ALL data!
docker-compose down -v
docker-compose up --build -d
docker-compose exec web bin/rails db:prepare
docker-compose exec web bin/rails db:seed
```

---

## 🔄 Updating Dependencies

### After Gemfile Changes

```bash
# Option 1: Install in running container
docker-compose exec web bundle install

# Option 2: Rebuild image (recommended)
docker-compose down
docker-compose up --build
```

### After Dockerfile Changes

```bash
# Force rebuild
docker-compose build --no-cache
docker-compose up
```

### After package.json Changes (UI)

```bash
cd vital-forge-ui-v1
npm install
```

---

## 📊 Performance Tips for Mac

Docker on Mac can be slower due to file system virtualization. Here are optimizations:

### 1. Use Named Volumes (Already Done ✅)

Your docker-compose.yml already uses named volumes for gems:
```yaml
volumes:
  - bundle_cache:/usr/local/bundle  # Fast!
```

### 2. Exclude node_modules

If you add UI to docker-compose, use:
```yaml
volumes:
  - ../vital-forge-ui-v1:/app
  - /app/node_modules  # Exclude from sync
```

### 3. Allocate More Resources

**Docker Desktop Settings:**
- Open Docker Desktop → Settings → Resources
- Recommended for Rails:
  - CPUs: 4+
  - Memory: 8 GB+
  - Swap: 2 GB
  - Disk: 60 GB+

### 4. Use Hybrid Workflow

For fastest development, run Rails/Next.js locally, Docker for DB/Redis only.

---

## 🎓 Next Steps

1. **Generate Swagger docs:**
   ```bash
   docker-compose exec web bin/rails rswag:specs:swaggerize
   open http://localhost:3000/api-docs
   ```

2. **Start UI development:**
   ```bash
   cd ../vital-forge-ui-v1
   npm install
   npm run dev
   open http://localhost:3001
   ```

3. **Explore documentation:**
   - `documentation/API_DOCUMENTATION_GUIDE.md` - API docs with Rswag
   - `documentation/SETUP_GUIDE.md` - Full project setup
   - `documentation/README.md` - Documentation index

---

## 📚 Useful Docker Commands Reference

```bash
# View all running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View images
docker images

# Remove stopped containers
docker container prune

# Remove unused images
docker image prune -a

# View networks
docker network ls

# View volumes
docker volume ls

# Complete cleanup (CAREFUL!)
docker system prune -a --volumes

# Build specific service
docker-compose build web

# Run one-off command
docker-compose run --rm web bin/rails console

# Scale services
docker-compose up --scale sidekiq=3

# View resource usage
docker stats
```

---

## 🆘 Getting Help

**Check logs first:**
```bash
docker-compose logs -f web
```

**Common issues:**
1. Database not created → `docker-compose exec web bin/rails db:prepare`
2. Redis not connected → `docker-compose restart redis`
3. Port in use → Change ports in docker-compose.yml
4. Out of memory → Increase Docker Desktop resources

**Still stuck?**
- Check `documentation/` folder for more guides
- Review error logs: `docker-compose logs`
- Ensure Docker Desktop is running
- Try `docker-compose down && docker-compose up --build`

---

## ✅ Quick Reference Card

```bash
# === Daily Development ===
docker-compose up                    # Start everything
docker-compose logs -f web           # View logs
docker-compose exec web bin/rails c  # Rails console
docker-compose down                  # Stop everything

# === Database ===
docker-compose exec web bin/rails db:prepare   # Setup DB
docker-compose exec web bin/rails db:migrate   # Run migrations
docker-compose exec db psql -U postgres        # PostgreSQL shell

# === Maintenance ===
docker-compose restart web           # Restart service
docker-compose up --build            # Rebuild & start
docker system prune -a               # Clean up disk

# === Troubleshooting ===
docker-compose ps                    # Check status
docker-compose logs [service]        # View logs
docker-compose exec web bash         # Access shell
```

---

**Happy coding! 🚀**
