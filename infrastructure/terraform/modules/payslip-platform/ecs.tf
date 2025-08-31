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
  desired_count       = 2
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
