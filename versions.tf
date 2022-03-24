# ---------------------------------------------------------------------------------------------------------------------
# Providers
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = ">=3.1.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.4"
    }
    aviatrix = {
      source  = "AviatrixSystems/aviatrix"
      version = "2.19.0"
    }
  }
}