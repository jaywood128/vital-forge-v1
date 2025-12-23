# VitalForge AWS Deployment - Quick Start Guide

## Overview

This guide will walk you through deploying VitalForge Rails API to AWS using Terraform.

**Time to Deploy**: ~30-45 minutes (mostly waiting for AWS resources)

## Prerequisites Checklist

- [ ] AWS CLI installed and configured (`aws configure`)
- [ ] Terraform >= 1.0 installed (`terraform --version`)
- [ ] Docker installed (`docker --version`)
- [ ] RDS PostgreSQL database created
- [ ] Route53 hosted zone for your domain
- [ ] Domain name ready (e.g., `yourdomain.com`)

## Step-by-Step Deployment

### Step 1: Configure Terraform Variables (5 minutes)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region     = "us-east-1"
aws_account_id = "381783740921"  # Your AWS account ID

domain_name    = "yourdomain.com"     # CHANGE THIS
api_subdomain  = "api"

rds_identifier = "database-1"  # Your RDS instance name

# Get these values:
database_url     = "postgresql://postgres:PASSWORD@database-1.xxx.us-east-1.rds.amazonaws.com:5432/vital_forge_production"
rails_master_key = "..."  # From config/master.key
secret_key_base  = "..."  # Run: rails secret
```

**How to get values:**
```bash
# Rails master key
cat config/master.key

# Generate secret key base
rails secret

# RDS endpoint
aws rds describe-db-instances \
  --db-instance-identifier database-1 \
  --region us-east-1 \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

### Step 2: Initialize Terraform (2 minutes)

```bash
terraform init
```

Expected output: "Terraform has been successfully initialized!"

### Step 3: Preview Infrastructure (2 minutes)

```bash
terraform plan
```

Review the output. Should show ~20-25 resources to create.

### Step 4: Create Infrastructure (15-20 minutes)

```bash
terraform apply
```

Type `yes` when prompted.

**What's being created:**
- ✅ ECR repository for Docker images
- ✅ Security groups (ALB, ECS, RDS)
- ✅ Application Load Balancer
- ✅ SSL certificate (with DNS validation)
- ✅ Route53 DNS records
- ✅ ECS cluster and task definition
- ✅ IAM roles and policies
- ✅ Secrets Manager secret
- ✅ CloudWatch log group

**Note**: Certificate validation takes 5-10 minutes. Terraform will wait for it.

### Step 5: Build and Push Docker Image (5-10 minutes)

Use the provided script:

```bash
./deploy.sh
```

Or manually:

```bash
# Get ECR URL
ECR_URL=$(terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $(echo $ECR_URL | cut -d/ -f1)

# Build and push
cd ..
docker build -t vitalforge-api .
docker tag vitalforge-api:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

### Step 6: Wait for ECS Service (2-3 minutes)

The ECS service will automatically start and pull your image.

Check status:

```bash
aws ecs describe-services \
  --cluster vitalforge-cluster \
  --services vitalforge-api \
  --query 'services[0].deployments[0].rolloutState' \
  --output text
```

Wait for: `COMPLETED`

### Step 7: Run Database Migrations (2 minutes)

Use the provided script:

```bash
./migrate.sh
```

Or manually:

```bash
# Get network config
SUBNET=$(aws ec2 describe-subnets --filters "Name=default-for-az,Values=true" --query 'Subnets[0].SubnetId' --output text)
SG=$(terraform output -raw ecs_security_group_id)

# Run migration
aws ecs run-task \
  --cluster vitalforge-cluster \
  --task-definition vitalforge-api \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG],assignPublicIp=ENABLED}" \
  --overrides '{"containerOverrides":[{"name":"rails","command":["bin/rails","db:migrate"]}]}'
```

### Step 8: Test Your API (1 minute)

```bash
# Get your API URL
terraform output api_url

# Test health endpoint
curl https://api.yourdomain.com/api/v1/health
# Expected: "ok"

# Test a real endpoint
curl https://api.yourdomain.com/api/v1/workout_templates
```

## 🎉 Deployment Complete!

Your API is now live at: `https://api.yourdomain.com`

## Next Steps

### Monitor Your Application

```bash
# View logs
aws logs tail /ecs/vitalforge --follow

# Check service status
aws ecs describe-services --cluster vitalforge-cluster --services vitalforge-api

# View tasks
aws ecs list-tasks --cluster vitalforge-cluster
```

### Deploy Updates

```bash
cd terraform
./deploy.sh
```

This will:
1. Build new Docker image
2. Push to ECR
3. Force ECS to deploy new version

### Update Infrastructure

```bash
# Edit .tf files as needed
terraform plan
terraform apply
```

## Troubleshooting

### Certificate Validation Stuck

**Problem**: Terraform hangs at "Creating certificate validation..."

**Solution**: Check DNS records were created:
```bash
aws route53 list-resource-record-sets --hosted-zone-id $(terraform output -raw route53_zone_id) | grep CNAME
```

If no CNAME records, check your hosted zone is correct in `terraform.tfvars`.

### ECS Service Won't Start

**Problem**: Tasks keep stopping

**Solution**: Check CloudWatch logs:
```bash
aws logs tail /ecs/vitalforge --follow
```

Common issues:
- Database connection failed → Check `DATABASE_URL` in Secrets Manager
- Missing `RAILS_MASTER_KEY` → Verify secret is correct
- Health check failing → Ensure `/api/v1/health` endpoint exists

### 502 Bad Gateway

**Problem**: ALB returns 502 error

**Solution**: 
1. Check target group health:
   ```bash
   aws elbv2 describe-target-health --target-group-arn $(terraform output -raw target_group_arn)
   ```
2. Verify security group allows ALB → ECS on port 80
3. Check ECS task logs for startup errors

### Database Connection Refused

**Problem**: Rails can't connect to RDS

**Solution**:
1. Verify RDS security group allows ECS security group on port 5432
2. Check `DATABASE_URL` format in Secrets Manager
3. Confirm RDS is in same VPC as ECS tasks

## Cost Management

**Current monthly cost**: ~$44

To reduce costs:

```bash
# Stop ECS service (keeps infrastructure, stops containers)
aws ecs update-service --cluster vitalforge-cluster --service vitalforge-api --desired-count 0

# Restart when needed
aws ecs update-service --cluster vitalforge-cluster --service vitalforge-api --desired-count 1
```

## Cleanup

To destroy all infrastructure:

```bash
cd terraform
terraform destroy
```

**Warning**: This will delete everything except RDS and Route53 (those are data sources, not managed by Terraform).

## Support

- **Documentation**: See `terraform/README.md` and `docs/AWS_DEPLOYMENT_ARCHITECTURE.md`
- **Logs**: `aws logs tail /ecs/vitalforge --follow`
- **AWS Console**: Check ECS, CloudWatch, and ALB sections

---

**Questions?** Review the detailed documentation in `terraform/README.md` or check CloudWatch logs for specific errors.

