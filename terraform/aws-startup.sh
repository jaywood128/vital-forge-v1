#!/bin/bash
set -e

# VitalForge AWS Startup Script
# Recreates infrastructure and deploys application

echo "🚀 VitalForge Infrastructure Startup"
echo "===================================="
echo ""

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
  echo "❌ Error: Run this script from the terraform/ directory"
  exit 1
fi

echo "📋 This will:"
echo "  1. Start Lightsail Database (if stopped)"
echo "  2. Create Lightsail Container Service"
echo "  3. Create ElastiCache Redis Cluster"
echo "  4. Deploy latest application image"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "❌ Startup cancelled"
  exit 0
fi

echo ""
echo "🔄 Applying Terraform configuration..."
terraform init -upgrade 2>&1 | grep -v "Terraform has been successfully initialized" || true
terraform apply -auto-approve

echo ""
echo "⏳ Waiting for infrastructure to be ready..."
sleep 10

# Get resource names from Terraform
DATABASE_NAME=$(terraform output -raw lightsail_database_name 2>/dev/null || echo "vitalforge-db")

echo ""
echo "▶️  Starting Lightsail Database (if stopped)..."
aws lightsail start-relational-database \
  --relational-database-name "$DATABASE_NAME" \
  2>/dev/null && echo "  ✅ Database starting..." || echo "  ℹ️  Database already running"

echo ""
echo "⏳ Waiting for database to be available (this may take 2-3 minutes)..."
sleep 30

# Check database status
DB_STATUS=$(aws lightsail get-relational-database \
  --relational-database-name "$DATABASE_NAME" \
  --query 'relationalDatabase.state' \
  --output text 2>/dev/null || echo "unknown")

echo "  Database status: $DB_STATUS"

if [ "$DB_STATUS" != "available" ]; then
  echo "  ⏳ Database still starting up. Check status with:"
  echo "     aws lightsail get-relational-database --relational-database-name $DATABASE_NAME"
fi

echo ""
echo "🐳 Deploying application to Lightsail..."
if [ -f "deploy-lightsail.sh" ]; then
  chmod +x deploy-lightsail.sh
  ./deploy-lightsail.sh
else
  echo "  ⚠️  deploy-lightsail.sh not found. You'll need to deploy manually."
fi

echo ""
echo "✅ Startup complete!"
echo ""
echo "📊 Check status:"
echo "  Container Service:"
echo "    aws lightsail get-container-services --service-name \$(terraform output -raw lightsail_container_service_name)"
echo ""
echo "  Database:"
echo "    aws lightsail get-relational-database --relational-database-name $DATABASE_NAME"
echo ""
echo "  Redis:"
echo "    aws elasticache describe-cache-clusters --cache-cluster-id \$(terraform output -raw redis_cluster_id)"
echo ""
echo "🌐 Application URL:"
terraform output lightsail_service_url 2>/dev/null || echo "  (Run terraform output to see URL)"
echo ""
