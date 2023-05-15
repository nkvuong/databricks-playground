resource "databricks_secret_scope" "scope" {
  name                     = var.scope_name
  initial_manage_principal = "users"
}

resource "databricks_secret" "secret" {
  for_each     = data.aws_secretsmanager_secret.secrets
  key          = replace(each.value.name, "/[^\\w\\-_.]/", "") # only alphanumeric characters, dashes, underscores, and periods allowed
  string_value = data.aws_secretsmanager_secret_version.values[each.key].secret_string
  scope        = databricks_secret_scope.scope.id
}
