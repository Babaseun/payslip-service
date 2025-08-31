# ECS Cluster
resource "aws_ecs_cluster" "payslip_cluster" {
  provider = aws.assume
  name     = "${var.environment}-payslip-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
  }
}

# Task Execution IAM Role
resource "aws_iam_role" "ecs_task_execution_role" {
  provider = aws.assume
  name     = "${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
  }
}

# IAM Role for ECS Auto Scaling
resource "aws_iam_role" "ecs_autoscale_role" {
  provider = aws.assume
  name     = "${var.environment}-ecs-autoscale-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
  }
}

# IAM Policy for ECS Auto Scaling
resource "aws_iam_role_policy_attachment" "ecs_autoscale_policy" {
  provider   = aws.assume
  role       = aws_iam_role.ecs_autoscale_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

# Attach the AmazonECSTaskExecutionRolePolicy to the role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  provider   = aws.assume
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition for Server
resource "aws_ecs_task_definition" "payslip_task" {
  provider                 = aws.assume
  family                   = "${var.environment}-payslip-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "payslip-server-app"
    image     = var.payslip_ecr_image_uri
    essential = true
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "ENVIRONMENT"
        value = var.environment
      },
      {
        name  = "SERVER_PORT"
        value = "5000"
      }
    ]

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:5000/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
        "awslogs-region"        = local.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
  }
}

