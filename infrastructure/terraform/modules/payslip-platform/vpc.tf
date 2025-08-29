resource "aws_vpc" "payslip_vpc" {
  provider             = aws.assume
  cidr_block           = var.payslip_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    ManagedBy = local.role_to_assume
    Name      = "${var.environment}-payslip-vpc"
  }
}

