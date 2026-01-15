# DEPRECATED_FARGATE: # CloudWatch Log Group for ECS container logs
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE: resource "aws_cloudwatch_log_group" "app" {
# DEPRECATED_FARGATE:   name              = "/ecs/${var.app_name}"
# DEPRECATED_FARGATE:   retention_in_days = 7
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   tags = {
# DEPRECATED_FARGATE:     Name = "${var.app_name}-logs"
# DEPRECATED_FARGATE:   }
# DEPRECATED_FARGATE: }
# DEPRECATED_FARGATE: 
