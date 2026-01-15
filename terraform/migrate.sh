#!/bin/bash
set -e

# VitalForge Database Migration Script
# Runs Rails migrations as a one-off ECS task

echo "🗄️  VitalForge Database Migration Script"
echo "========================================"

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
  echo "❌ Error: Run this script from the terraform/ directory"
  exit 1
fi

# Get values from Terraform
echo "📦 Getting ECS configuration..."
CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null)
TASK_DEF=$(terraform output -raw ecs_cluster_name 2>/dev/null)
REGION="us-east-1"

if [ -z "$CLUSTER" ]; then
  echo "❌ Error: Could not get ECS cluster name. Have you run 'terraform apply'?"
  exit 1
fi

# Get subnet and security group
echo "🔍 Getting network configuration..."
SUBNET=$(aws ec2 describe-subnets \
  --filters "Name=default-for-az,Values=true" \
  --query 'Subnets[0].SubnetId' \
  --output text \
  --region $REGION)

# Get ECS security group
SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=vitalforge-ecs-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text \
  --region $REGION)

echo "🚀 Running database migrations..."
TASK_ARN=$(aws ecs run-task \
  --cluster $CLUSTER \
  --task-definition vitalforge-api \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG],assignPublicIp=ENABLED}" \
  --overrides '{"containerOverrides":[{"name":"rails","command":["bin/rails","db:migrate"]}]}' \
  --region $REGION \
  --query 'tasks[0].taskArn' \
  --output text)

echo "✅ Migration task started: $TASK_ARN"
echo ""
echo "📊 Monitor task:"
echo "  aws ecs describe-tasks --cluster $CLUSTER --tasks $TASK_ARN --region $REGION"
echo ""
echo "📝 View logs:"
echo "  aws logs tail /ecs/vitalforge --follow --region $REGION"

