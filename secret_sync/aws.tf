data "aws_secretsmanager_secrets" "all" {
  filter {
    name   = "tag-value"
    values = ["databricks"]
  }
}

data "aws_secretsmanager_secret" "secrets" {
  for_each = data.aws_secretsmanager_secrets.all.names
  name     = each.value
}

data "aws_secretsmanager_secret_version" "values" {
  for_each  = data.aws_secretsmanager_secret.secrets
  secret_id = each.value.id
}
