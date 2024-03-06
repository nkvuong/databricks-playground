resource "databricks_sql_endpoint" "shared" {
  name                      = "Shared Endpoint"
  cluster_size              = "Small"
  enable_serverless_compute = true
  max_num_clusters          = 1
}

resource "databricks_permissions" "can_use_sql" {
  sql_endpoint_id = databricks_sql_endpoint.shared.id
  access_control {
    group_name       = databricks_group.sandbox.display_name
    permission_level = "CAN_USE"
  }
}

resource "databricks_cluster_policy" "fair_use" {
  name       = "${var.sandbox_group} cluster policy"
  definition = jsonencode(local.sandbox_policy)
}

resource "databricks_permissions" "can_use_cluster_policy" {
  cluster_policy_id = databricks_cluster_policy.fair_use.id
  access_control {
    group_name       = databricks_group.sandbox.display_name
    permission_level = "CAN_USE"
  }
}

resource "databricks_cluster" "shared_autoscaling" {
  cluster_name            = "Shared Autoscaling"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 20
  autoscale {
    min_workers = 1
    max_workers = 2
  }
}

resource "databricks_permissions" "can_use_cluster" {
  cluster_id = databricks_cluster.shared_autoscaling.id
  access_control {
    group_name       = databricks_group.sandbox.display_name
    permission_level = "CAN_ATTACH_TO"
  }
}
