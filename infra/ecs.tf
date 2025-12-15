
# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/express-gateway-app"
  retention_in_days = var.log_retention_in_days

  tags = var.additional_tags
}

# ECS Express Gateway Service
resource "aws_ecs_express_gateway_service" "example" {
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  infrastructure_role_arn = aws_iam_role.ecs_infrastructure_role_for_express_services.arn
  health_check_path       = "/health"

  primary_container {
    image          = var.application_image
    container_port = var.application_port

    aws_logs_configuration {
      log_group = aws_cloudwatch_log_group.app.name
    }

    dynamic "environment" {
      for_each = var.application_env_vars
      content {
        name  = environment.key
        value = environment.value
      }
    }

    # Always include PORT environment variable
    environment {
      name  = "PORT"
      value = var.application_port
    }

    dynamic "secret" {
      for_each = var.application_env_secrets
      content {
        name       = secret.key
        value_from = secret.value
      }
    }
  }

  tags = var.additional_tags
}
