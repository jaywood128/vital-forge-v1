variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "app_name" {
  description = "Application name used for resource naming"
  type        = string
  default     = "vitalforge-v1"
}

variable "environment" {
  description = "Environment name (production, staging, etc.)"
  type        = string
  default     = "staging"
}

variable "domain_name" {
  description = "Root domain name (e.g., yourdomain.com)"
  type        = string
}

variable "api_subdomain" {
  description = "Subdomain for API (e.g., api)"
  type        = string
  default     = "api"
}

# Lightsail Database Password
variable "lightsail_db_password" {
  description = "Master password for Lightsail PostgreSQL database"
  type        = string
  sensitive   = true
}

# Rails Secrets (still needed for Lightsail deployment)
variable "rails_master_key" {
  description = "Rails master key for credentials"
  type        = string
  sensitive   = true
}

variable "secret_key_base" {
  description = "Rails secret key base"
  type        = string
  sensitive   = true
}

# OpenAI API Key for AI features
variable "openai_api_key" {
  description = "OpenAI API key for weekly feedback generation"
  type        = string
  sensitive   = true
  default     = ""
}

# Honeybadger API Key for error tracking
variable "honeybadger_api_key" {
  description = "Honeybadger API key for error tracking"
  type        = string
  sensitive   = true
  default     = ""
}

# Legacy variables (kept for backwards compatibility but not used)
variable "rds_identifier" {
  description = "DEPRECATED - Legacy RDS instance identifier"
  type        = string
  default     = "database-1"
}

variable "container_cpu" {
  description = "DEPRECATED - Legacy CPU units for ECS container"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "DEPRECATED - Legacy memory for ECS container"
  type        = number
  default     = 512
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "database_url" {
  description = "DEPRECATED - Legacy PostgreSQL connection URL"
  type        = string
  sensitive   = true
  default     = ""
}

variable "desired_count" {
  description = "DEPRECATED - Legacy desired number of ECS tasks"
  type        = number
  default     = 1
}

