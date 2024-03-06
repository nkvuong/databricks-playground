
resource "databricks_catalog" "training_data" {
  name       = "training_data"
  depends_on = [databricks_metastore_assignment.unity]
}

resource "databricks_catalog" "sandbox" {
  name       = "sandbox"
  depends_on = [databricks_metastore_assignment.unity]
}

resource "databricks_schema" "training_data" {
  for_each     = toset(["bronze", "silver", "gold"])
  name         = each.key
  catalog_name = databricks_catalog.training_data.name
}

resource "databricks_schema" "sandbox" {
  for_each     = toset(var.users)
  name         = replace(each.key, ".", "_")
  catalog_name = databricks_catalog.sandbox.name
  owner        = each.key
}
