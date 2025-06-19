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
tables = ["orders", "products", "departments", "aisles", "order_products__prior", "order_products__train"]

for table_name in tables:
    try:
        print(f"📥 Reading Snowflake table: {table_name}")

        # --- Read from Snowflake using Glue native connector ---
        dyf = glueContext.create_dynamic_frame.from_options(
            connection_type="snowflake",
            connection_options={
                "connectionName": connection_name,
                "dbtable": table_name,
                # "sfDatabase": "IMBA",
                # "sfSchema": "PUBLIC",
                # "sfWarehouse": "COMPUTE_WH",
                # "sfRole": "ACCOUNTADMIN"
            }
        )
        row_count = dyf.count()
        print(f"✔️ Retrieved {row_count} rows from {table_name}")

        # --- Write DynamicFrame directly as Parquet to S3 ---
        output_path = f"s3://{bucket}/snowflake_exports/{table_name}"
        dyf.toDF().write.mode("overwrite").parquet(output_path)
    
        print(f"✅ Exported {table_name} to {output_path}")
    
    except Exception as e:
        print(f"❗ Failed to process {table_name}: {e}")