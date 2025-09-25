resource "aws_internet_gateway" "payslip_igw" {
  vpc_id = aws_vpc.payslip_vpc.id

  tags = {
    ManagedBy = local.role_to_assume
    Name      = "${var.environment}payslip-igw"
  }
}

