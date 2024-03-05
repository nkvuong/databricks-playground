data "azurerm_client_config" "current" {
  depends_on = [ module.adb-lakehouse ]
}

data "databricks_node_type" "smallest" {
  depends_on = [ module.adb-lakehouse ]
  local_disk = true
}

data "databricks_spark_version" "latest_lts" {
  depends_on = [ module.adb-lakehouse ]
  long_term_support = true
}