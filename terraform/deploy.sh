#!/bin/bash
set -e

# VitalForge Deployment Script
# Builds Docker image and deploys to ECS

echo "🚀 VitalForge Deployment Script"
echo "================================"

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
  echo "❌ Error: Run this script from the terraform/ directory"
  exit 1
fi

# Get ECR repository URL from Terraform
echo "📦 Getting ECR repository URL..."
ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null)

if [ -z "$ECR_URL" ]; then
  echo "❌ Error: Could not get ECR URL. Have you run 'terraform apply'?"
  exit 1
fi

echo "✅ ECR URL: $ECR_URL"

# Extract account ID and region
ACCOUNT_ID=$(echo $ECR_URL | cut -d. -f1)
REGION=$(echo $ECR_URL | cut -d. -f4)

echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

echo "🏗️  Building Docker image..."
cd ..
docker build -t vitalforge-api .

echo "🏷️  Tagging image..."
docker tag vitalforge-api:latest $ECR_URL:latest

echo "⬆️  Pushing to ECR..."
docker push $ECR_URL:latest

echo "🔄 Forcing new ECS deployment..."
cd terraform
CLUSTER=$(terraform output -raw ecs_cluster_name)
SERVICE=$(terraform output -raw ecs_service_name)

aws ecs update-service \
  --cluster $CLUSTER \
  --service $SERVICE \
  --force-new-deployment \
  --region $REGION \
  > /dev/null

echo "✅ Deployment initiated!"
echo ""
echo "📊 Monitor deployment:"
echo "  aws ecs describe-services --cluster $CLUSTER --service $SERVICE --region $REGION"
echo ""
echo "📝 View logs:"
echo "  aws logs tail /ecs/vitalforge --follow --region $REGION"
echo ""
echo "🌐 Your API:"
echo "  $(terraform output -raw api_url)"

