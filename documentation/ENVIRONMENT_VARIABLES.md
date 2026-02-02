# Terraform Environment Variables for Staging

## Required Environment Variables for ECS Task

Add these to your ECS task definition in Terraform:

```hcl
environment = [
  # Rails environment (use "staging" for your current deployment)
  {
    name  = "RAILS_ENV"
    value = "staging"
  },
  
  # CORS allowed origins (comma-separated list of frontend URLs)
  {
    name  = "ALLOWED_ORIGINS"
    value = "https://staging.yourfrontend.com,https://app.yourfrontend.com"
  },
  
  # App host for mailer URLs and redirects
  {
    name  = "APP_HOST"
    value = "api.staging.yourdomain.com"
  },
  
  # Optional: Log level (defaults to "debug" in staging)
  {
    name  = "RAILS_LOG_LEVEL"
    value = "debug"
  }
]
```

## Secrets (stored in AWS Secrets Manager)

These should already be in your Secrets Manager secret:

```json
{
  "DATABASE_URL": "postgresql://user:pass@host:5432/dbname",
  "RAILS_MASTER_KEY": "your-master-key-from-config/master.key",
  "SECRET_KEY_BASE": "generated-via-rails-secret"
}
```

## Quick Setup Checklist

- [ ] Set `RAILS_ENV=staging` in ECS task definition
- [ ] Set `ALLOWED_ORIGINS` with your frontend URL(s)
- [ ] Set `APP_HOST` to your API domain
- [ ] Verify secrets in AWS Secrets Manager
- [ ] Deploy: `cd terraform && ./deploy.sh`
- [ ] Test: `curl https://api.staging.yourdomain.com/api/v1/health`

## Environment Behavior

| Variable | Value | Effect |
|----------|-------|--------|
| `RAILS_ENV=staging` | staging | Uses `config/environments/staging.rb` |
| `RAILS_ENV=production` | production | Uses `config/environments/production.rb` |
| `ALLOWED_ORIGINS` | (empty) | CORS blocks all browser requests |
| `ALLOWED_ORIGINS` | `https://app.com` | CORS allows only `https://app.com` |
| `RAILS_LOG_LEVEL` | debug | Verbose logging |
| `RAILS_LOG_LEVEL` | info | Standard logging |

## Testing CORS Configuration

### From Browser Console
```javascript
// Should succeed if origin is in ALLOWED_ORIGINS
fetch('https://api.staging.yourdomain.com/api/v1/health', {
  credentials: 'include'
})
.then(r => r.text())
.then(console.log)
```

### From Postman/Bruno
No CORS restrictions apply — these tools bypass browser security.

## Common Mistakes

❌ **Don't do this:**
```hcl
# Wrong: Using production for staging
RAILS_ENV = "production"
```

❌ **Don't do this:**
```hcl
# Wrong: Including localhost in staging CORS
ALLOWED_ORIGINS = "http://localhost:3001,https://app.com"
```

✅ **Do this:**
```hcl
# Correct: Use staging environment
RAILS_ENV = "staging"

# Correct: Only production frontend URLs
ALLOWED_ORIGINS = "https://staging.app.com,https://app.com"
```

## Updating Environment Variables

After changing environment variables in Terraform:

```bash
# 1. Apply Terraform changes
terraform apply

# 2. Force new deployment to pick up new env vars
aws ecs update-service \
  --cluster vitalforge-cluster \
  --service vitalforge-api \
  --force-new-deployment \
  --region us-east-1
```

Or use the deploy script (rebuilds image):
```bash
./deploy.sh
```