# Security Group for ECS Service
resource "aws_security_group" "ecs_service_sg" {
  provider    = aws.assume
  name        = "${var.environment}-ecs-service-sg"
  description = "Security group for ECS service allowing traffic from NLB"
  vpc_id      = aws_vpc.payslip_vpc.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "payslip_service" {
  provider            = aws.assume
  name                = "${var.environment}-payslip-service"
  cluster             = aws_ecs_cluster.payslip_cluster.id
  task_definition     = aws_ecs_task_definition.payslip_task.arn
  desired_count       = var.ecs_desired_count
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"

  network_configuration {
    subnets          = [aws_subnet.public_zone1.id]
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.payslip_tg.arn
    container_name   = "payslip-server-app"
    container_port   = 5000
  }

  depends_on = [aws_lb_listener.payslip_listener]

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  provider          = aws.assume
  name              = "/ecs/${var.environment}-payslip-task"
  retention_in_days = 7

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
  }
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "payslip_scaling_target" {
  provider           = aws.assume
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.payslip_cluster.name}/${aws_ecs_service.payslip_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.ecs_min_capacity
  max_capacity       = var.ecs_max_capacity
  role_arn           = aws_iam_role.ecs_autoscale_role.arn

  depends_on = [aws_ecs_service.payslip_service]
}

# CPU Utilization Scaling Policy - More aggressive for traffic spikes
resource "aws_appautoscaling_policy" "payslip_cpu_scaling" {
  provider           = aws.assume
  name               = "${var.environment}-payslip-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60  # Lower target from 70% to 60% (more aggressive scaling)
    scale_in_cooldown  = 300 # 5 minutes
    scale_out_cooldown = 30  # Reduced from 60 to 30 seconds (faster scale-out)
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

# Memory Utilization Scaling Policy - More aggressive for traffic spikes
resource "aws_appautoscaling_policy" "payslip_memory_scaling" {
  provider           = aws.assume
  name               = "${var.environment}-payslip-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 60  # Lower target from 65% to 60% (more aggressive scaling)
    scale_in_cooldown  = 300 # 5 minutes
    scale_out_cooldown = 30  # Reduced from 60 to 30 seconds (faster scale-out)
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

# Scheduled Scaling Policies for Morning Peak (8–10 AM) - Scale up 1 hour early
resource "aws_appautoscaling_scheduled_action" "morning_scale_up" {
  provider           = aws.assume
  name               = "${var.environment}-morning-scale-up"
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  schedule           = "cron(0 7 ? * MON-FRI *)" # 7:00 AM - Scale up 1 hour before peak
  timezone           = "Europe/Rome"
  start_time         = timeadd(timestamp(), "24h")

  scalable_target_action {
    min_capacity = var.morning_min_capacity
    max_capacity = var.morning_max_capacity
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

resource "aws_appautoscaling_scheduled_action" "morning_scale_down" {
  provider           = aws.assume
  name               = "${var.environment}-morning-scale-down"
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  schedule           = "cron(0 10 ? * MON-FRI *)" # 10:00 AM Monday-Friday
  timezone           = "Europe/Rome"
  start_time         = timeadd(timestamp(), "24h")

  scalable_target_action {
    min_capacity = var.regular_min_capacity
    max_capacity = var.regular_max_capacity
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

# Scheduled Scaling Policies for Evening Peak (5–7 PM) - Scale up 1 hour early
resource "aws_appautoscaling_scheduled_action" "evening_scale_up" {
  provider           = aws.assume
  name               = "${var.environment}-evening-scale-up"
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  schedule           = "cron(0 16 ? * MON-FRI *)" # 4:00 PM - Scale up 1 hour before peak
  timezone           = "Europe/Rome"
  start_time         = timeadd(timestamp(), "24h")

  scalable_target_action {
    min_capacity = var.evening_min_capacity
    max_capacity = var.evening_max_capacity
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

resource "aws_appautoscaling_scheduled_action" "evening_scale_down" {
  provider           = aws.assume
  name               = "${var.environment}-evening-scale-down"
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  schedule           = "cron(0 19 ? * MON-FRI *)" # 7:00 PM Monday-Friday
  timezone           = "Europe/Rome"
  start_time         = timeadd(timestamp(), "24h")

  scalable_target_action {
    min_capacity = var.regular_min_capacity
    max_capacity = var.regular_max_capacity
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

# End of Month Scaling - More aggressive for last 7 days
resource "aws_appautoscaling_scheduled_action" "end_of_month_scale_up" {
  provider           = aws.assume
  name               = "${var.environment}-end-of-month-scale-up"
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  schedule           = "cron(0 0 25-31 * ? *)" # Last 7 days of month at midnight
  timezone           = "Europe/Rome"
  start_time         = timeadd(timestamp(), "24h")

  scalable_target_action {
    min_capacity = var.eom_min_capacity
    max_capacity = var.eom_max_capacity
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

resource "aws_appautoscaling_scheduled_action" "end_of_month_scale_down" {
  provider           = aws.assume
  name               = "${var.environment}-end-of-month-scale-down"
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  schedule           = "cron(0 0 1 * ? *)" # First day of month at midnight
  timezone           = "Europe/Rome"
  start_time         = timeadd(timestamp(), "24h")

  scalable_target_action {
    min_capacity = var.regular_min_capacity
    max_capacity = var.regular_max_capacity
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

# Public Holidays Scaling - More aggressive scaling for traffic spikes
resource "aws_appautoscaling_scheduled_action" "christmas_scale_up" {
  provider           = aws.assume
  name               = "${var.environment}-christmas-scale-up"
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  schedule           = "cron(0 0 24 12 ? *)" # December 24 at midnight
  timezone           = "Europe/Rome"
  start_time         = timeadd(timestamp(), "24h")

  scalable_target_action {
    min_capacity = var.holiday_min_capacity
    max_capacity = var.holiday_max_capacity
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

resource "aws_appautoscaling_scheduled_action" "christmas_scale_down" {
  provider           = aws.assume
  name               = "${var.environment}-christmas-scale-down"
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  schedule           = "cron(0 0 27 12 ? *)" # December 27 at midnight
  timezone           = "Europe/Rome"
  start_time         = timeadd(timestamp(), "24h")

  scalable_target_action {
    min_capacity = var.regular_min_capacity
    max_capacity = var.regular_max_capacity
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

resource "aws_appautoscaling_scheduled_action" "new_year_scale_up" {
  provider           = aws.assume
  name               = "${var.environment}-new-year-scale-up"
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  schedule           = "cron(0 0 31 12 ? *)" # December 31 at midnight
  timezone           = "Europe/Rome"
  start_time         = timeadd(timestamp(), "24h")

  scalable_target_action {
    min_capacity = var.holiday_min_capacity
    max_capacity = var.holiday_max_capacity
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

resource "aws_appautoscaling_scheduled_action" "new_year_scale_down" {
  provider           = aws.assume
  name               = "${var.environment}-new-year-scale-down"
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  schedule           = "cron(0 0 3 1 ? *)" # January 3 at midnight
  timezone           = "Europe/Rome"
  start_time         = timeadd(timestamp(), "24h")

  scalable_target_action {
    min_capacity = var.regular_min_capacity
    max_capacity = var.regular_max_capacity
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

# Italian Liberation Day (April 25) - Scale UP
resource "aws_appautoscaling_scheduled_action" "liberation_day_scale_up" {
  provider           = aws.assume
  name               = "${var.environment}-liberation-day-scale-up"
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  schedule           = "cron(0 0 24 4 ? *)" # April 24 at midnight
  timezone           = "Europe/Rome"
  start_time         = timeadd(timestamp(), "24h")

  scalable_target_action {
    min_capacity = var.holiday_min_capacity
    max_capacity = var.holiday_max_capacity
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

resource "aws_appautoscaling_scheduled_action" "liberation_day_scale_down" {
  provider           = aws.assume
  name               = "${var.environment}-liberation-day-scale-down"
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  schedule           = "cron(0 0 26 4 ? *)" # April 26 at midnight
  timezone           = "Europe/Rome"
  start_time         = timeadd(timestamp(), "24h")

  scalable_target_action {
    min_capacity = var.regular_min_capacity
    max_capacity = var.regular_max_capacity
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

# Italian Republic Day (June 2) - Scale UP
resource "aws_appautoscaling_scheduled_action" "republic_day_scale_up" {
  provider           = aws.assume
  name               = "${var.environment}-republic-day-scale-up"
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  schedule           = "cron(0 0 1 6 ? *)" # June 1 at midnight
  timezone           = "Europe/Rome"
  start_time         = timeadd(timestamp(), "24h")

  scalable_target_action {
    min_capacity = var.holiday_min_capacity
    max_capacity = var.holiday_max_capacity
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}

resource "aws_appautoscaling_scheduled_action" "republic_day_scale_down" {
  provider           = aws.assume
  name               = "${var.environment}-republic-day-scale-down"
  service_namespace  = aws_appautoscaling_target.payslip_scaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.payslip_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payslip_scaling_target.scalable_dimension
  schedule           = "cron(0 0 3 6 ? *)" # June 3 at midnight
  timezone           = "Europe/Rome"
  start_time         = timeadd(timestamp(), "24h")

  scalable_target_action {
    min_capacity = var.regular_min_capacity
    max_capacity = var.regular_max_capacity
  }

  depends_on = [aws_appautoscaling_target.payslip_scaling_target]
}
