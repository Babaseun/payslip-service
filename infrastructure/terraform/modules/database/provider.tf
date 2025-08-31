# PostgreSQL provider to connect to the new server
provider "postgresql" {
  host            = var.admin_db_host
  port            = var.admin_db_port
  database        = var.admin_database
  username        = var.admin_db_username
  password        = var.admin_db_password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}



provider "aws" {
  region = var.region
}
