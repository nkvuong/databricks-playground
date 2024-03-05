
resource "databricks_catalog" "training_data" {
  name = "training_data"
}

resource "databricks_catalog" "sandbox" {
  name = "sandbox"
}

resource "databricks_schema" "training_data" {
  for_each = toset(["bronze", "silver", "gold"])
  name = each.key
  catalog_name = databricks_catalog.training_data.name
}

resource "databricks_schema" "sandbox" {
  for_each = toset(var.users)
  name = each.key
  catalog_name = databricks_catalog.sandbox.name
}