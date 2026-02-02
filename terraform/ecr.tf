# ECR Repository for Docker images

resource "aws_ecr_repository" "app" {
  name                 = "${var.app_name}-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.app_name}-api"
  }
}

# Allow Lightsail Container Service to pull from this private ECR repo.
# Without this repository policy, deployments can fail before the container starts (no app logs).
data "aws_iam_policy_document" "ecr_lightsail_pull" {
  statement {
    sid    = "AllowLightsailContainerServicePull"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [
        aws_lightsail_container_service.app.private_registry_access[0].ecr_image_puller_role[0].principal_arn
      ]
    }

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
  }
}

resource "aws_ecr_repository_policy" "lightsail_pull" {
  repository = aws_ecr_repository.app.name
  policy     = data.aws_iam_policy_document.ecr_lightsail_pull.json
}

# Lifecycle policy to keep only recent images
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

