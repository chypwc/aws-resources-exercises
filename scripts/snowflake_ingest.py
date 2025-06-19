import sys
import json
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
args = getResolvedOptions(sys.argv, ["CONNECTION_NAME", "TARGET_S3_BUCKET", "SF_SECRET_NAME"])
connection_name = args["CONNECTION_NAME"]
bucket = args["TARGET_S3_BUCKET"]
secret_name = args["SF_SECRET_NAME"]

# --- Fetch Snowflake credentials from Secrets Manager ---
secrets_client = boto3.client("secretsmanager")
secret_response = secrets_client.get_secret_value(SecretId=secret_name)
secret_dict = json.loads(secret_response["SecretString"])

sf_user = secret_dict["USERNAME"]
sf_password = secret_dict["PASSWORD"]
sf_account = secret_dict["ACCOUNT"]
sf_warehouse = secret_dict.get("sfWarehouse", "COMPUTE_WH")
sf_database = secret_dict.get("sfDatabase", "IMBA")
sf_schema = secret_dict.get("sfSchema", "PUBLIC")
sf_role = secret_dict.get("sfRole", "ACCOUNTADMIN")

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
                "sfUser": sf_user,
                "sfPassword": sf_password,
                "sfDatabase": sf_database,
                "sfSchema": sf_schema,
                "sfWarehouse": sf_warehouse,
                "dbtable": table_name,
                "sfRole": sf_role
            }
        )
        row_count = dyf.count()
        print(f"✔️ Retrieved {row_count} rows from {table_name}")

        # --- Write DynamicFrame directly as Parquet to S3 ---
        output_path = f"s3://{bucket}/snowflake_exports/{table_name}"
        dyf.toDF().repartition(10).write.mode("overwrite").parquet(output_path)
    
        print(f"✅ Exported {table_name} to {output_path}")
    
    except Exception as e:
        print(f"❗ Failed to process {table_name}: {e}")