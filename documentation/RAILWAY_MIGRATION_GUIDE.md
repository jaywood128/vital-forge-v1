# AWS to Railway Migration Guide

## ✅ COMPLETED: AWS Resource Cleanup (2026-01-31)

All billable resources have been successfully deleted via Terraform:
- ✅ Lightsail Container Service
- ✅ Lightsail PostgreSQL Database  
- ✅ ElastiCache Redis Cluster
- ✅ ECR Docker Repository (after clearing images)
- ✅ Security Groups
- ✅ Subnet Groups

**Monthly savings: ~$34.51**

---

## 🔍 Manual Cleanup (Optional)

### 1. Lightsail SSL Certificate
**Status:** Still exists (certificates don't cost money, but good hygiene to clean up)

**Certificate Details:**
- Name: `Certificate-1`
- Domains: `api-staging.forge-fitness-journal.app`, `staging-ui.forge-fitness-journal.app`

**To delete:**
```bash
# List certificates
aws lightsail get-certificates --region us-east-1

# Delete certificate (only if not attached to any resource)
aws lightsail delete-certificate \
  --certificate-name Certificate-1 \
  --region us-east-1
```

### 2. Route 53 DNS Validation Records (Optional)
The CNAME records created for SSL certificate validation can be cleaned up if desired:
- `_03507ff811d9c061f75981bc64065c16.api-staging.forge-fitness-journal.app`
- `_e85e3c4a3c93fdcacfe6f096a64c8a43.staging-ui.forge-fitness-journal.app`

These are harmless to leave in place.

---

## 🚂 Railway Migration Guide

### Step 1: Create Railway Account & Project
1. Go to https://railway.app
2. Sign up / log in with GitHub
3. Click **"New Project"**
4. Select **"Provision PostgreSQL"**

### Step 2: Add Rails Application
1. Click **"+ New"** → **"GitHub Repo"**
2. Connect your `vital-forge-v1` repository
3. Railway will auto-detect it's a Rails app

### Step 3: Configure Environment Variables

Railway needs these environment variables (add via project settings):

```bash
# Database (Railway provides DATABASE_URL automatically)
# DATABASE_URL=<automatically set by Railway>

# Rails secrets
RAILS_MASTER_KEY=<from vital-forge-v1/config/master.key>
SECRET_KEY_BASE=<generate new or use existing>
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true

# API Keys
OPENAI_API_KEY=<your key>
HONEYBADGER_API_KEY=<your key>

# CORS / Security (for Next.js UI)
ALLOWED_ORIGINS=https://staging-ui.forge-fitness-journal.app,https://your-vercel-ui.vercel.app
```

### Step 4: Configure Build & Start Commands

Railway should auto-detect these, but verify:

**Build Command:**
```bash
bundle install && bin/rails db:prepare && bin/rails assets:precompile
```

**Start Command:**
```bash
bin/rails server -b 0.0.0.0 -p $PORT
```

### Step 5: Run Database Migrations
After first deploy, open Railway's **"Terminal"** tab and run:
```bash
bin/rails db:migrate
bin/rails db:seed  # This will seed your exercises
```

### Step 6: Configure Custom Domain in Railway
1. In Railway project → Click your Rails service
2. Go to **"Settings"** → **"Networking"** → **"Public Networking"**
3. Click **"Custom Domain"**
4. Enter: `api-staging.forge-fitness-journal.app`
5. Railway will give you a CNAME target (like `xxx.railway.app`)

### Step 7: Update Route 53 DNS Records

In AWS Route 53 hosted zone for `forge-fitness-journal.app`:

**Update the API CNAME:**
```
Record Name: api-staging.forge-fitness-journal.app
Type: CNAME
Value: <your-railway-domain>.up.railway.app  # Railway will provide this
TTL: 300
```

**Remove or update UI CNAME (if needed):**
- Delete `staging-ui.forge-fitness-journal.app` CNAME pointing to Lightsail
- Later add new CNAME pointing to Vercel (when UI is deployed)

### Step 8: Test the Deployment
```bash
# Health check
curl https://api-staging.forge-fitness-journal.app/api/v1/health

# Should return: "ok"
```

### Step 9: Update Vercel UI Environment Variable
Once Railway API is live, update Vercel project:
```bash
API_URL=https://api-staging.forge-fitness-journal.app
```

---

## 💰 Cost Comparison

### AWS Lightsail (Previous)
- Container Service (Nano): $7/month
- Database (Micro): $15/month
- ElastiCache (t3.micro): $12.41/month
- **Total: ~$34.41/month**

### Railway (New)
- Hobby Plan: $5/month (includes $5 usage credit)
- Additional usage: ~$0.000231/GB egress, $0.000463/GB-hour RAM
- PostgreSQL: Included in usage
- **Estimated: $5-15/month** (depending on traffic)

### Remaining AWS Costs
- Route 53 Hosted Zone: $0.50/month
- Route 53 DNS Queries: ~$0.01-0.10/month
- **Total AWS: ~$0.50-0.60/month**

---

## 📋 Railway Deployment Checklist

- [ ] Create Railway account
- [ ] Create new project with PostgreSQL
- [ ] Connect GitHub repository
- [ ] Add environment variables
- [ ] Verify build/start commands
- [ ] Deploy and check logs
- [ ] Run `db:migrate` and `db:seed`
- [ ] Configure custom domain in Railway
- [ ] Update Route 53 CNAME record
- [ ] Test API endpoint
- [ ] Update Vercel UI `API_URL`
- [ ] Test full flow (UI → API → DB)

---

## 🆘 Troubleshooting

### Railway Build Fails
- Check Ruby version matches (should be 3.2.6)
- Verify Gemfile.lock is committed
- Check build logs for missing system dependencies

### Database Connection Errors
- Railway automatically sets `DATABASE_URL`
- Verify `config/database.yml` uses `ENV['DATABASE_URL']`
- Check that PostgreSQL service is running

### CORS Errors from UI
- Verify `ALLOWED_ORIGINS` includes your Vercel domain
- Check `config/initializers/cors.rb` configuration
- Ensure `credentials: true` is set for cookie-based auth

### Custom Domain Not Working
- DNS propagation can take 5-60 minutes
- Verify CNAME record points to Railway domain
- Check Railway logs for SSL certificate provisioning
- Use `dig api-staging.forge-fitness-journal.app` to verify DNS

---

## 📚 Useful Railway Commands

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Link to project
railway link

# Run migrations
railway run bin/rails db:migrate

# Open console
railway run bin/rails console

# View logs
railway logs

# View environment variables
railway variables
```

---

## 🎉 Migration Complete!

Once Railway is deployed and Route 53 is updated, your application will be:
- Running on Railway (cheaper, simpler)
- Using Railway Postgres (managed)
- DNS managed by Route 53 (minimal cost)
- Ready for Vercel UI deployment

**Next step:** Deploy your Next.js UI to Vercel and connect it to the Railway API!
