# DEPRECATED_FARGATE: # ECS Cluster, Task Definition, and Service
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE: # ECS Cluster
# DEPRECATED_FARGATE: resource "aws_ecs_cluster" "main" {
# DEPRECATED_FARGATE:   name = "${var.app_name}-cluster"
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   setting {
# DEPRECATED_FARGATE:     name  = "containerInsights"
# DEPRECATED_FARGATE:     value = "enabled"
# DEPRECATED_FARGATE:   }
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   tags = {
# DEPRECATED_FARGATE:     Name = "${var.app_name}-cluster"
# DEPRECATED_FARGATE:   }
# DEPRECATED_FARGATE: }
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE: # ECS Task Definition
# DEPRECATED_FARGATE: resource "aws_ecs_task_definition" "app" {
# DEPRECATED_FARGATE:   family                   = "${var.app_name}-api"
# DEPRECATED_FARGATE:   network_mode             = "awsvpc"
# DEPRECATED_FARGATE:   requires_compatibilities = ["FARGATE"]
# DEPRECATED_FARGATE:   cpu                      = var.container_cpu
# DEPRECATED_FARGATE:   memory                   = var.container_memory
# DEPRECATED_FARGATE:   execution_role_arn       = aws_iam_role.ecs_task_execution.arn
# DEPRECATED_FARGATE:   task_role_arn            = aws_iam_role.ecs_task.arn
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   container_definitions = jsonencode([
# DEPRECATED_FARGATE:     {
# DEPRECATED_FARGATE:       name      = "rails"
# DEPRECATED_FARGATE:       image     = "${aws_ecr_repository.app.repository_url}:latest"
# DEPRECATED_FARGATE:       essential = true
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:       portMappings = [
# DEPRECATED_FARGATE:         {
# DEPRECATED_FARGATE:           containerPort = var.container_port
# DEPRECATED_FARGATE:           protocol      = "tcp"
# DEPRECATED_FARGATE:         }
# DEPRECATED_FARGATE:       ]
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:       environment = [
# DEPRECATED_FARGATE:         {
# DEPRECATED_FARGATE:           name  = "RAILS_ENV"
# DEPRECATED_FARGATE:           value = "production"
# DEPRECATED_FARGATE:         },
# DEPRECATED_FARGATE:         {
# DEPRECATED_FARGATE:           name  = "RAILS_SERVE_STATIC_FILES"
# DEPRECATED_FARGATE:           value = "true"
# DEPRECATED_FARGATE:         },
# DEPRECATED_FARGATE:         {
# DEPRECATED_FARGATE:           name  = "RAILS_LOG_TO_STDOUT"
# DEPRECATED_FARGATE:           value = "true"
# DEPRECATED_FARGATE:         }
# DEPRECATED_FARGATE:       ]
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:       secrets = [
# DEPRECATED_FARGATE:         {
# DEPRECATED_FARGATE:           name      = "DATABASE_URL"
# DEPRECATED_FARGATE:           valueFrom = "${aws_secretsmanager_secret.app.arn}:DATABASE_URL::"
# DEPRECATED_FARGATE:         },
# DEPRECATED_FARGATE:         {
# DEPRECATED_FARGATE:           name      = "RAILS_MASTER_KEY"
# DEPRECATED_FARGATE:           valueFrom = "${aws_secretsmanager_secret.app.arn}:RAILS_MASTER_KEY::"
# DEPRECATED_FARGATE:         },
# DEPRECATED_FARGATE:         {
# DEPRECATED_FARGATE:           name      = "SECRET_KEY_BASE"
# DEPRECATED_FARGATE:           valueFrom = "${aws_secretsmanager_secret.app.arn}:SECRET_KEY_BASE::"
# DEPRECATED_FARGATE:         }
# DEPRECATED_FARGATE:       ]
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:       logConfiguration = {
# DEPRECATED_FARGATE:         logDriver = "awslogs"
# DEPRECATED_FARGATE:         options = {
# DEPRECATED_FARGATE:           "awslogs-group"         = aws_cloudwatch_log_group.app.name
# DEPRECATED_FARGATE:           "awslogs-region"        = var.aws_region
# DEPRECATED_FARGATE:           "awslogs-stream-prefix" = "rails"
# DEPRECATED_FARGATE:         }
# DEPRECATED_FARGATE:       }
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:       healthCheck = {
# DEPRECATED_FARGATE:         command     = ["CMD-SHELL", "curl -f http://localhost:3000/api/v1/health || exit 1"]
# DEPRECATED_FARGATE:         interval    = 30
# DEPRECATED_FARGATE:         timeout     = 5
# DEPRECATED_FARGATE:         retries     = 3
# DEPRECATED_FARGATE:         startPeriod = 60
# DEPRECATED_FARGATE:       }
# DEPRECATED_FARGATE:     }
# DEPRECATED_FARGATE:   ])
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   tags = {
# DEPRECATED_FARGATE:     Name = "${var.app_name}-task-definition"
# DEPRECATED_FARGATE:   }
# DEPRECATED_FARGATE: }
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE: # ECS Service
# DEPRECATED_FARGATE: resource "aws_ecs_service" "app" {
# DEPRECATED_FARGATE:   name            = "${var.app_name}-api"
# DEPRECATED_FARGATE:   cluster         = aws_ecs_cluster.main.id
# DEPRECATED_FARGATE:   task_definition = aws_ecs_task_definition.app.arn
# DEPRECATED_FARGATE:   desired_count   = var.desired_count
# DEPRECATED_FARGATE:   launch_type     = "FARGATE"
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   network_configuration {
# DEPRECATED_FARGATE:     subnets          = data.aws_subnets.default.ids
# DEPRECATED_FARGATE:     security_groups  = [aws_security_group.ecs.id]
# DEPRECATED_FARGATE:     assign_public_ip = true
# DEPRECATED_FARGATE:   }
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   # TEMPORARILY DISABLED: Load balancer removed for direct ECS access
# DEPRECATED_FARGATE:   # load_balancer {
# DEPRECATED_FARGATE:   #   target_group_arn = aws_lb_target_group.app.arn
# DEPRECATED_FARGATE:   #   container_name   = "rails"
# DEPRECATED_FARGATE:   #   container_port   = var.container_port
# DEPRECATED_FARGATE:   # }
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   # TEMPORARILY DISABLED: No longer depends on ALB listeners
# DEPRECATED_FARGATE:   # depends_on = [
# DEPRECATED_FARGATE:   #   aws_lb_listener.https,
# DEPRECATED_FARGATE:   #   aws_lb_listener.http
# DEPRECATED_FARGATE:   # ]
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   tags = {
# DEPRECATED_FARGATE:     Name = "${var.app_name}-service"
# DEPRECATED_FARGATE:   }
# DEPRECATED_FARGATE: }
# DEPRECATED_FARGATE: 
