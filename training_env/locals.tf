locals {
  sandbox_policy = {
    "node_type_id" : {
      "type" : "fixed",
      "value" : "Standard_E4d_v4",
      "hidden" : true
    },
    "spark_version" : {
      "type" : "fixed",
      "value" : "13.3.x-cpu-ml-scala2.12",
      "hidden" : true
    },
    "runtime_engine" : {
      "type" : "fixed",
      "value" : "STANDARD",
      "hidden" : true
    },
    "num_workers" : {
      "type" : "fixed",
      "value" : 0,
      "hidden" : true
    },
    "data_security_mode" : {
      "type" : "fixed",
      "value" : "SINGLE_USER",
      "hidden" : true
    },
    "driver_instance_pool_id" : {
      "type" : "forbidden",
      "hidden" : true
    },
    "cluster_type" : {
      "type" : "fixed",
      "value" : "all-purpose"
    },
    "instance_pool_id" : {
      "type" : "forbidden",
      "hidden" : true
    },
    "azure_attributes.availability" : {
      "type" : "fixed",
      "value" : "ON_DEMAND_AZURE",
      "hidden" : true
    },
    "spark_conf.spark.databricks.cluster.profile" : {
      "type" : "fixed",
      "value" : "singleNode",
      "hidden" : true
    },
    "autotermination_minutes" : {
      "type" : "fixed",
      "value" : 120,
      "hidden" : true
    }
  }
}
