terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }
  }
}

# The primary provider, configured with local credentials.
# This profile only needs sts:AssumeRole permission on the target role.
provider "aws" {
  region  = local.region
  profile = local.terraform_profile
}

# The provider that will assume the role for managing resources.
# All infrastructure will be created by this provider.
provider "aws" {
  alias  = "assume"
  region = local.region

  assume_role {
    # Hardcoded the ARN to avoid needing iam:GetRole permissions
    role_arn     = "arn:aws:iam::${local.aws_account_id}:role/${local.role_to_assume}"
    session_name = "TerraformSession-${local.role_to_assume}"
  }

  default_tags {
    tags = {
      ManagedBy   = local.role_to_assume
      Provisioner = "Terraform"
      Environment = var.environment
    }
  }
}
