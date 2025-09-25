resource "aws_subnet" "sn-reserved-A" {
  vpc_id                          = aws_vpc.payslip_vpc.id
  cidr_block                      = local.subnets["sn-reserved-A"].cidr
  availability_zone               = local.availability_zones[local.subnets["sn-reserved-A"].az_index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.payslip_vpc.ipv6_cidr_block, 8, local.subnets_with_decimal["sn-reserved-A"].ipv6_suffix_decimal)
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch         = false

  tags = {
    "ManagedBy" = local.role_to_assume
    Name        = "sn-reserved-A"
    Type        = local.subnets["sn-reserved-A"].type
    AZ          = local.az_letters[local.subnets["sn-reserved-A"].az_index]
  }
}

resource "aws_subnet" "sn-db-A" {
  vpc_id                          = aws_vpc.payslip_vpc.id
  cidr_block                      = local.subnets["sn-db-A"].cidr
  availability_zone               = local.availability_zones[local.subnets["sn-db-A"].az_index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.payslip_vpc.ipv6_cidr_block, 8, local.subnets_with_decimal["sn-db-A"].ipv6_suffix_decimal)
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch         = false

  tags = {
    "ManagedBy" = local.role_to_assume
    Name        = "sn-db-A"
    Type        = local.subnets["sn-db-A"].type
    AZ          = local.az_letters[local.subnets["sn-db-A"].az_index]
  }
}

resource "aws_subnet" "sn-app-A" {
  vpc_id                          = aws_vpc.payslip_vpc.id
  cidr_block                      = local.subnets["sn-app-A"].cidr
  availability_zone               = local.availability_zones[local.subnets["sn-app-A"].az_index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.payslip_vpc.ipv6_cidr_block, 8, local.subnets_with_decimal["sn-app-A"].ipv6_suffix_decimal)
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch         = false

  tags = {
    "ManagedBy" = local.role_to_assume
    Name        = "sn-app-A"
    Type        = local.subnets["sn-app-A"].type
    AZ          = local.az_letters[local.subnets["sn-app-A"].az_index]
  }
}

resource "aws_subnet" "sn-web-A" {
  vpc_id                          = aws_vpc.payslip_vpc.id
  cidr_block                      = local.subnets["sn-web-A"].cidr
  availability_zone               = local.availability_zones[local.subnets["sn-web-A"].az_index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.payslip_vpc.ipv6_cidr_block, 8, local.subnets_with_decimal["sn-web-A"].ipv6_suffix_decimal)
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true

  tags = {
    "ManagedBy" = local.role_to_assume
    Name        = "sn-web-A"
    Type        = local.subnets["sn-web-A"].type
    AZ          = local.az_letters[local.subnets["sn-web-A"].az_index]
  }
}

resource "aws_subnet" "sn-reserved-B" {
  vpc_id                          = aws_vpc.payslip_vpc.id
  cidr_block                      = local.subnets["sn-reserved-B"].cidr
  availability_zone               = local.availability_zones[local.subnets["sn-reserved-B"].az_index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.payslip_vpc.ipv6_cidr_block, 8, local.subnets_with_decimal["sn-reserved-B"].ipv6_suffix_decimal)
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch         = false

  tags = {
    "ManagedBy" = local.role_to_assume
    Name        = "sn-reserved-B"
    Type        = local.subnets["sn-reserved-B"].type
    AZ          = local.az_letters[local.subnets["sn-reserved-B"].az_index]
  }
}

resource "aws_subnet" "sn-db-B" {
  vpc_id                          = aws_vpc.payslip_vpc.id
  cidr_block                      = local.subnets["sn-db-B"].cidr
  availability_zone               = local.availability_zones[local.subnets["sn-db-B"].az_index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.payslip_vpc.ipv6_cidr_block, 8, local.subnets_with_decimal["sn-db-B"].ipv6_suffix_decimal)
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch         = false

  tags = {
    "ManagedBy" = local.role_to_assume
    Name        = "sn-db-B"
    Type        = local.subnets["sn-db-B"].type
    AZ          = local.az_letters[local.subnets["sn-db-B"].az_index]
  }
}

