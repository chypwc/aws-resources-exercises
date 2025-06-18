import sys
import boto3
import pyarrow as pa
import pyarrow.parquet as pq
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from pyspark.context import SparkContext

# --- Glue context ---
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# --- Job parameters ---
args = getResolvedOptions(sys.argv, ["CONNECTION_NAME", "TARGET_S3_BUCKET"])
connection_name = args["CONNECTION_NAME"]
bucket = args["TARGET_S3_BUCKET"]

# --- Snowflake tables to export ---
tables = ["orders", "products", "departments", "aisles", "order_products"]

for table_name in tables:
    print(f"📥 Reading Snowflake table: {table_name}")

    # --- Read from Snowflake using Glue native connector ---
    dyf = glueContext.create_dynamic_frame.from_options(
        connection_type="snowflake",
        connection_options={
            "connectionName": connection_name,
            "dbtable": table_name,
            "sfDatabase": "IMBA",
            "sfSchema": "PUBLIC",
            "sfWarehouse": "COMPUTE_WH",
            "sfRole": "ACCOUNTADMIN"
        }
    )

    # --- Convert to Pandas DataFrame ---
    df = dyf.toDF().limit(1000).toPandas()

    # --- Save as Parquet ---
    table = pa.Table.from_pandas(df)
    local_file = f"/tmp/{table_name}.parquet"
    pq.write_table(table, local_file)

    # --- Upload to S3 ---
    s3_key = f"snowflake_exports/{table_name}.parquet"
    s3 = boto3.client("s3")
    s3.upload_file(local_file, bucket, s3_key)

    print(f"✅ Uploaded to s3://{bucket}/{s3_key}")