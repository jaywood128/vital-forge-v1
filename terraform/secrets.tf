# DEPRECATED_FARGATE: # AWS Secrets Manager for sensitive configuration
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE: resource "aws_secretsmanager_secret" "app" {
# DEPRECATED_FARGATE:   name        = "${var.app_name}/production"
# DEPRECATED_FARGATE:   description = "Production secrets for ${var.app_name} Rails application"
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   recovery_window_in_days = 7
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   tags = {
# DEPRECATED_FARGATE:     Name = "${var.app_name}-production-secrets"
# DEPRECATED_FARGATE:   }
# DEPRECATED_FARGATE: }
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE: resource "aws_secretsmanager_secret_version" "app" {
# DEPRECATED_FARGATE:   secret_id = aws_secretsmanager_secret.app.id
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   secret_string = jsonencode({
# DEPRECATED_FARGATE:     DATABASE_URL     = var.database_url
# DEPRECATED_FARGATE:     RAILS_MASTER_KEY = var.rails_master_key
# DEPRECATED_FARGATE:     SECRET_KEY_BASE  = var.secret_key_base
# DEPRECATED_FARGATE:   })
# DEPRECATED_FARGATE: }
# DEPRECATED_FARGATE: 
