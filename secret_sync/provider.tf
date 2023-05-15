terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.16.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

provider "databricks" {
  # Configuration options
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}
