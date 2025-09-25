resource "aws_kms_key" "payslip_rds_key" {
  description             = "KMS key for encrypting Payslip RDS PostgreSQL database"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/kms-role"
        }
        Action   = "kms:*"
        Resource = "*"
      },
    ]
  })
}

resource "aws_kms_alias" "payslip_rds_key_alias" {
  name          = "alias/payslip-rds-key"
  target_key_id = aws_kms_key.payslip_rds_key.key_id
}


resource "aws_db_subnet_group" "payslip_postgres_database_subnet_group" {
  name       = "${var.environment}-payslip-postgres-database-subnet-group"
  subnet_ids = [aws_subnet.sn-db-A.id, aws_subnet.sn-db-B.id, aws_subnet.sn-db-C.id]

  tags = {
    Name = "${var.environment}-payslip-postgres-database-subnet-group"
  }
}


resource "aws_db_instance" "payslip_postgres_database" {
  identifier                          = "${var.environment}-payslip-postgres-database"
  instance_class                      = var.postgres_instance_class
  engine                              = "postgres"
  engine_version                      = "17.5"
  port                                = 5432
  allocated_storage                   = "20"
  max_allocated_storage               = "30"
  publicly_accessible                 = true
  iam_database_authentication_enabled = false
  auto_minor_version_upgrade          = true
  deletion_protection                 = false
  performance_insights_enabled        = false
  storage_type                        = "gp3"
  backup_retention_period             = 7
  skip_final_snapshot                 = true
  username                            = var.postgres_admin_username
  password                            = var.postgres_admin_password
  storage_encrypted                   = true
  kms_key_id                          = aws_kms_key.payslip_rds_key.arn
  db_subnet_group_name                = aws_db_subnet_group.payslip_postgres_database_subnet_group.name
  vpc_security_group_ids              = [aws_security_group.payslip_postgres_database_security_group.id]

  tags = {
    Name = "${var.environment}-payslip-postgres-database"
  }
}

resource "aws_security_group" "payslip_postgres_database_security_group" {
  vpc_id      = aws_vpc.payslip_vpc.id
  name        = "${var.environment}-payslip-postgres-database-security-group"
  description = "${var.environment}-payslip-postgres-database-security-group"



  ingress {
    cidr_blocks = [local.adeyemi_public_ip]
    from_port   = 5432
    protocol    = "TCP"
    to_port     = 5432
    description = "adeyemi-home"
  }

  ingress {
    cidr_blocks = [aws_vpc.payslip_vpc.cidr_block]
    from_port   = 5432
    protocol    = "TCP"
    to_port     = 5432
    description = "vpc"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
