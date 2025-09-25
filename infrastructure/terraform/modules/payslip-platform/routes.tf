# Route table for public subnets (web subnets) - with internet access
resource "aws_route_table" "public_payslip_rt" {
  vpc_id = aws_vpc.payslip_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.payslip_igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.payslip_igw.id
  }

  tags = {
    Name = "public_payslip_rt"
    Type = "public"
  }
}

resource "aws_route_table" "private_payslip_rt" {
  vpc_id = aws_vpc.payslip_vpc.id

  tags = {
    Name = "private_payslip_rt"
    Type = "private"
  }
}


# Associate app subnets with private route table
resource "aws_route_table_association" "payslip_app_private" {
  for_each = {
    "sn-app-A" = aws_subnet.sn-app-A.id
    "sn-app-B" = aws_subnet.sn-app-B.id
    "sn-app-C" = aws_subnet.sn-app-C.id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.private_payslip_rt.id
}

# Associate web (public) subnets with the public route table
resource "aws_route_table_association" "payslip_web_public" {
  for_each = {
    "sn-web-A" = aws_subnet.sn-web-A.id
    "sn-web-B" = aws_subnet.sn-web-B.id
    "sn-web-C" = aws_subnet.sn-web-C.id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.public_payslip_rt.id
}



