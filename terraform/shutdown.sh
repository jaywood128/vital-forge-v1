#!/bin/bash

# VitalForge AWS Shutdown Script
# Safely stops all running resources to minimize costs overnight

set -e  # Exit on error

echo "🌙 VitalForge AWS Shutdown Script"
echo "=================================="
echo ""

# Configuration
CLUSTER_NAME="vitalforge-v1-cluster"
SERVICE_NAME="vitalforge-v1-api"
DB_INSTANCE="database-1"
REGION="us-east-1"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Scale down ECS service
echo "📦 Step 1: Scaling ECS service to 0 tasks..."
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "$SERVICE_NAME" \
  --desired-count 0 \
  --region "$REGION" \
  --output text > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ ECS service scaled to 0${NC}"
else
  echo -e "${RED}❌ Failed to scale ECS service${NC}"
  exit 1
fi

# Step 2: Stop RDS database
echo ""
echo "🗄️  Step 2: Stopping RDS database..."
aws rds stop-db-instance \
  --db-instance-identifier "$DB_INSTANCE" \
  --region "$REGION" \
  --output text > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ RDS database stopping (will take 2-5 minutes)${NC}"
else
  # Check if already stopped
  STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE" \
    --region "$REGION" \
    --query 'DBInstances[0].DBInstanceStatus' \
    --output text 2>/dev/null)
  
  if [ "$STATUS" = "stopped" ]; then
    echo -e "${YELLOW}⚠️  RDS database already stopped${NC}"
  else
    echo -e "${RED}❌ Failed to stop RDS database (status: $STATUS)${NC}"
  fi
fi

# Step 3: Verify shutdown
echo ""
echo "🔍 Step 3: Verifying shutdown..."
sleep 2

# Check ECS tasks
TASK_COUNT=$(aws ecs list-tasks \
  --cluster "$CLUSTER_NAME" \
  --region "$REGION" \
  --query 'length(taskArns)' \
  --output text 2>/dev/null)

if [ "$TASK_COUNT" = "0" ]; then
  echo -e "${GREEN}✅ ECS: 0 tasks running${NC}"
else
  echo -e "${YELLOW}⚠️  ECS: $TASK_COUNT tasks still running (stopping...)${NC}"
fi

# Check RDS status
RDS_STATUS=$(aws rds describe-db-instances \
  --db-instance-identifier "$DB_INSTANCE" \
  --region "$REGION" \
  --query 'DBInstances[0].DBInstanceStatus' \
  --output text 2>/dev/null)

if [ "$RDS_STATUS" = "stopped" ] || [ "$RDS_STATUS" = "stopping" ]; then
  echo -e "${GREEN}✅ RDS: $RDS_STATUS${NC}"
else
  echo -e "${YELLOW}⚠️  RDS: $RDS_STATUS${NC}"
fi

# Summary
echo ""
echo "=================================="
echo -e "${GREEN}✅ Shutdown Complete!${NC}"
echo ""
echo "💰 Cost Savings:"
echo "   • Overnight: ~\$0.50"
echo "   • Monthly (with these settings): ~\$17-18"
echo ""
echo "📊 What's Still Running:"
echo "   • Application Load Balancer (~\$16/month)"
echo "   • ECR Docker images (~\$0.10/month)"
echo "   • CloudWatch logs (~\$0.50/month)"
echo "   • Secrets Manager (~\$0.40/month)"
echo "   • Route53 DNS (~\$0.50/month)"
echo ""
echo "🌅 To Restart Tomorrow:"
echo "   Run: ./startup.sh"
echo "   Or manually:"
echo "   1. aws rds start-db-instance --db-instance-identifier $DB_INSTANCE --region $REGION"
echo "   2. aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count 1 --region $REGION"
echo ""
echo "😴 Sleep well!"

