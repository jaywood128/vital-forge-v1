# Lightsail Outputs
output "lightsail_service_url" {
  description = "Lightsail Container Service public URL"
  value       = "https://${aws_lightsail_container_service.app.name}.${data.aws_region.current.name}.cs.amazonlightsail.com"
}

output "lightsail_container_service_name" {
  description = "Name of the Lightsail Container Service"
  value       = aws_lightsail_container_service.app.name
}

output "lightsail_database_name" {
  description = "Name of the Lightsail PostgreSQL database"
  value       = aws_lightsail_database.main.relational_database_name
}

output "lightsail_database_endpoint" {
  description = "Lightsail PostgreSQL database endpoint"
  value       = aws_lightsail_database.main.master_endpoint_address
  sensitive   = true
}

output "lightsail_database_port" {
  description = "Lightsail PostgreSQL database port"
  value       = aws_lightsail_database.main.master_endpoint_port
}

# ElastiCache Outputs
output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
  sensitive   = true
}

output "redis_port" {
  description = "ElastiCache Redis port"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].port
}

output "redis_cluster_id" {
  description = "ElastiCache Redis cluster ID"
  value       = aws_elasticache_cluster.redis.cluster_id
}

# ECR Output (kept for image storage)
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

# Route53 Output (kept for domain management)
output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

# Database connection string for deployment
output "database_url" {
  description = "Full PostgreSQL connection URL for Rails"
  value       = "postgresql://postgres:${var.lightsail_db_password}@${aws_lightsail_database.main.master_endpoint_address}:${aws_lightsail_database.main.master_endpoint_port}/vital_forge_production"
  sensitive   = true
}

# Redis connection string for deployment
output "redis_url" {
  description = "Full Redis connection URL for Sidekiq"
  value       = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}/0"
  sensitive   = true
}
