# Lakehouse training environments

This example contains Terraform code used to provision a Lakehouse platform using the [adb-lakehouse module](https://github.com/databricks/terraform-databricks-examples/tree/main/modules/adb-lakehouse).
It also contains Terraform code to create the following:

* Unity Catalog resources: Catalog, Schema, table, storage credential and external location
* New principals in the Databricks workspace.

## How to use

1. Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
1. Create a `terraform.tfvars` file and provide values to each defined variable
1. (Optional) Configure your [remote backend](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)
1. Run `terraform init` to initialize terraform and get provider ready.
1. Run `terraform apply` to create the resources.

An example `terraform.tfvars`

```hcl
location                  = "eastus2"
spoke_resource_group_name = "test_training_env"
project_name              = "training_env"
environment_name          = "dev"
spoke_vnet_address_space  = "10.179.128.0/18"
tags = {
  Owner       = "vuong.nguyen@databricks.com"
  RemoveAfter = "2024-03-01"
}
databricks_workspace_name       = "training_env"
private_subnet_address_prefixes = ["10.179.128.0/20"]
public_subnet_address_prefixes  = ["10.179.144.0/20"]
account_id                      = "000000000-0000-0000-0000-00000000000"
users                           = ["me@example.com"]
metastore_id                    = "000000000-0000-0000-0000-00000000000"
```
