variable "environment" {
  type        = string
  description = "dev, staging, production etc"
}

variable "payslip_vpc_cidr" {
  type = string

}



variable "payslip_public_subnet_1_cidr" {
  type        = string
  description = "CIDR for public subnet 1"
}



variable "payslip_public_subnet_2_cidr" {
  type        = string
  description = "CIDR for public subnet 2"
}

variable "assume_role_arn" {
  type    = string
  default = null
}

variable "postgres_instance_class" {
  description = "Postgres database instance class"
}

variable "postgres_admin_username" {
  description = "Admin username for postgres"
}

variable "postgres_admin_password" {
  description = "Admin password for postgres"
}

