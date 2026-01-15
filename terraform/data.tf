# Data sources for existing AWS resources

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get all subnets in default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# DEPRECATED - Legacy RDS reference (no longer used with Lightsail)
# data "aws_db_instance" "vitalforge" {
#   db_instance_identifier = var.rds_identifier
# }

# Reference existing Route53 hosted zone
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Get current AWS caller identity
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

