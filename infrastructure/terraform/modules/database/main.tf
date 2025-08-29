resource "postgresql_database" "payslip_db" {
  name  = var.payslip_db_name
  owner = postgresql_role.name
}

resource "postgresql_role" "payslip_role" {
  name     = var.payslip_db_user_name
  login    = true
  password = var.payslip_db_password
}
