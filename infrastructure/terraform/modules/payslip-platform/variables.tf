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

variable "payslip_ecr_image_uri" {
  type = string
}


# Existing variables...
variable "ecs_desired_count" {
  description = "Initial desired count of ECS tasks"
  type        = number
  default     = 2
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks for auto scaling"
  type        = number
  default     = 2
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks for auto scaling"
  type        = number
  default     = 10
}

# Scheduled scaling variables
variable "morning_min_capacity" {
  description = "Minimum capacity during morning peak hours (8-10 AM)"
  type        = number
  default     = 5
}

variable "morning_max_capacity" {
  description = "Maximum capacity during morning peak hours (8-10 AM)"
  type        = number
  default     = 15
}

variable "evening_min_capacity" {
  description = "Minimum capacity during evening peak hours (5-7 PM)"
  type        = number
  default     = 5
}

variable "evening_max_capacity" {
  description = "Maximum capacity during evening peak hours (5-7 PM)"
  type        = number
  default     = 15
}

variable "regular_min_capacity" {
  description = "Minimum capacity during regular hours"
  type        = number
  default     = 2
}

variable "regular_max_capacity" {
  description = "Maximum capacity during regular hours"
  type        = number
  default     = 10
}

variable "eom_min_capacity" {
  description = "Minimum capacity during end of month period"
  type        = number
  default     = 8
}

variable "eom_max_capacity" {
  description = "Maximum capacity during end of month period"
  type        = number
  default     = 20
}

variable "holiday_min_capacity" {
  description = "Minimum capacity during public holidays"
  type        = number
  default     = 1
}

variable "holiday_max_capacity" {
  description = "Maximum capacity during public holidays"
  type        = number
  default     = 5
}
