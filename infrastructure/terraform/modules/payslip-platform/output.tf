output "db_connection_string" {
  value     = "postgres://${aws_db_instance.payslip_postgres_database.username}:${var.postgres_admin_password}@${aws_db_instance.payslip_postgres_database.endpoint}:${aws_db_instance.payslip_postgres_database.port}/postgres"
  sensitive = true
}
