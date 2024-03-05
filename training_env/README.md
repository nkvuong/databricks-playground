# Lakehouse training environments

This example contains Terraform code used to provision a Lakehouse platform using the [adb-lakehouse module](../../modules/adb-lakehouse).
It also contains Terraform code to create the following:

* Unity Catalog resources: Catalog, Schema, table, storage credential and external location
* New principals in the Databricks workspace.

## How to use

1. Update `terraform.tfvars` file and provide values to each defined variable
2. (Optional) Configure your [remote backend](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)
3. Run `terraform init` to initialize terraform and get provider ready.
4. Run `terraform apply` to create the resources.
