# AWS Lightsail Resources for VitalForge
# Container Service + PostgreSQL Database

# Lightsail Container Service
resource "aws_lightsail_container_service" "app" {
  name  = "${var.app_name}-container"
  power = "nano" # $7/month - 512MB RAM, 0.25 vCPU
  scale = 1

  # Enable ECR access for pulling Docker images
  private_registry_access {
    ecr_image_puller_role {
      is_active = true
    }
  }

  tags = {
    Name        = "${var.app_name}-container-service"
    Environment = var.environment
  }
}

# Lightsail PostgreSQL Database
resource "aws_lightsail_database" "main" {
  relational_database_name = "${var.app_name}-db"
  availability_zone        = "${var.aws_region}a"
  master_database_name     = "vital_forge_production"
  master_username          = "postgres"
  master_password          = var.lightsail_db_password
  
  # PostgreSQL 16
  blueprint_id = "postgres_16"
  
  # Micro plan: $15/month - 1GB RAM, 1 vCPU, 40GB SSD
  bundle_id = "micro_2_0"
  
  # Skip final snapshot for development
  skip_final_snapshot = var.environment == "staging" ? true : false
  
  # Enable backups for production
  backup_retention_enabled = var.environment == "production" ? true : false
  
  # Public accessibility (required for Lightsail containers)
  publicly_accessible = true
  
  tags = {
    Name        = "${var.app_name}-database"
    Environment = var.environment
  }
}

