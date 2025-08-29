variable "region" {
  type        = string
  description = "AWS region"
}
variable "admin_db_host" {
  type        = string
  description = "Database host"
}

variable "admin_db_port" {
  type        = number
  description = "Database port"
  default     = 5432
}

variable "admin_database" {
  type        = string
  description = "Admin database name"
  default     = "postgres"
}

variable "admin_db_username" {
  type        = string
  description = "Database username"
}

variable "admin_db_password" {
  type        = string
  description = "Database password"
}
