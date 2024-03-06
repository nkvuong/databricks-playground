resource "databricks_notebook" "schema_cleanup" {
    content_base64 = base64encode(<<-EOT
        from databricks.sdk import WorkspaceClient
        import time
        import datetime
        today = time.time()
        w = WorkspaceClient()
        today = datetime.datetime.today()
        threshold = today - datetime.timedelta(days=60)
        threshold = time.mktime(threshold.timetuple())
        catalog_name = "sandbox"
        for schema in w.schemas.list(catalog_name=catalog_name):
        if schema.created_at < threshold:
            w.schemas.delete(f"{catalog_name}.{schema.name}")  
        }
    EOT
    )
  path     = "/Shared/CleanupSchema"
  language = "PYTHON"
}

resource "databricks_job" "this" {
  name        = "Clean up schema job"
  description = "This job cleans up any schema that is older than 60 days"

  task {
    task_key = "a"

    new_cluster {
      num_workers   = 1
      spark_version = data.databricks_spark_version.latest_lts.id
      node_type_id  = data.databricks_node_type.smallest.id
    }

    notebook_task {
      notebook_path = databricks_notebook.schema_cleanup.path
    }
  }
}