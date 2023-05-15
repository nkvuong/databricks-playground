# Syncing secrets from AWS Secrets Manager to Databricks Secrets

This Terraform configuration simply reads all AWS secrets that has the tag value `Databricks`, and replicate them into a new Databricks secret scope.
