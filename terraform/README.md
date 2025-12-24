# VitalForge Terraform Infrastructure

This directory contains Terraform configuration for deploying VitalForge Rails API to AWS.

## Prerequisites

1. **AWS CLI** configured with credentials
2. **Terraform** >= 1.0 installed
3. **Docker** installed for building images
4. **Existing Resources**:
   - RDS PostgreSQL database
   - Route53 hosted zone for your domain

## Quick Start

### 1. Configure Variables

Copy the example file and fill in your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your actual values:
- `domain_name` - Your domain (e.g., "yourdomain.com")
- `database_url` - Full PostgreSQL connection string
- `rails_master_key` - From `config/master.key`
- `secret_key_base` - Generate with `rails secret`

### 2. Initialize Terraform

```bash
terraform init
```

This downloads the AWS provider and prepares Terraform.

### 3. Preview Changes

```bash
terraform plan
```

Review what Terraform will create. Should show ~20-25 resources.

### 4. Apply Configuration

```bash
terraform apply
```

Type `yes` to confirm. This will:
- Create ECR repository
- Set up security groups
- Create ALB with SSL certificate
- Configure ECS cluster and task definition
- Create Route53 DNS records
- Set up IAM roles and Secrets Manager

**Note**: Certificate validation may take 5-10 minutes.

### 5. Build and Push Docker Image

After Terraform completes, get the ECR repository URL:

```bash
terraform output ecr_repository_url
```

Then build and push:

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url | cut -d/ -f1)

# Build image (from project root)
cd ..
docker build -t vitalforge-api .

# Tag for ECR
docker tag vitalforge-api:latest $(cd terraform && terraform output -raw ecr_repository_url):latest

# Push to ECR
docker push $(cd terraform && terraform output -raw ecr_repository_url):latest
```

### 6. Wait for ECS Service

The ECS service will automatically pull the image and start:

```bash
# Check service status
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw ecs_service_name)
```

### 7. Run Database Migrations

Once the service is running, execute migrations:

```bash
# Get the task definition ARN
TASK_DEF=$(terraform output -raw ecs_cluster_name)

# Run migration as one-off task
aws ecs run-task \
  --cluster vitalforge-cluster \
  --task-definition vitalforge-api \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$(aws ec2 describe-subnets --filters "Name=default-for-az,Values=true" --query 'Subnets[0].SubnetId' --output text)],securityGroups=[$(terraform output -raw ecs_security_group_id)],assignPublicIp=ENABLED}" \
  --overrides '{"containerOverrides":[{"name":"rails","command":["bin/rails","db:migrate"]}]}'
```

### 8. Test Your API

```bash
# Get your API URL
terraform output api_url

# Test health endpoint
curl https://api.yourdomain.com/api/v1/health
```

## File Structure

```
terraform/
├── main.tf              # Provider and backend configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── data.tf              # Data sources (VPC, RDS, Route53)
├── security_groups.tf   # Security groups for ALB, ECS, RDS
├── ecr.tf               # Container registry
├── ecs.tf               # ECS cluster, task definition, service
├── alb.tf               # Application Load Balancer
├── acm.tf               # SSL certificate
├── route53.tf           # DNS records
├── iam.tf               # IAM roles and policies
├── secrets.tf           # Secrets Manager
├── cloudwatch.tf        # Log groups
└── terraform.tfvars     # Your values (gitignored)
```

## Common Commands

```bash
# Format Terraform files
terraform fmt

# Validate configuration
terraform validate

# Show current state
terraform show

# List all resources
terraform state list

# Get specific output
terraform output ecr_repository_url

# Update a single resource
terraform apply -target=aws_ecs_service.app

# Destroy everything (careful!)
terraform destroy
```

## Updating Your Application

### Deploy New Code

```bash
# 1. Build new image
docker build -t vitalforge-api .

# 2. Tag and push to ECR
docker tag vitalforge-api:latest $(terraform output -raw ecr_repository_url):latest
docker push $(terraform output -raw ecr_repository_url):latest

# 3. Force new deployment
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw ecs_service_name) \
  --force-new-deployment
```

### Update Infrastructure

```bash
# 1. Edit .tf files as needed

# 2. Preview changes
terraform plan

# 3. Apply changes
terraform apply
```

## Troubleshooting

### Certificate Validation Stuck

Check DNS records were created:

```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id $(terraform output -raw route53_zone_id)
```

### ECS Service Won't Start

Check CloudWatch logs:

```bash
aws logs tail /ecs/vitalforge --follow
```

### Health Check Failing

1. Verify `/api/v1/health` endpoint works locally
2. Check security group allows ALB → ECS on port 80
3. Review ECS task logs

### Database Connection Issues

1. Verify `DATABASE_URL` in Secrets Manager is correct
2. Check RDS security group allows ECS security group
3. Confirm RDS is in same VPC

## Cost Management

### Current Configuration Cost (~$44/month)

- ECS Fargate: ~$9
- RDS (existing): ~$15
- ALB: ~$18
- Other: ~$2

### To Reduce Costs

1. **Stop ECS service when not in use**:
   ```bash
   aws ecs update-service \
     --cluster vitalforge-cluster \
     --service vitalforge-api \
     --desired-count 0
   ```

2. **Use Fargate Spot** (edit `ecs.tf`):
   ```hcl
   capacity_provider_strategy {
     capacity_provider = "FARGATE_SPOT"
     weight            = 1
   }
   ```

3. **Downsize containers** (edit `terraform.tfvars`):
   ```hcl
   container_cpu    = 256  # Minimum
   container_memory = 512  # Minimum
   ```

## Security Best Practices

✅ **Implemented**:
- Secrets in AWS Secrets Manager
- Least-privilege IAM roles
- Security groups restrict traffic
- SSL/TLS encryption
- Container runs as non-root
- RDS in private subnet

🔄 **Consider Adding**:
- WAF for DDoS protection
- CloudTrail for audit logging
- GuardDuty for threat detection
- Secrets rotation policy
- Multi-AZ RDS

## Remote State (Optional)

For team collaboration, store Terraform state in S3:

1. Create S3 bucket and DynamoDB table:
   ```bash
   aws s3 mb s3://vitalforge-terraform-state
   aws dynamodb create-table \
     --table-name vitalforge-terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

2. Uncomment backend block in `main.tf`

3. Migrate state:
   ```bash
   terraform init -migrate-state
   ```

## Support

For issues or questions:
- Check CloudWatch logs: `/ecs/vitalforge`
- Review AWS documentation
- See `docs/AWS_DEPLOYMENT_ARCHITECTURE.md`

