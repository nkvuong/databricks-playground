# Databricks notebook source
# MAGIC %md
# MAGIC # Train and Score multiple prophet models at the same time. 
# MAGIC 
# MAGIC This is based of these posts:
# MAGIC - https://databricks.com/blog/2020/05/19/manage-and-scale-machine-learning-models-for-iot-devices.html
# MAGIC - https://databricks.com/blog/2020/01/27/time-series-forecasting-prophet-spark.html
# MAGIC - https://github.com/mlflow/mlflow/tree/master/examples/prophet
# MAGIC - https://databricks.com/blog/2021/04/06/fine-grained-time-series-forecasting-at-scale-with-facebook-prophet-and-apache-spark-updated-for-spark-3.html

# COMMAND ----------

# silence annoying prophet messages
import logging
logger = spark._jvm.org.apache.log4j
logging.getLogger("py4j").setLevel(logging.ERROR)

# COMMAND ----------

import pyspark.sql.functions as f

# number of time series to train prophet model on
series_num = 10

# number of data points in each time series
data_points = 1000

# generate a random DF for X stores, each store has Y number of data points
df = (spark.range(data_points * series_num).
      select(f.col("id").alias("record_id"), 
             (f.col("id") % series_num).alias("store_id"),
            (f.expr(f'date_add(current_date, cast(floor(id / {series_num}) as int))').alias("date"))).
      withColumn("sales", f.rand() * 1000))

# COMMAND ----------

display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Define the prophet training function

# COMMAND ----------

import time
import mlflow
import pandas as pd
from prophet import Prophet
from prophet.diagnostics import cross_validation
from prophet.diagnostics import performance_metrics

import pyspark.sql.types as t

train_return_schema = t.StructType([
  t.StructField('store_id', t.IntegerType()), #unique time series id
  t.StructField('model_path', t.StringType()), # path to the model for a given device
  t.StructField('rmse', t.FloatType())
])

def train_model(pandas_df: pd.DataFrame) -> pd.DataFrame:
  '''
  Trains an prophet model on the series of data
  '''
  # Timing code
  start_time = time.perf_counter()

  # Pull metadata
  store_id = pandas_df['store_id'].iloc[0]
  rolling_window = pandas_df['rolling_window'].iloc[0]
  run_id = pandas_df['run_id'].iloc[0] # Pulls run ID to do a nested run

  # Train the model
  X = pandas_df[['date', 'sales']].rename(columns={'date': 'ds', 'sales': 'y'})
  m = Prophet()
  m.fit(X)

  # Evaluate Metrics
  df_cv = cross_validation(m, initial="100 days", period="30 days", horizon="90 days")
  df_p = performance_metrics(df_cv, rolling_window=rolling_window)

  rmse = df_p.loc[0, "rmse"]

  # Resume the top level training
  with mlflow.start_run(run_id=run_id):
    with mlflow.start_run(run_name=f'Series {store_id}', nested=True) as run:
      mlflow.log_param("rolling_window", rolling_window)
      mlflow.log_metric("rmse", rmse)

      # log time run
      elapsed_time = time.perf_counter() - start_time
      mlflow.log_metric('Total Elapsed Time', elapsed_time)
      
      # log the prophet model as a pyfunc.PythonModel
      mlflow.prophet.log_model(m, f"{store_id}")

      artifact_uri = f"runs:/{run.info.run_id}/{store_id}"
      # Create a return pandas DataFrame that matches the schema above
      returnDF = pd.DataFrame([[store_id, artifact_uri, rmse]],
                             columns=['store_id', 'model_path', 'rmse'])

  return returnDF

# COMMAND ----------

with mlflow.start_run(run_name=f"Training Session for {series_num} stores") as run:
  run_id = run.info.run_uuid
  overall_start_time = time.perf_counter()
  mlflow.log_metric('Number of series trained', series_num)
  
  modelDF = (df
             .withColumn("run_id", f.lit(run_id)) # Add run id
             .withColumn("rolling_window", f.lit(0.1)) # Add the rolling window parameter
             .groupBy("store_id")
             .applyInPandas(train_model, schema=train_return_schema)
            )
  modelDF.cache()
  # doing this to trigger the df calculation and hence the pandas_udf to train the models
  modelDF.write.format("noop").mode("overwrite").save()
  
  # log overall time run
  overall_elapsed_time = time.perf_counter() - overall_start_time
  mlflow.log_metric('Total Elapsed Time', overall_elapsed_time)

# COMMAND ----------

# MAGIC %md
# MAGIC ### Parallel Prediction

# COMMAND ----------

from typing import Iterator
import numpy as np

# here is an example of wrapping a pandas_udf inside a class, for easier debugging & schema validation
class ProphetPredictor(object):
  
  apply_return_schema = {
      'store_id': int(1),
      'ds': np.datetime64('now'),
      'yhat': float(1.0),    
      'yhat_lower': float(1.0),
      'yhat_upper': float(1.0),
      'ERROR': str("")
      }

  spark_schema = spark.createDataFrame(pd.DataFrame(data=apply_return_schema, index=[0])).schema

  # creating a udf that takes an iterator of pd.DF and returns an iterator of pd.DF for mapInPandas
  @staticmethod
  def apply_model(iterator: Iterator[pd.DataFrame]) -> Iterator[pd.DataFrame]:
    '''
    Applies model to data for a particular series
    '''
    # We reference `schema` directly via the class here because we can't pass self into a pandas_udf (pandas_udf turns functions into static methods implicitly).
    schema = list(ProphetPredictor.apply_return_schema)
    
    # loop through the iterator
    for pandas_df in iterator:
      
      try:      
        # load the model from mlflow
        model_path = pandas_df['model_path'].iloc[0]
        model = mlflow.prophet.load_model(model_path)

        future = model.make_future_dataframe(periods=90, 
                                             freq="D",
                                             include_history=True)

        # get the predicted dataframe
        f_pd = model.predict(future)

        # get relevant fields from forecast
        f_pd = f_pd[['ds','yhat', 'yhat_upper', 'yhat_lower']]
        f_pd['store_id'] = pandas_df['store_id'].iloc[0]
        f_pd['ERROR'] = None
        
      except Exception as e:
        # Log the exception in an ERROR column
        f_pd = pd.DataFrame(columns=schema)
        f_pd = f_pd.append({'ERROR': f"{e.__class__.__name__}: {e}"}, ignore_index=True)
        f_pd['store_id'].iloc[0] = pandas_df['store_id'].iloc[0]

      # Check that predictions column has same columns as schema
      f_pd_cols = set(f_pd.columns)
      schema_set = set(schema)

      assert len(f_pd_cols.symmetric_difference(schema_set)) == 0, f"Prediction columns do not all match. Difference is {f_pd_cols.symmetric_difference(schema_set)}"        
      yield f_pd        

# COMMAND ----------

p = ProphetPredictor()

predictionDF = modelDF.mapInPandas(p.apply_model, schema=p.spark_schema)
predictionDF.cache()
predictionDF.createOrReplaceTempView("forecast")

# COMMAND ----------

# MAGIC %sql
# MAGIC 
# MAGIC SELECT
# MAGIC   store_id,
# MAGIC   ds,
# MAGIC   yhat,
# MAGIC   yhat_upper,
# MAGIC   yhat_lower
# MAGIC FROM forecast
# MAGIC WHERE store_id IN (1, 4, 5) 
# MAGIC ORDER BY store_id
