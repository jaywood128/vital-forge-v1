# Local Terraform Cleanup Guide

## AWS Resources Cleanup Complete ✅

**All AWS resources deleted (2026-01-31):**
- ✅ Secrets Manager secrets (2)
- ✅ CloudWatch log groups (5)
- ✅ ECS service (vitalforge-v1-api)
- ✅ ECS cluster (vitalforge-v1-cluster)

**Additional monthly savings: ~$0.90**

---

## Local Terraform Files - What to Keep vs Delete

### ❓ Should You Keep Terraform Files?

**Reasons to KEEP:**
1. **Documentation** - Shows what infrastructure you had
2. **Reference** - Useful patterns for future projects
3. **History** - Understanding of your deployment evolution
4. **Reusability** - If you ever go back to AWS
5. **Learning** - Good examples of Lightsail, ECS, RDS configs

**Reasons to DELETE:**
1. **Confusion** - Might accidentally run `terraform apply`
2. **Clutter** - Not using AWS anymore
3. **Outdated** - Railway doesn't use Terraform (uses railway.json or GUI)

### 🎯 My Recommendation: **ARCHIVE, Don't Delete**

Railway doesn't use Terraform like AWS does. Railway uses:
- `railway.json` (optional config file)
- Railway Dashboard/CLI (primary deployment method)

So your Terraform code is AWS-specific and won't help with Railway.

---

## Option 1: Archive Terraform Files (RECOMMENDED)

Create an archive directory to preserve history:

```bash
cd vital-forge-v1
mkdir terraform-archive-aws-2026-01-31
mv terraform terraform-archive-aws-2026-01-31/
```

**Pros:**
- Preserves all infrastructure knowledge
- Can reference later if needed
- Prevents accidental `terraform apply`
- Clean main directory

---

## Option 2: Keep Terraform As-Is

Leave `vital-forge-v1/terraform/` exactly where it is.

**Add this to the README to prevent accidents:**

```markdown
## ⚠️ Terraform Directory - AWS DEPRECATED

The `terraform/` directory contains AWS Lightsail infrastructure code that is
**NO LONGER IN USE** as of 2026-01-31. 

**DO NOT RUN:**
- `terraform apply` (all resources deleted)
- `terraform plan` (will show everything needs to be created)

**Current hosting:** Railway (see RAILWAY_MIGRATION_GUIDE.md)

**Keep for:** Reference and documentation purposes only.
```

---

## Option 3: Delete Terraform Entirely

If you're 100% sure you'll never reference it:

```bash
cd vital-forge-v1
rm -rf terraform/
```

**⚠️ Warning:** This is permanent. No getting it back unless you have git history.

---

## What About Terraform State Files?

Your `terraform.tfstate` files show **zero resources** now (we ran `terraform destroy`).

### Safe to Delete:
```bash
cd vital-forge-v1/terraform
rm terraform.tfstate*
rm .terraform.lock.hcl
rm -rf .terraform/
```

These files are only needed if you want to manage AWS resources with Terraform again.

---

## Railway Configuration Files

Railway uses different configuration:

### Option 1: `railway.json` (optional)
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "bundle install && bin/rails db:prepare && bin/rails assets:precompile"
  },
  "deploy": {
    "startCommand": "bin/rails server -b 0.0.0.0 -p $PORT",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### Option 2: Railway Dashboard (most common)
Just use the Railway web UI to configure everything. No config files needed!

---

## Git Considerations

### If You Keep Terraform:
Add this to `.gitignore` (if not already there):
```
terraform/.terraform/
terraform/*.tfstate
terraform/*.tfstate.backup
terraform/.terraform.lock.hcl
```

### If You Archive Terraform:
```bash
git mv terraform terraform-archive-aws-2026-01-31
git commit -m "Archive AWS Terraform configs (migrated to Railway)"
```

### If You Delete Terraform:
```bash
git rm -rf terraform
git commit -m "Remove AWS Terraform (migrated to Railway)"
```

---

## Recommended Action Plan

```bash
# 1. Archive the terraform directory
cd vital-forge-v1
mkdir -p documentation/archive
mv terraform documentation/archive/terraform-aws-2026-01-31

# 2. Create a note about the migration
cat > documentation/archive/README.md << 'EOF'
# AWS Infrastructure Archive

This directory contains AWS Lightsail/ECS/RDS Terraform configurations
that were used from 2025-2026.

**Decommissioned:** January 31, 2026
**Migrated to:** Railway
**Reason:** Cost savings (~$34/month → ~$5-15/month)

See `RAILWAY_MIGRATION_GUIDE.md` for current hosting setup.
EOF

# 3. Update main README to mention Railway
# (You'll do this manually)

# 4. Commit the changes
git add -A
git commit -m "Archive AWS Terraform configs after successful migration to Railway"
```

---

## Files You Should Definitely Keep

These are not Terraform-related and are needed for Railway:

✅ **Keep these files:**
- `Dockerfile` - Railway uses this!
- `config/database.yml` - Railway needs this
- `config/environments/production.rb` - Railway uses this
- All your Rails app code
- `Gemfile` / `Gemfile.lock`
- `.env.example` (template for Railway env vars)

---

## Summary

**My recommendation:**
1. ✅ **Archive** `terraform/` → `documentation/archive/terraform-aws-2026-01-31/`
2. ✅ **Keep** the documentation files we just created
3. ✅ **Keep** `Dockerfile` and all Rails code
4. ✅ **Add** `railway.json` (optional, but nice for explicitness)
5. ✅ **Update** main README to mention Railway as current host

This way you preserve knowledge but avoid confusion! 🎯
