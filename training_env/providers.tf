provider "azurerm" {
  features {}
  skip_provider_registration = true
}

provider "databricks" {
  host  = module.adb-lakehouse.workspace_url
}