resource "aws_subnet" "sn-app-B" {
  vpc_id                          = aws_vpc.payslip_vpc.id
  cidr_block                      = local.subnets["sn-app-B"].cidr
  availability_zone               = local.availability_zones[local.subnets["sn-app-B"].az_index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.payslip_vpc.ipv6_cidr_block, 8, local.subnets_with_decimal["sn-app-B"].ipv6_suffix_decimal)
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch         = false

  tags = {
    "ManagedBy" = local.role_to_assume
    Name        = "sn-app-B"
    Type        = local.subnets["sn-app-B"].type
    AZ          = local.az_letters[local.subnets["sn-app-B"].az_index]
  }
}

resource "aws_subnet" "sn-web-B" {
  vpc_id                          = aws_vpc.payslip_vpc.id
  cidr_block                      = local.subnets["sn-web-B"].cidr
  availability_zone               = local.availability_zones[local.subnets["sn-web-B"].az_index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.payslip_vpc.ipv6_cidr_block, 8, local.subnets_with_decimal["sn-web-B"].ipv6_suffix_decimal)
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true

  tags = {
    "ManagedBy" = local.role_to_assume
    Name        = "sn-web-B"
    Type        = local.subnets["sn-web-B"].type
    AZ          = local.az_letters[local.subnets["sn-web-B"].az_index]
  }
}

resource "aws_subnet" "sn-reserved-C" {
  vpc_id                          = aws_vpc.payslip_vpc.id
  cidr_block                      = local.subnets["sn-reserved-C"].cidr
  availability_zone               = local.availability_zones[local.subnets["sn-reserved-C"].az_index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.payslip_vpc.ipv6_cidr_block, 8, local.subnets_with_decimal["sn-reserved-C"].ipv6_suffix_decimal)
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch         = false

  tags = {
    "ManagedBy" = local.role_to_assume
    Name        = "sn-reserved-C"
    Type        = local.subnets["sn-reserved-C"].type
    AZ          = local.az_letters[local.subnets["sn-reserved-C"].az_index]
  }
}

resource "aws_subnet" "sn-db-C" {
  vpc_id                          = aws_vpc.payslip_vpc.id
  cidr_block                      = local.subnets["sn-db-C"].cidr
  availability_zone               = local.availability_zones[local.subnets["sn-db-C"].az_index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.payslip_vpc.ipv6_cidr_block, 8, local.subnets_with_decimal["sn-db-C"].ipv6_suffix_decimal)
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch         = false

  tags = {
    "ManagedBy" = local.role_to_assume
    Name        = "sn-db-C"
    Type        = local.subnets["sn-db-C"].type
    AZ          = local.az_letters[local.subnets["sn-db-C"].az_index]
  }
}

resource "aws_subnet" "sn-app-C" {
  vpc_id                          = aws_vpc.payslip_vpc.id
  cidr_block                      = local.subnets["sn-app-C"].cidr
  availability_zone               = local.availability_zones[local.subnets["sn-app-C"].az_index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.payslip_vpc.ipv6_cidr_block, 8, local.subnets_with_decimal["sn-app-C"].ipv6_suffix_decimal)
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch         = false

  tags = {
    "ManagedBy" = local.role_to_assume
    Name        = "sn-app-C"
    Type        = local.subnets["sn-app-C"].type
    AZ          = local.az_letters[local.subnets["sn-app-C"].az_index]
  }
}

resource "aws_subnet" "sn-web-C" {
  vpc_id                          = aws_vpc.payslip_vpc.id
  cidr_block                      = local.subnets["sn-web-C"].cidr
  availability_zone               = local.availability_zones[local.subnets["sn-web-C"].az_index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.payslip_vpc.ipv6_cidr_block, 8, local.subnets_with_decimal["sn-web-C"].ipv6_suffix_decimal)
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true

  tags = {
    "ManagedBy" = local.role_to_assume
    Name        = "sn-web-C"
    Type        = local.subnets["sn-web-C"].type
    AZ          = local.az_letters[local.subnets["sn-web-C"].az_index]
  }
}

