#!/bin/bash
set -e

# VitalForge Lightsail Deployment Script
# Builds Docker image and deploys to Lightsail Container Service

echo "🚀 VitalForge Lightsail Deployment"
echo "=================================="
echo ""

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
  echo "❌ Error: Run this script from the terraform/ directory"
  exit 1
fi

# Get resource info from Terraform
echo "📦 Getting Lightsail configuration..."
SERVICE_NAME=$(terraform output -raw lightsail_container_service_name 2>/dev/null)
ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null)
DB_URL=$(terraform output -raw database_url 2>/dev/null)
REDIS_URL=$(terraform output -raw redis_url 2>/dev/null)

if [ -z "$SERVICE_NAME" ] || [ -z "$ECR_URL" ]; then
  echo "❌ Error: Could not get Lightsail configuration. Run 'terraform apply' first."
  exit 1
fi

echo "  ✅ Service: $SERVICE_NAME"
echo "  ✅ ECR: $ECR_URL"
echo ""

# Extract AWS account ID and region
ACCOUNT_ID=$(echo $ECR_URL | cut -d. -f1)
REGION=$(echo $ECR_URL | cut -d. -f4)

echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

echo ""
echo "🏗️  Building Docker image..."
cd ..
docker build --platform linux/amd64 -t vitalforge-api .

echo ""
echo "🏷️  Tagging image..."
docker tag vitalforge-api:latest $ECR_URL:latest

echo ""
echo "⬆️  Pushing to ECR..."
docker push $ECR_URL:latest

echo ""
echo "🔄 Deploying to Lightsail Container Service..."

# Read environment variables
if [ -z "$RAILS_MASTER_KEY" ]; then
  echo "⚠️  RAILS_MASTER_KEY not set. Reading from terraform.tfvars..."
  RAILS_MASTER_KEY=$(grep rails_master_key ../terraform.tfvars 2>/dev/null | cut -d'"' -f2 || echo "")
fi

if [ -z "$SECRET_KEY_BASE" ]; then
  echo "⚠️  SECRET_KEY_BASE not set. Reading from terraform.tfvars..."
  SECRET_KEY_BASE=$(grep secret_key_base ../terraform.tfvars 2>/dev/null | cut -d'"' -f2 || echo "")
fi

if [ -z "$OPENAI_API_KEY" ]; then
  OPENAI_API_KEY=$(grep openai_api_key ../terraform.tfvars 2>/dev/null | cut -d'"' -f2 || echo "")
fi

if [ -z "$HONEYBADGER_API_KEY" ]; then
  HONEYBADGER_API_KEY=$(grep honeybadger_api_key ../terraform.tfvars 2>/dev/null | cut -d'"' -f2 || echo "")
fi

# Create deployment JSON
cat > /tmp/lightsail-deployment.json << EOF
{
  "containers": {
    "rails": {
      "image": "$ECR_URL:latest",
      "ports": {
        "3000": "HTTP"
      },
      "environment": {
        "RAILS_ENV": "production",
        "RAILS_LOG_TO_STDOUT": "true",
        "RAILS_SERVE_STATIC_FILES": "true",
        "DATABASE_URL": "$DB_URL",
        "REDIS_URL": "$REDIS_URL",
        "RAILS_MASTER_KEY": "$RAILS_MASTER_KEY",
        "SECRET_KEY_BASE": "$SECRET_KEY_BASE",
        "OPENAI_API_KEY": "$OPENAI_API_KEY",
        "HONEYBADGER_API_KEY": "$HONEYBADGER_API_KEY"
      }
    }
  },
  "publicEndpoint": {
    "containerName": "rails",
    "containerPort": 3000,
    "healthCheck": {
      "path": "/api/v1/health",
      "intervalSeconds": 30,
      "timeoutSeconds": 5,
      "unhealthyThresholdCount": 2,
      "healthyThresholdCount": 2
    }
  }
}
EOF

# Deploy to Lightsail
aws lightsail create-container-service-deployment \
  --region $REGION \
  --service-name $SERVICE_NAME \
  --cli-input-json file:///tmp/lightsail-deployment.json

rm /tmp/lightsail-deployment.json

echo ""
echo "✅ Deployment initiated!"
echo ""
echo "📊 Monitor deployment:"
echo "  aws lightsail get-container-service-deployments --service-name $SERVICE_NAME"
echo ""
echo "📝 View logs:"
echo "  aws lightsail get-container-log --service-name $SERVICE_NAME --container-name rails"
echo ""
echo "🌐 Your API will be available at:"
terraform output lightsail_service_url
echo ""
echo "⏳ Note: First deployment may take 5-10 minutes"
echo ""

