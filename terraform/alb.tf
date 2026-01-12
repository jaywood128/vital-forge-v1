# Application Load Balancer
# TEMPORARILY DISABLED: Removed for direct ECS access

# resource "aws_lb" "main" {
#   name               = "${var.app_name}-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb.id]
#   subnets            = data.aws_subnets.default.ids
#
#   enable_deletion_protection = false
#   enable_http2              = true
#   enable_cross_zone_load_balancing = true
#
#   tags = {
#     Name = "${var.app_name}-alb"
#   }
# }

# Target Group for ECS tasks
# resource "aws_lb_target_group" "app" {
#   name        = "${var.app_name}-tg-v2"
#   port        = var.container_port
#   protocol    = "HTTP"
#   vpc_id      = data.aws_vpc.default.id
#   target_type = "ip"
#
#   health_check {
#     enabled             = true
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 5
#     interval            = 30
#     path                = "/api/v1/health"
#     protocol            = "HTTP"
#     matcher             = "200"
#   }
#
#   deregistration_delay = 30
#
#   tags = {
#     Name = "${var.app_name}-tg-v2"
#   }
# }

# HTTP Listener - redirects to HTTPS
# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = "80"
#   protocol          = "HTTP"
#
#   default_action {
#     type = "redirect"
#
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }

# HTTPS Listener
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   certificate_arn   = aws_acm_certificate_validation.main.certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app.arn
#   }
# }
