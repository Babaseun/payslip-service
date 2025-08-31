# Security Group for NLB
resource "aws_security_group" "nlb_sg" {
  provider    = aws.assume
  name        = "${var.environment}-nlb-sg"
  description = "Security group for NLB allowing TCP traffic"
  vpc_id      = aws_vpc.payslip_vpc.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Server access"
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

# Network Load Balancer
resource "aws_lb" "payslip_nlb" {
  provider           = aws.assume
  name               = "${var.environment}-payslip-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_zone1.id]

  enable_deletion_protection = false

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
  }
}

# NLB Target Group
resource "aws_lb_target_group" "payslip_tg" {
  provider    = aws.assume
  name        = "${var.environment}-payslip-tg"
  port        = 5000
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.payslip_vpc.id

  health_check {
    protocol            = "TCP"
    port                = "traffic-port"
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
  }
}

# NLB Listener
resource "aws_lb_listener" "payslip_listener" {
  provider          = aws.assume
  load_balancer_arn = aws_lb.payslip_nlb.arn
  port              = "5000"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payslip_tg.arn
  }
}

