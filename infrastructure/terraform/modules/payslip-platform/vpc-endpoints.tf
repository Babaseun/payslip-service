###########################################################################
##### ECR access in private subnet without going through the internet #####
###########################################################################

# Security Group for the VPC Endpoints
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "${var.environment}-vpc-endpoint-sg"
  description = "Security group for VPC Endpoints"
  vpc_id      = aws_vpc.payslip_vpc.id

  # Allow HTTPS traffic from resources within the private subnets
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.payslip_vpc.cidr_block] # Allows from entire VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
  }
}

# 1. Interface Endpoint for ECR Docker API (dkr)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.payslip_vpc.id
  service_name        = "com.amazonaws.af-south-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true # Crucial for proper DNS resolution :cite[3]

  subnet_ids = [
    aws_subnet.sn-app-A.id,
    aws_subnet.sn-app-B.id,
    aws_subnet.sn-app-C.id
  ]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name        = "${var.environment}-ecr-dkr-endpoint"
    Environment = var.environment
  }
}

# 2. Interface Endpoint for ECR API (api)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.payslip_vpc.id
  service_name        = "com.amazonaws.af-south-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true # Crucial for proper DNS resolution :cite[3]

  subnet_ids = [
    aws_subnet.sn-app-A.id,
    aws_subnet.sn-app-B.id,
    aws_subnet.sn-app-C.id
  ]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name        = "${var.environment}-ecr-api-endpoint"
    Environment = var.environment
  }
}

# 3. Gateway Endpoint for Amazon S3 (Required for ECR image layers) :cite[3]:cite[8]
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.payslip_vpc.id
  service_name      = "com.amazonaws.af-south-1.s3"
  vpc_endpoint_type = "Gateway"

  # Automatically add a route to the S3 endpoint in the specified route tables
  route_table_ids = [aws_route_table.private_payslip_rt.id]

  tags = {
    Name        = "${var.environment}-s3-gateway-endpoint"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = aws_vpc.payslip_vpc.id
  service_name        = "com.amazonaws.af-south-1.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.sn-app-A.id,
    aws_subnet.sn-app-B.id,
    aws_subnet.sn-app-C.id
  ]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name        = "${var.environment}-logs-endpoint"
    Environment = var.environment
  }
}

