
resource "aws_route_table" "payslip_public" {
  provider = aws.assume
  vpc_id   = aws_vpc.payslip_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.payslip_igw.id
  }

  tags = {
    ManagedBy = local.role_to_assume
    Name      = "${var.environment}-payslip-public"
  }
}


resource "aws_route_table_association" "payslip_public_zone1" {
  provider       = aws.assume
  subnet_id      = aws_subnet.payslip_public_zone1.id
  route_table_id = aws_route_table.payslip_public.id
}

