# DEPRECATED_FARGATE: # IAM Roles and Policies for ECS
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE: # ECS Task Execution Role - allows ECS to pull images and write logs
# DEPRECATED_FARGATE: resource "aws_iam_role" "ecs_task_execution" {
# DEPRECATED_FARGATE:   name = "${var.app_name}-ecs-task-execution-role"
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   assume_role_policy = jsonencode({
# DEPRECATED_FARGATE:     Version = "2012-10-17"
# DEPRECATED_FARGATE:     Statement = [
# DEPRECATED_FARGATE:       {
# DEPRECATED_FARGATE:         Effect = "Allow"
# DEPRECATED_FARGATE:         Principal = {
# DEPRECATED_FARGATE:           Service = "ecs-tasks.amazonaws.com"
# DEPRECATED_FARGATE:         }
# DEPRECATED_FARGATE:         Action = "sts:AssumeRole"
# DEPRECATED_FARGATE:       }
# DEPRECATED_FARGATE:     ]
# DEPRECATED_FARGATE:   })
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   tags = {
# DEPRECATED_FARGATE:     Name = "${var.app_name}-ecs-task-execution-role"
# DEPRECATED_FARGATE:   }
# DEPRECATED_FARGATE: }
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE: # Attach AWS managed policy for ECS task execution
# DEPRECATED_FARGATE: resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
# DEPRECATED_FARGATE:   role       = aws_iam_role.ecs_task_execution.name
# DEPRECATED_FARGATE:   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# DEPRECATED_FARGATE: }
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE: # Custom policy for Secrets Manager access
# DEPRECATED_FARGATE: resource "aws_iam_role_policy" "secrets_manager_access" {
# DEPRECATED_FARGATE:   name = "${var.app_name}-secrets-manager-access"
# DEPRECATED_FARGATE:   role = aws_iam_role.ecs_task_execution.id
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   policy = jsonencode({
# DEPRECATED_FARGATE:     Version = "2012-10-17"
# DEPRECATED_FARGATE:     Statement = [
# DEPRECATED_FARGATE:       {
# DEPRECATED_FARGATE:         Effect = "Allow"
# DEPRECATED_FARGATE:         Action = [
# DEPRECATED_FARGATE:           "secretsmanager:GetSecretValue"
# DEPRECATED_FARGATE:         ]
# DEPRECATED_FARGATE:         Resource = [
# DEPRECATED_FARGATE:           aws_secretsmanager_secret.app.arn
# DEPRECATED_FARGATE:         ]
# DEPRECATED_FARGATE:       }
# DEPRECATED_FARGATE:     ]
# DEPRECATED_FARGATE:   })
# DEPRECATED_FARGATE: }
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE: # ECS Task Role - allows the container itself to access AWS services
# DEPRECATED_FARGATE: resource "aws_iam_role" "ecs_task" {
# DEPRECATED_FARGATE:   name = "${var.app_name}-ecs-task-role"
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   assume_role_policy = jsonencode({
# DEPRECATED_FARGATE:     Version = "2012-10-17"
# DEPRECATED_FARGATE:     Statement = [
# DEPRECATED_FARGATE:       {
# DEPRECATED_FARGATE:         Effect = "Allow"
# DEPRECATED_FARGATE:         Principal = {
# DEPRECATED_FARGATE:           Service = "ecs-tasks.amazonaws.com"
# DEPRECATED_FARGATE:         }
# DEPRECATED_FARGATE:         Action = "sts:AssumeRole"
# DEPRECATED_FARGATE:       }
# DEPRECATED_FARGATE:     ]
# DEPRECATED_FARGATE:   })
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE:   tags = {
# DEPRECATED_FARGATE:     Name = "${var.app_name}-ecs-task-role"
# DEPRECATED_FARGATE:   }
# DEPRECATED_FARGATE: }
# DEPRECATED_FARGATE: 
# DEPRECATED_FARGATE: # Add policies to task role if needed (e.g., S3 access for Active Storage)
# DEPRECATED_FARGATE: # resource "aws_iam_role_policy" "task_s3_access" {
# DEPRECATED_FARGATE: #   name = "${var.app_name}-task-s3-access"
# DEPRECATED_FARGATE: #   role = aws_iam_role.ecs_task.id
# DEPRECATED_FARGATE: #   policy = jsonencode({
# DEPRECATED_FARGATE: #     Version = "2012-10-17"
# DEPRECATED_FARGATE: #     Statement = [
# DEPRECATED_FARGATE: #       {
# DEPRECATED_FARGATE: #         Effect = "Allow"
# DEPRECATED_FARGATE: #         Action = [
# DEPRECATED_FARGATE: #           "s3:GetObject",
# DEPRECATED_FARGATE: #           "s3:PutObject",
# DEPRECATED_FARGATE: #           "s3:DeleteObject"
# DEPRECATED_FARGATE: #         ]
# DEPRECATED_FARGATE: #         Resource = ["arn:aws:s3:::your-bucket/*"]
# DEPRECATED_FARGATE: #       }
# DEPRECATED_FARGATE: #     ]
# DEPRECATED_FARGATE: #   })
# DEPRECATED_FARGATE: # }
# DEPRECATED_FARGATE: 
