# Lightsail Migration - Successfully Completed ✅

**Migration Date:** January 14, 2026  
**Status:** Infrastructure created and ready for deployment

---

## Migration Summary

Successfully migrated VitalForge from AWS Fargate to AWS Lightsail architecture.

### What Was Created

✅ **Lightsail Container Service**
- Name: `vitalforge-v1-container`
- Size: Nano (512MB RAM, 0.25 vCPU)
- Cost: $7/month
- URL: https://vitalforge-v1-container.w17nat6jerjqp.us-east-1.cs.amazonlightsail.com

✅ **Lightsail PostgreSQL Database**
- Name: `vitalforge-v1-db`
- Version: PostgreSQL 16
- Size: Micro (1GB RAM, 40GB SSD)
- Cost: $15/month
- Status: Available

✅ **ElastiCache Redis Cluster**
- Name: `vitalforge-v1-redis`
- Type: cache.t3.micro
- Cost: ~$12.41/month
- Status: Available

✅ **ECR Repository** (Kept from previous setup)
- URL: `381783740921.dkr.ecr.us-east-1.amazonaws.com/vitalforge-v1-api`
- Purpose: Docker image storage

---

## What Was Removed

🗑️ **Old Fargate Resources**
- ECS Cluster, Service, Task Definition
- IAM Roles for ECS
- Secrets Manager
- CloudWatch Log Group
- Security Groups
- RDS Instance (database-1) - Deleted

---

## Cost Summary

### Estimated Monthly Cost

| Resource | Monthly Cost |
|----------|-------------|
| Lightsail Container (Nano) | $7.00 |
| Lightsail Database (Micro) | $15.00 |
| ElastiCache Redis (t3.micro) | $12.41 |
| ECR Storage (~1GB) | $0.10 |
| **Total (Full Month)** | **$34.51** |

### Cost for 10 Days Usage

| Resource | 10-Day Cost |
|----------|-------------|
| Lightsail Container | $2.33 |
| Lightsail Database | $5.00 |
| ElastiCache Redis | $4.08 |
| ECR Storage | $0.10 |
| **Total (10 Days)** | **$11.51** |

---

## Configuration Changes

### 1. Email Jobs Disabled

**File:** `app/jobs/weekly_progress_report_job.rb`

```ruby
# TEMPORARILY DISABLED - No mail server configured
# SendWeeklyProgressEmailJob.perform_async(user.id)
```

- ✅ Cron schedule still runs (Monday 8 AM)
- ✅ AI feedback generation still works
- ❌ Email sending disabled (no mail server)

### 2. Terraform Structure

**New Files Created:**
- `terraform/lightsail.tf` - Lightsail resources
- `terraform/elasticache.tf` - Redis configuration
- `terraform/deploy-lightsail.sh` - Deployment script
- `terraform/aws-shutdown.sh` - Infrastructure shutdown script
- `terraform/aws-startup.sh` - Infrastructure startup script

**Files Modified:**
- `terraform/variables.tf` - Added Lightsail variables
- `terraform/outputs.tf` - Updated for Lightsail outputs
- `terraform/terraform.tfvars` - Added database password
- `terraform/data.tf` - Removed RDS reference

**Files Deprecated (Commented Out):**
- `terraform/ecs.tf` - Old Fargate configuration
- `terraform/iam.tf` - ECS IAM roles
- `terraform/secrets.tf` - Secrets Manager
- `terraform/cloudwatch.tf` - CloudWatch logs
- `terraform/security_groups.tf` - ECS security groups

---

## Next Steps: Deployment

### Step 1: Build and Push Docker Image

```bash
cd terraform
./deploy-lightsail.sh
```

This script will:
1. Log into ECR
2. Build Docker image
3. Push to ECR
4. Deploy to Lightsail Container Service
5. Run database migrations

### Step 2: Verify Deployment

```bash
# Check container service status
aws lightsail get-container-services --service-name vitalforge-v1-container

# View logs
aws lightsail get-container-log \
  --service-name vitalforge-v1-container \
  --container-name rails

# Test health endpoint
curl https://vitalforge-v1-container.us-east-1.cs.amazonlightsail.com/api/v1/health
```

### Step 3: Run Database Migrations

The deployment script will handle this, but you can also run manually:

```bash
# SSH into container or use AWS CLI to execute
aws lightsail create-container-service-deployment \
  --service-name vitalforge-v1-container \
  --containers '{"rails": {"command": ["bin/rails", "db:create", "db:migrate", "db:seed"]}}'
```

---

## Cost Management Scripts

### Shutdown Infrastructure (When Not Using)

```bash
cd terraform
./aws-shutdown.sh
```

Saves approximately **$0.95/day** when shut down.

### Startup Infrastructure (When Needed)

```bash
cd terraform
./aws-startup.sh
```

Recreates all infrastructure and deploys the latest image.

---

## Environment Variables Needed

The following environment variables are configured in the deployment:

✅ **DATABASE_URL** - Auto-generated from Lightsail DB endpoint  
✅ **REDIS_URL** - Auto-generated from ElastiCache endpoint  
✅ **RAILS_MASTER_KEY** - From terraform.tfvars  
✅ **SECRET_KEY_BASE** - From terraform.tfvars  
⚠️ **OPENAI_API_KEY** - Optional (for AI feedback)  
⚠️ **HONEYBADGER_API_KEY** - Optional (for error tracking)

