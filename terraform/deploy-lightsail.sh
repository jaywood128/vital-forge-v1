#!/bin/bash
set -e

# VitalForge Lightsail Deployment Script
# Builds Docker image and deploys to Lightsail Container Service

echo "🚀 VitalForge Lightsail Deployment"
echo "=================================="
echo ""

# Flags
DEPLOY_ONLY=false

usage() {
  cat <<'USAGE'
Usage:
  ./deploy-lightsail.sh [--deploy-only]

Options:
  --deploy-only   Skip docker build/tag/push and only create a new Lightsail deployment
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --deploy-only)
      DEPLOY_ONLY=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "❌ Unknown argument: $arg"
      echo ""
      usage
      exit 1
      ;;
  esac
done

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
  echo "❌ Error: Run this script from the terraform/ directory"
  exit 1
fi

# Capture absolute path to terraform directory (script changes directories later)
TERRAFORM_DIR="$(pwd)"
TFVARS_FILE="${TERRAFORM_DIR}/terraform.tfvars"

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

if [ "$DEPLOY_ONLY" = true ]; then
  echo "⏩ Deploy-only mode enabled (skipping docker build/tag/push)."
  echo "   Using existing image tag: $ECR_URL:latest"
else
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
fi

echo ""
echo "🔄 Deploying to Lightsail Container Service..."

# Read environment variables
if [ -z "$RAILS_MASTER_KEY" ]; then
  echo "⚠️  RAILS_MASTER_KEY not set. Reading from terraform.tfvars..."
  RAILS_MASTER_KEY=$(grep -E '^rails_master_key' "$TFVARS_FILE" 2>/dev/null | cut -d'"' -f2 || echo "")
fi

if [ -z "$SECRET_KEY_BASE" ]; then
  echo "⚠️  SECRET_KEY_BASE not set. Reading from terraform.tfvars..."
  SECRET_KEY_BASE=$(grep -E '^secret_key_base' "$TFVARS_FILE" 2>/dev/null | cut -d'"' -f2 || echo "")
fi

if [ -z "$OPENAI_API_KEY" ]; then
  OPENAI_API_KEY=$(grep -E '^openai_api_key' "$TFVARS_FILE" 2>/dev/null | cut -d'"' -f2 || echo "")
fi

if [ -z "$HONEYBADGER_API_KEY" ]; then
  HONEYBADGER_API_KEY=$(grep -E '^honeybadger_api_key' "$TFVARS_FILE" 2>/dev/null | cut -d'"' -f2 || echo "")
fi

if [ -z "$RAILS_MASTER_KEY" ] || [ -z "$SECRET_KEY_BASE" ]; then
  echo "❌ Error: Missing Rails secrets. Ensure terraform/terraform.tfvars contains rails_master_key and secret_key_base,"
  echo "   or export RAILS_MASTER_KEY and SECRET_KEY_BASE in your shell before running this script."
  exit 1
fi

# Create deployment JSON (use Python to guarantee correct JSON escaping)
STARTUP_CMD='set -euxo pipefail

# Redacted environment checks (do not print secrets)
echo "RAILS_ENV=${RAILS_ENV:-}"
if [ -n "${RAILS_MASTER_KEY:-}" ]; then echo "RAILS_MASTER_KEY_set=yes"; else echo "RAILS_MASTER_KEY_set=no"; fi
if [ -n "${SECRET_KEY_BASE:-}" ]; then echo "SECRET_KEY_BASE_set=yes"; else echo "SECRET_KEY_BASE_set=no"; fi

# Show only hosts (not credentials)
DB_HOST="${DATABASE_URL#*@}"
DB_HOST="${DB_HOST%%[:/]*}"
REDIS_HOST="${REDIS_URL#*//}"
REDIS_HOST="${REDIS_HOST%%[:/]*}"
echo "DATABASE_URL_host=${DB_HOST}"
echo "REDIS_URL_host=${REDIS_HOST}"

echo "Running db:prepare (with trace)..."
./bin/rails db:prepare --trace

echo "Starting Rails server..."
exec ./bin/rails server -b 0.0.0.0 -p 3000'

python3 - <<PY
import json

deployment = {
  "containers": {
    "rails": {
      "image": "${ECR_URL}:latest",
      "command": ["bash", "-lc", """${STARTUP_CMD}"""],
      "ports": {"3000": "HTTP"},
      "environment": {
        "RAILS_ENV": "production",
        "RAILS_LOG_TO_STDOUT": "true",
        "RAILS_LOG_LEVEL": "debug",
        "RAILS_SERVE_STATIC_FILES": "true",
        "DATABASE_URL": """${DB_URL}""",
        "REDIS_URL": """${REDIS_URL}""",
        "RAILS_MASTER_KEY": """${RAILS_MASTER_KEY}""",
        "SECRET_KEY_BASE": """${SECRET_KEY_BASE}""",
        "OPENAI_API_KEY": """${OPENAI_API_KEY}""",
        "HONEYBADGER_API_KEY": """${HONEYBADGER_API_KEY}""",
      },
    }
  },
  "publicEndpoint": {
    "containerName": "rails",
    "containerPort": 3000,
    "healthCheck": {
      "path": "/api/v1/health",
      "intervalSeconds": 30,
      "timeoutSeconds": 5,
      "unhealthyThreshold": 2,
      "healthyThreshold": 2,
      "successCodes": "200-499",
    },
  },
}

with open("/tmp/lightsail-deployment.json", "w") as f:
  json.dump(deployment, f, indent=2)
PY

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
echo "  aws lightsail get-container-service-deployments --region $REGION --service-name $SERVICE_NAME"
echo ""
echo "📝 View logs:"
echo "  aws lightsail get-container-log --region $REGION --service-name $SERVICE_NAME --container-name rails"
echo ""
echo "🌐 Your API will be available at:"
cd "$TERRAFORM_DIR"
terraform output lightsail_service_url
echo ""
echo "⏳ Note: First deployment may take 5-10 minutes"
echo ""

