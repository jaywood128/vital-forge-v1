# Staging Environment Configuration

## Overview

VitalForge now has a dedicated **staging environment** that mirrors production settings but with enhanced debugging capabilities.

## Environment Hierarchy

```
development  → Local development (HTTP, localhost, verbose logging)
staging      → AWS deployment for testing (HTTPS, secure cookies, debug logging)
production   → Future production deployment (HTTPS, secure cookies, info logging)
```

## Key Differences

| Setting | Development | Staging | Production |
|---------|-------------|---------|------------|
| **HTTPS** | ❌ HTTP only | ✅ Required | ✅ Required |
| **Secure Cookies** | ❌ No | ✅ Yes | ✅ Yes |
| **Error Reports** | Full | Full | Limited |
| **Log Level** | Debug | Debug | Info |
| **Deprecation Warnings** | Yes | Yes | No |
| **Code Reloading** | Yes | No | No |
| **CORS** | Localhost only | ALLOWED_ORIGINS | ALLOWED_ORIGINS |

## Cookie Configuration

All environments now use consistent cookie settings:

```ruby
# Session cookies
secure: !Rails.env.development?  # true in staging and production
same_site: :lax                   # compatible with most use cases

# CSRF cookies
secure: !Rails.env.development?  # true in staging and production
same_site: :lax                   # compatible with most use cases
```

### Why `:lax` instead of `:none`?

- `:lax` works for same-site requests and top-level navigation
- `:none` requires `secure: true` and allows true cross-site requests
- For most API + frontend setups, `:lax` is sufficient and more secure
- Change to `:none` only if you need cross-site POST requests from embedded contexts

## Deploying to Staging

### 1. Set Environment Variables in Terraform

Update your ECS task definition to include:

```hcl
environment = [
  {
    name  = "RAILS_ENV"
    value = "staging"
  },
  {
    name  = "ALLOWED_ORIGINS"
    value = "https://staging.yourfrontend.com,https://app.yourfrontend.com"
  },
  {
    name  = "APP_HOST"
    value = "api.staging.yourdomain.com"
  }
]
```

### 2. Deploy

```bash
cd terraform
./deploy.sh
```

The deploy script will:
1. Build Docker image from current code
2. Push to ECR with `:latest` tag
3. Force ECS to deploy new version

### 3. Verify Environment

```bash
# Check logs to confirm staging environment
aws logs tail /ecs/vitalforge --follow

# Should see: "Rails 8.0.2 application starting in staging"
```

## Testing Staging from Local Machine

### Using Postman/Bruno (Recommended)

```
1. GET https://api.staging.yourdomain.com/api/v1/csrf
   → Captures CSRF-TOKEN cookie

2. POST https://api.staging.yourdomain.com/api/v1/session
   Headers:
     X-CSRF-Token: <token from step 1>
   Body:
     { "user": { "email": "test@example.com", "password": "..." } }
   → Captures session cookie

3. GET https://api.staging.yourdomain.com/api/v1/workouts
   Headers:
     X-CSRF-Token: <token from step 1>
   Cookies:
     _vital_forge_session=<session from step 2>
```

**Note**: CORS doesn't apply to Postman/Bruno — they're not browsers.

### Using Browser/Frontend

Your frontend must be in the `ALLOWED_ORIGINS` list:

```bash
# In Terraform or ECS environment
ALLOWED_ORIGINS=https://staging.yourfrontend.com
```

## Common Issues

### Issue: "ActionController::InvalidAuthenticityToken"

**Cause**: Missing or invalid CSRF token

**Solution**: 
1. Get fresh CSRF token from `/api/v1/csrf`
2. Include in `X-CSRF-Token` header
3. Include session cookie from login

### Issue: "CORS policy blocked"

**Cause**: Frontend origin not in `ALLOWED_ORIGINS`

**Solution**: Add your frontend URL to `ALLOWED_ORIGINS` environment variable

### Issue: Cookies not being set

**Cause**: Not using HTTPS in staging

**Solution**: Verify:
1. ALB is configured for HTTPS (port 443)
2. SSL certificate is valid
3. Route53 points to ALB
4. `config.force_ssl = true` in staging.rb

## Environment-Specific Credentials

Rails uses separate credentials for each environment:

```bash
# Edit staging credentials
EDITOR=nano rails credentials:edit --environment staging

# View staging credentials
rails credentials:show --environment staging
```

Store staging-specific secrets here:
- Database passwords
- API keys
- Third-party service credentials

## Switching Between Environments Locally

```bash
# Run in development (default)
rails server

# Run in staging (for testing)
RAILS_ENV=staging rails server

# Run in production (rarely needed locally)
RAILS_ENV=production rails server
```

## Branching Strategy for Staging

```
main (production)
  ↑
  └── development (staging deployments)
        ↑
        └── feature branches
```

**Workflow:**
1. Create feature branch from `development`
2. Merge feature → `development` when ready
3. Deploy `development` to staging: `git checkout development && cd terraform && ./deploy.sh`
4. Test in staging
5. When stable, merge `development` → `main` for production

## Monitoring Staging

```bash
# View logs
aws logs tail /ecs/vitalforge --follow --region us-east-1

# Check service status
aws ecs describe-services \
  --cluster vitalforge-cluster \
  --services vitalforge-api \
  --region us-east-1

# Check task health
aws ecs list-tasks \
  --cluster vitalforge-cluster \
  --service-name vitalforge-api \
  --region us-east-1
```

## Cost Considerations

Staging and production run on the same infrastructure type, so costs are similar:
- **ECS Fargate**: ~$30/month per environment
- **RDS**: ~$15/month per database
- **ALB**: ~$16/month per load balancer

**Total per environment**: ~$60/month

To reduce costs, you can:
1. Scale down ECS task count: `desired_count = 1`
2. Use smaller Fargate sizes: `cpu = 256, memory = 512`
3. Stop staging when not in use: `aws ecs update-service --desired-count 0`

## Next Steps

1. ✅ Staging environment created
2. ✅ Cookie configurations updated
3. ✅ CORS configured for environment-based origins
4. 🔲 Update Terraform to use `RAILS_ENV=staging`
5. 🔲 Set `ALLOWED_ORIGINS` in Terraform
6. 🔲 Deploy to staging
7. 🔲 Test authentication flow
8. 🔲 Create production environment when ready

