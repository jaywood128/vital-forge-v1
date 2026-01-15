#!/bin/bash

# VitalForge AWS Startup Script
# Starts all stopped resources to resume development

set -e  # Exit on error

echo "🌅 VitalForge AWS Startup Script"
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
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Start RDS database
echo "🗄️  Step 1: Starting RDS database..."
aws rds start-db-instance \
  --db-instance-identifier "$DB_INSTANCE" \
  --region "$REGION" \
  --output text > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ RDS database starting...${NC}"
  echo -e "${BLUE}⏳ Waiting for database to be available (this takes 5-10 minutes)...${NC}"
  
  # Wait for database to be available
  aws rds wait db-instance-available \
    --db-instance-identifier "$DB_INSTANCE" \
    --region "$REGION"
  
  echo -e "${GREEN}✅ RDS database is now available!${NC}"
else
  # Check if already running
  STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE" \
    --region "$REGION" \
    --query 'DBInstances[0].DBInstanceStatus' \
    --output text 2>/dev/null)
  
  if [ "$STATUS" = "available" ]; then
    echo -e "${YELLOW}⚠️  RDS database already running${NC}"
  else
    echo -e "${RED}❌ Failed to start RDS database (status: $STATUS)${NC}"
    exit 1
  fi
fi

# Step 2: Scale up ECS service
echo ""
echo "📦 Step 2: Scaling ECS service to 1 task..."
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "$SERVICE_NAME" \
  --desired-count 1 \
  --region "$REGION" \
  --output text > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ ECS service scaling to 1 task${NC}"
  echo -e "${BLUE}⏳ Waiting for task to start (this takes 2-3 minutes)...${NC}"
  
  # Wait for service to stabilize
  sleep 10
  
  # Check if task is running
  for i in {1..30}; do
    RUNNING_COUNT=$(aws ecs describe-services \
      --cluster "$CLUSTER_NAME" \
      --services "$SERVICE_NAME" \
      --region "$REGION" \
      --query 'services[0].runningCount' \
      --output text 2>/dev/null)
    
    if [ "$RUNNING_COUNT" = "1" ]; then
      echo -e "${GREEN}✅ ECS task is now running!${NC}"
      break
    fi
    
    echo -e "${BLUE}   Still starting... ($i/30)${NC}"
    sleep 10
  done
else
  echo -e "${RED}❌ Failed to scale ECS service${NC}"
  exit 1
fi

# Step 3: Get application URL
echo ""
echo "🔍 Step 3: Getting application URL..."
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --region "$REGION" \
  --query 'LoadBalancers[?contains(LoadBalancerName, `vitalforge`)].DNSName' \
  --output text 2>/dev/null)

if [ -n "$ALB_DNS" ]; then
  echo -e "${GREEN}✅ Application URL: http://$ALB_DNS${NC}"
else
  echo -e "${YELLOW}⚠️  Could not retrieve ALB URL${NC}"
fi

# Step 4: Check logs
echo ""
echo "📋 Step 4: Checking recent logs..."
LOG_GROUP="/ecs/vitalforge-v1-api"

# Get the most recent log stream
LATEST_STREAM=$(aws logs describe-log-streams \
  --log-group-name "$LOG_GROUP" \
  --region "$REGION" \
  --order-by LastEventTime \
  --descending \
  --max-items 1 \
  --query 'logStreams[0].logStreamName' \
  --output text 2>/dev/null)

if [ -n "$LATEST_STREAM" ] && [ "$LATEST_STREAM" != "None" ]; then
  echo -e "${BLUE}Latest logs from: $LATEST_STREAM${NC}"
  echo ""
  aws logs tail "$LOG_GROUP" \
    --region "$REGION" \
    --since 5m \
    --format short 2>/dev/null | tail -20
else
  echo -e "${YELLOW}⚠️  No recent logs found yet (task may still be starting)${NC}"
fi

# Summary
echo ""
echo "=================================="
echo -e "${GREEN}✅ Startup Complete!${NC}"
echo ""
echo "📊 Current Status:"
echo "   • ECS Tasks: $RUNNING_COUNT running"
echo "   • RDS Database: available"
echo "   • Application: http://$ALB_DNS"
echo ""
echo "🔧 Useful Commands:"
echo "   • View logs: aws logs tail $LOG_GROUP --follow --region $REGION"
echo "   • Check tasks: aws ecs list-tasks --cluster $CLUSTER_NAME --region $REGION"
echo "   • Shutdown: ./shutdown.sh"
echo ""
echo "🚀 Ready to develop!"

