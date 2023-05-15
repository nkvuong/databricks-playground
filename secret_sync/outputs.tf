output "number_of_secrets" {
  value = length(data.aws_secretsmanager_secrets.all.names)
}