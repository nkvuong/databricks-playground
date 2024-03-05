resource "databricks_user" "sandbox" {
  for_each = toset(var.users)
  user_name = each.key
}

resource "databricks_group" "sandbox" {
  display_name = var.sandbox_group
}

resource "databricks_group_member" "sandbox" {
  for_each = toset(var.users)
  group_id = databricks_group.sandbox.id
  member_id = databricks_user.sandbox[each.key].id
}