# Public subnet 
resource "aws_subnet" "public_zone1" {
  provider                = aws.assume
  vpc_id                  = aws_vpc.payslip_vpc.id
  cidr_block              = var.payslip_public_subnet_1_cidr
  availability_zone       = local.zone1
  map_public_ip_on_launch = true

  tags = {
    "ManagedBy" = local.role_to_assume
    "Name"      = "${var.environment}payslip-public-${local.zone1}"
  }
}

