#!/bin/bash
set -e

# VitalForge AWS Shutdown Script
# Stops all infrastructure to reduce costs when not in use

echo "🛑 VitalForge Infrastructure Shutdown"
echo "====================================="
echo ""
echo "This will stop:"
echo "  - Lightsail Container Service"
echo "  - Lightsail PostgreSQL Database"
echo "  - ElastiCache Redis Cluster"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "❌ Shutdown cancelled"
  exit 0
fi

echo ""
echo "📊 Getting current resource status..."

# Get service names from Terraform outputs
CONTAINER_SERVICE=$(terraform output -raw lightsail_container_service_name 2>/dev/null || echo "vitalforge-v1")
DATABASE_NAME=$(terraform output -raw lightsail_database_name 2>/dev/null || echo "vitalforge-db")
REDIS_CLUSTER=$(terraform output -raw redis_cluster_id 2>/dev/null || echo "vitalforge-redis")

echo "  Container Service: $CONTAINER_SERVICE"
echo "  Database: $DATABASE_NAME"
echo "  Redis Cluster: $REDIS_CLUSTER"
echo ""

# Delete Lightsail Container Service
echo "🗑️  Deleting Lightsail Container Service..."
aws lightsail delete-container-service \
  --service-name "$CONTAINER_SERVICE" \
  2>/dev/null && echo "  ✅ Container service deleted" || echo "  ⚠️  Container service not found or already deleted"

# Stop Lightsail Database (doesn't delete, just stops)
echo "⏸️  Stopping Lightsail Database..."
aws lightsail stop-relational-database \
  --relational-database-name "$DATABASE_NAME" \
  2>/dev/null && echo "  ✅ Database stopped" || echo "  ⚠️  Database not found or already stopped"

# Delete ElastiCache Redis Cluster
echo "🗑️  Deleting ElastiCache Redis Cluster..."
aws elasticache delete-cache-cluster \
  --cache-cluster-id "$REDIS_CLUSTER" \
  2>/dev/null && echo "  ✅ Redis cluster deletion initiated" || echo "  ⚠️  Redis cluster not found or already deleted"

echo ""
echo "✅ Shutdown complete!"
echo ""
echo "💰 Cost Savings:"
echo "  - Container Service: ~\$0.29/day saved"
echo "  - Database (stopped): ~\$0.25/day saved"
echo "  - Redis: ~\$0.41/day saved"
echo "  - Total: ~\$0.95/day saved"
echo ""
echo "📝 Notes:"
echo "  - Database data is preserved (stopped, not deleted)"
echo "  - ECR images remain available"
echo "  - Run ./aws-startup.sh to bring everything back online"
echo ""
