import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
import snowflake.connector
import boto3
import os
import json

# --- Load credentials from AWS Secrets Manager ---
def load_snowflake_secrets(secret_name):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

# --- Retrieve secret and config values ---
secret_name = os.environ["SF_SECRET_NAME"]
config = load_snowflake_secrets(secret_name)

sf_user = config["username"]
sf_password = config["password"]
sf_account = config["account"]
sf_warehouse = config["warehouse"]
sf_database = config["database"]
sf_schema = config["schema"]
sf_role = "ACCOUNTADMIN"

# --- Connect to Snowflake ---
conn = snowflake.connector.connect(
    user=sf_user,
    password=sf_password,
    account=sf_account,
    warehouse=sf_warehouse,
    database=sf_database,
    schema=sf_schema,
    role=sf_role
)

# --- Run Query ---
tables = ["orders", "products", "departments", "aisles", "order_products"]
for table_name in tables:
    query = f"SELECT * FROM {table_name} LIMIT 1000;"
    df = pd.read_sql(query, conn)

    # --- Save as Parquet ---
    table = pa.Table.from_pandas(df)
    local_file = f"/tmp/{table_name}.parquet"
    pq.write_table(table, local_file)

    # --- Upload to S3 ---
    s3 = boto3.client('s3')
    bucket = os.environ["TARGET_S3_BUCKET"]
    key = f"snowflake_exports/{table_name}.parquet"
    s3.upload_file(local_file, bucket, key)

    print(f"✅ Uploaded to s3://{bucket}/{key}")

conn.close()
