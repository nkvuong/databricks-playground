// Databricks notebook source
// MAGIC %scala
// MAGIC import com.databricks.backend.common.util.Project
// MAGIC import com.databricks.backend.daemon.driver.DriverConf
// MAGIC import com.databricks.conf.trusted.ProjectConf
// MAGIC import java.util.Properties
// MAGIC 
// MAGIC val dbConf = new DriverConf(ProjectConf.loadLocalConfig(Project.Driver))
// MAGIC val port = dbConf.internalMetastorePort
// MAGIC val user = dbConf.internalMetastoreUser
// MAGIC val pass = dbConf.internalMetastorePassword
// MAGIC val db = dbConf.internalMetastoreDatabase
// MAGIC val host = dbConf.internalMetastoreHost.get
// MAGIC 
// MAGIC val jdbcUrl = s"jdbc:mysql://${host}:${port}/${db}"
// MAGIC 
// MAGIC val connectionProperties = new Properties()
// MAGIC connectionProperties.put("user", s"${user}")
// MAGIC connectionProperties.put("password", s"${pass}")
// MAGIC if (host contains "azure") {
// MAGIC   connectionProperties.put("useSSL", "true")
// MAGIC }
// MAGIC 
// MAGIC Class.forName("org.mariadb.jdbc.Driver")

// COMMAND ----------

// MAGIC %md
// MAGIC ### List Managed Tables

// COMMAND ----------

val sql = "(SELECT d.NAME, from_unixtime(t.CREATE_TIME) as create_time_t, lower(p.PARAM_VALUE) as type, sp.PARAM_VALUE AS LOCATION , t.* from TBLS t JOIN DBS d ON t.DB_ID = d.DB_ID JOIN SDS s ON s.SD_ID = t.SD_ID JOIN SERDE_PARAMS sp ON sp.SERDE_ID = s.SERDE_ID AND sp.PARAM_KEY = 'path' LEFT JOIN TABLE_PARAMS p ON p.TBL_ID = t.TBL_ID AND p.PARAM_KEY = 'spark.sql.sources.provider') as empty_sc"
val df = spark.read.jdbc(url=jdbcUrl, table=sql, properties=connectionProperties).cache()
df.createOrReplaceTempView("hive_tables")

// COMMAND ----------

// MAGIC %sql
// MAGIC select * from hive_tables 
// MAGIC where TBL_TYPE = 'MANAGED_TABLE'

// COMMAND ----------

// MAGIC %md
// MAGIC ### Get column names, types and comments of all tables

// COMMAND ----------

val sql = "(SELECT t.TBL_NAME, c.* FROM TBLS t JOIN DBS d ON t.DB_ID = d.DB_ID JOIN SDS s ON t.SD_ID = s.SD_ID JOIN COLUMNS_V2 c ON s.CD_ID = c.CD_ID ORDER by INTEGER_IDX) as empty_sc"
val df = spark.read.jdbc(url=jdbcUrl, table=sql, properties=connectionProperties).cache()
df.createOrReplaceTempView("hive_columns")

// COMMAND ----------

// MAGIC %sql
// MAGIC select * from hive_columns
