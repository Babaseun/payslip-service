# ECS Cluster with cost-optimized settings
resource "aws_ecs_cluster" "payslip_cluster" {
  name = "${var.environment}-payslip-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled" # Disabled to reduce CloudWatch costs
  }

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
    rightsizing = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "payslip_cluster_cp" {
  cluster_name       = aws_ecs_cluster.payslip_cluster.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
    base              = 0
  }
}

# Task Execution IAM Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-ecs-task-execution-role"

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
    rightsizing = "enabled"
  }
}

# Attach the AmazonECSTaskExecutionRolePolicy to the role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition with right-sized resources
resource "aws_ecs_task_definition" "payslip_task" {
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
      command     = ["CMD-SHELL", "curl -f http://localhost:5000 || exit 1"]
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
    rightsizing = "enabled"
  }
}

# Security Group for ECS Service
resource "aws_security_group" "ecs_service_sg" {
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
    rightsizing = "enabled"
  }
}

# ECS Service with Fargate Spot capacity provider and fixed desired count
resource "aws_ecs_service" "payslip_service" {
  name                = "${var.environment}-payslip-service"
  cluster             = aws_ecs_cluster.payslip_cluster.id
  task_definition     = aws_ecs_task_definition.payslip_task.arn
  desired_count       = var.ecs_desired_count # Fixed number of tasks
  scheduling_strategy = "REPLICA"

  # Use Fargate Spot for significant cost savings
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
    base              = 0
  }

  network_configuration {
    subnets          = [aws_subnet.sn-app-A.id, aws_subnet.sn-app-B.id, aws_subnet.sn-app-C.id]
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.payslip_tg.arn
    container_name   = "payslip-server-app"
    container_port   = 5000
  }

  # Enable task tag propagation for cost tracking
  propagate_tags = "SERVICE"

  depends_on = [aws_lb_listener.payslip_listener]

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
    rightsizing = "enabled"
  }
}

# CloudWatch Log Group with reduced retention period
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.environment}-payslip-task"
  retention_in_days = 3 # Reduced from 7 to 3 days to save costs

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
    rightsizing = "enabled"
  }
}
