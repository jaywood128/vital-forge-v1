# Security Groups

# ALB Security Group - allows HTTP/HTTPS from internet
# TEMPORARILY DISABLED: ALB removed
# resource "aws_security_group" "alb" {
#   name        = "${var.app_name}-alb-sg"
#   description = "Security group for ${var.app_name} Application Load Balancer"
#   vpc_id      = data.aws_vpc.default.id
#
#   # Allow HTTP from anywhere
#   ingress {
#     description = "HTTP from internet"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   # Allow HTTPS from anywhere
#   ingress {
#     description = "HTTPS from internet"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   # Allow all outbound traffic
#   egress {
#     description = "Allow all outbound"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = {
#     Name = "${var.app_name}-alb-sg"
#   }
# }

# ECS Security Group - allows direct HTTP/HTTPS from internet
resource "aws_security_group" "ecs" {
  name        = "${var.app_name}-ecs-sg"
  description = "Security group for ${var.app_name} ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  # Allow HTTP from anywhere (for direct access without ALB)
  ingress {
    description = "HTTP from internet"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-ecs-sg"
  }
}

# RDS Security Group - allows traffic from ECS only
resource "aws_security_group" "rds" {
  name        = "${var.app_name}-rds-sg"
  description = "Security group for ${var.app_name} RDS database"
  vpc_id      = data.aws_vpc.default.id

  # Allow PostgreSQL from ECS tasks
  ingress {
    description     = "PostgreSQL from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-rds-sg"
  }
}

