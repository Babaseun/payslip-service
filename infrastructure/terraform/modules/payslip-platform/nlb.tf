# Security Group for NLB
resource "aws_security_group" "nlb_sg" {
  name        = "${var.environment}-nlb-sg"
  description = "Security group for NLB allowing TCP traffic"
  vpc_id      = aws_vpc.payslip_vpc.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Public access to payslip server on port 5000"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic for health checks and backend communication"
  }

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
  }
}

# Network Load Balancer (Enhanced for high availability)
resource "aws_lb" "payslip_nlb" {
  name               = "${var.environment}-payslip-nlb"
  internal           = false
  load_balancer_type = "network"

  subnets = [
    aws_subnet.sn-web-A.id,
    aws_subnet.sn-web-B.id,
    aws_subnet.sn-web-C.id
  ]
  ip_address_type                  = "dualstack"
  security_groups                  = [aws_security_group.nlb_sg.id]
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true # Better traffic distribution across AZs :cite[7]

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
  }

  # Lifecycle setting to handle NLB replacement safely
  lifecycle {
    create_before_destroy = true
  }
}

# NLB Target Group (Optimized for ECS Fargate)
resource "aws_lb_target_group" "payslip_tg" {

  name        = "${var.environment}-payslip-tg"
  port        = 5000
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.payslip_vpc.id

  # Connection draining for graceful shutdowns during deployments
  deregistration_delay = 300 # 5 minutes for graceful connection draining :cite[5]

  # Health check configuration optimized for Flask application
  health_check {
    protocol            = "TCP"
    port                = "traffic-port"
    interval            = 60
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
  }

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
  }

  depends_on = [aws_lb.payslip_nlb]
}

# NLB Listener for TCP traffic
resource "aws_lb_listener" "payslip_listener" {
  load_balancer_arn = aws_lb.payslip_nlb.arn
  port              = "5000"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payslip_tg.arn
  }
}

# TODO: TLS Listener for HTTPS 
# resource "aws_lb_listener" "payslip_tls_listener" {
#   load_balancer_arn = aws_lb.payslip_nlb.arn
#   port              = "443"
#   protocol          = "TLS"
#   certificate_arn   = aws_acm_certificate.payslip_cert.arn  # Would need ACM certificate
# 
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.payslip_tg.arn
#   }
# }


# CloudWatch Metrics Alarm for NLB Healthy Hosts
resource "aws_cloudwatch_metric_alarm" "nlb_healthy_hosts" {
  alarm_name          = "${var.environment}-nlb-healthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1 # Alert if less than 1 healthy host

  dimensions = {
    LoadBalancer = aws_lb.payslip_nlb.arn_suffix
    TargetGroup  = aws_lb_target_group.payslip_tg.arn_suffix
  }

  alarm_description = "Trigger when there are no healthy hosts in the NLB target group"
  alarm_actions     = [] # Add SNS topic ARN for notifications if needed

  tags = {
    ManagedBy   = local.role_to_assume
    Environment = var.environment
  }
}

