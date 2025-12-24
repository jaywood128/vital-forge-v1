# AWS Secrets Manager for sensitive configuration

resource "aws_secretsmanager_secret" "app" {
  name        = "${var.app_name}/production"
  description = "Production secrets for ${var.app_name} Rails application"

  recovery_window_in_days = 7

  tags = {
    Name = "${var.app_name}-production-secrets"
  }
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id

  secret_string = jsonencode({
    DATABASE_URL     = var.database_url
    RAILS_MASTER_KEY = var.rails_master_key
    SECRET_KEY_BASE  = var.secret_key_base
  })
}

