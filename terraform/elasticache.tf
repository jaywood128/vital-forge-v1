# AWS ElastiCache Redis for Sidekiq
# Provides Redis instance for background job processing

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.app_name}-redis-subnet"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name        = "${var.app_name}-redis-subnet-group"
    Environment = var.environment
  }
}

# Security Group for Redis
resource "aws_security_group" "redis" {
  name        = "${var.app_name}-redis-sg"
  description = "Security group for ${var.app_name} ElastiCache Redis"
  vpc_id      = data.aws_vpc.default.id

  # Allow Redis from anywhere in VPC
  # In production, tighten this to specific security groups
  ingress {
    description = "Redis from VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-redis-sg"
    Environment = var.environment
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.app_name}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro" # ~$12.41/month
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  # Snapshot settings
  snapshot_retention_limit = var.environment == "production" ? 5 : 0
  snapshot_window          = "03:00-05:00"

  # Maintenance window
  maintenance_window = "mon:05:00-mon:07:00"

  tags = {
    Name        = "${var.app_name}-redis"
    Environment = var.environment
  }
}

