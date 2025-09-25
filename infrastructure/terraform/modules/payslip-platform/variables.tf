variable "environment" {
  type        = string
  description = "dev, staging, production etc"
}

variable "payslip_vpc_ipv4_cidr" {
  type = string

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

variable "payslip_ecr_image_uri" {
  type = string
}


# Existing variables...
variable "ecs_desired_count" {
  description = "Initial desired count of ECS tasks"
  type        = number
  default     = 2
}
