variable "scope_name" {
  description = "Name of the Databricks scope"
}

variable "aws_profile" {
  description = "AWS profile for provider"
}

variable "aws_region" {
  description = "AWS region"
  default = "us-east-1"
}