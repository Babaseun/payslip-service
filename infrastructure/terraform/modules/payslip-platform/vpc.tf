resource "aws_vpc" "payslip_vpc" {
  cidr_block                       = var.payslip_vpc_ipv4_cidr
  assign_generated_ipv6_cidr_block = true
  enable_dns_support               = true
  enable_dns_hostnames             = true

  tags = {
    ManagedBy = local.role_to_assume
    Name      = "${var.environment}-payslip-vpc"
  }
}

