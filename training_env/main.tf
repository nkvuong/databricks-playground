resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

module "adb-lakehouse" {
  source                          = "databricks/examples/databricks//modules/adb-lakehouse"
  project_name                    = "${var.project_name}_${random_string.naming.result}"
  environment_name                = "${var.environment_name}_${random_string.naming.result}"
  location                        = var.location
  spoke_vnet_address_space        = var.spoke_vnet_address_space
  spoke_resource_group_name       = "${var.spoke_resource_group_name}_${random_string.naming.result}"
  managed_resource_group_name     = var.managed_resource_group_name
  databricks_workspace_name       = "${var.databricks_workspace_name}_${random_string.naming.result}"
  data_factory_name               = var.data_factory_name
  key_vault_name                  = var.key_vault_name
  private_subnet_address_prefixes = var.private_subnet_address_prefixes
  public_subnet_address_prefixes  = var.public_subnet_address_prefixes
  storage_account_names           = var.storage_account_names
  tags                            = var.tags
}

resource "databricks_metastore_assignment" "unity" {
  workspace_id = module.adb-lakehouse.workspace_id
  metastore_id = var.metastore_id
}