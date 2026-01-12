# TEMPORARILY DISABLED: ALB removed
# output "alb_dns_name" {
#   description = "DNS name of the Application Load Balancer"
#   value       = aws_lb.main.dns_name
# }

# output "alb_zone_id" {
#   description = "Zone ID of the Application Load Balancer"
#   value       = aws_lb.main.zone_id
# }

# NOTE: Without ALB, this URL is not valid. Access ECS task directly via public IP on port 3000
# output "api_url" {
#   description = "Full API URL"
#   value       = "https://${var.api_subdomain}.${var.domain_name}"
# }

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.app.name
}

output "rds_endpoint" {
  description = "RDS endpoint (from existing database)"
  value       = data.aws_db_instance.vitalforge.endpoint
}

# TEMPORARILY DISABLED: ACM certificate removed with ALB
# output "acm_certificate_arn" {
#   description = "ARN of the ACM certificate"
#   value       = aws_acm_certificate.main.arn
# }

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs.id
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