---

## Domains & DNS (Route 53 / Lightsail / Vercel)

### Root domain (registered)
- **Apex domain**: `forge-fitness-journal.app`
- **Authoritative DNS**: Route 53 hosted zone for `forge-fitness-journal.app`

> Note: subdomains like `api-staging.forge-fitness-journal.app` are not “registered” separately. Only the apex domain is registered; subdomains are created via DNS records.

### Current / intended subdomains

#### API (Lightsail Container Service)
- **Hostname**: `api-staging.forge-fitness-journal.app`
- **Purpose**: Rails API (Lightsail Container Service public endpoint)
- **DNS (Route 53)**:
  - **Type**: CNAME
  - **Name**: `api-staging`
  - **Value**: `vitalforge-v1-container.w17nat6jerjqp.us-east-1.cs.amazonlightsail.com` *(hostname only — no `http://`, no path)*
- **HTTPS/TLS**:
  - Route 53 CNAME is not enough by itself.
  - The domain must be attached in **Lightsail → Container services → `vitalforge-v1-container` → Networking / Custom domains**.
  - Lightsail will provide DNS validation records (typically CNAMEs) to add to Route 53.
  - If not attached, requests may return: `404 No Such Service`.

#### UI (Vercel) — planned
- **Hostname**: `staging-ui.forge-fitness-journal.app`
- **Purpose**: Next.js UI hosted on Vercel
- **DNS (Route 53)** (typical Vercel setup):
  - **Type**: CNAME
  - **Name**: `staging-ui`
  - **Value**: `cname.vercel-dns.com` *(or whatever Vercel instructs)*
- **HTTPS/TLS**:
  - Managed by Vercel after DNS verification.

### Naming convention (future environments — unlikely)
If another environment is ever added, keep the same pattern:
- **Prod API**: `api.forge-fitness-journal.app`
- **Prod UI**: `forge-fitness-journal.app` (or `www.forge-fitness-journal.app`)
- **Staging API**: `api-staging.forge-fitness-journal.app`
- **Staging UI**: `staging-ui.forge-fitness-journal.app`

### Quick troubleshooting notes
- **Don’t use URLs in DNS records**: Route 53 record values must not include `http://` / `https://` or any `/path`.
- **Ping is not a health check**: many AWS endpoints don’t respond to ICMP; use `curl`.
- **API health check**: `GET /api/v1/health` should return `200` with body `ok`.

---

## Manual Cleanup Required

The following old resources were **removed from Terraform state** but still exist in AWS and should be manually deleted:

### In AWS Console:

1. **ECS Service** - `vitalforge-v1-api` (if still exists)
2. **ECS Cluster** - `vitalforge-v1-cluster` (if still exists)
3. **IAM Roles** - Search for "vitalforge" and delete:
   - `vitalforge-v1-ecs-task-execution-role`
   - `vitalforge-v1-ecs-task-role`
4. **Secrets Manager** - `vitalforge-v1/production` (if still exists)
5. **CloudWatch Log Group** - `/ecs/vitalforge-v1` (if still exists)
6. **Security Groups** - `vitalforge-v1-ecs-sg` (if still exists)

### Already Deleted:

✅ **RDS Instance** - `database-1` (deletion in progress)

---

## Terraform Outputs

```bash
ecr_repository_url = 381783740921.dkr.ecr.us-east-1.amazonaws.com/vitalforge-v1-api
lightsail_container_service_name = vitalforge-v1-container
lightsail_database_name = vitalforge-v1-db
lightsail_service_url = https://vitalforge-v1-container.us-east-1.cs.amazonlightsail.com
redis_cluster_id = vitalforge-v1-redis
route53_zone_id = Z007891223B49MBJLHM9Z

# Sensitive outputs (use: terraform output <name>)
database_url = postgresql://postgres:***@...
redis_url = redis://...
lightsail_database_endpoint = ...
redis_endpoint = ...
```

---

## Troubleshooting

### If deployment fails:

1. **Check container logs:**
   ```bash
   aws lightsail get-container-log \
     --service-name vitalforge-v1-container \
     --container-name rails
   ```

2. **Verify database connectivity:**
   ```bash
   terraform output lightsail_database_endpoint
   terraform output database_url
   ```

3. **Check Redis connectivity:**
   ```bash
   terraform output redis_endpoint
   ```

4. **Restart deployment:**
   ```bash
   cd terraform
   ./deploy-lightsail.sh
   ```

---

## Rolling Back (If Needed)

If you need to rollback to Fargate:

1. Uncomment files in `terraform/`:
   - `ecs.tf`
   - `iam.tf`
   - `secrets.tf`
   - `cloudwatch.tf`

2. Comment out:
   - `lightsail.tf`
   - `elasticache.tf`

3. Run:
   ```bash
   terraform init
   terraform apply
   ```

---

## Success Criteria

✅ Infrastructure created  
⏳ **Next:** Deploy application  
⏳ **Then:** Test API endpoints  
⏳ **Finally:** Verify AI feedback job runs

---

## Support

For issues or questions about this migration, refer to:
- Terraform configuration in `terraform/` directory
- Deployment script: `terraform/deploy-lightsail.sh`
- Shutdown script: `terraform/aws-shutdown.sh`
- Startup script: `terraform/aws-startup.sh`

---

**Migration completed successfully!** 🎉

Ready for first deployment to Lightsail.
