import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# -----------------------
# JOB PARAMETER SETUP
# -----------------------
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# -----------------------
# CONFIGURATION SECTION
# -----------------------
s3_input_path = "s3://source-bucket-chien/input/"
redshift_tmp_dir = "s3://data-bucket-chien/tmp/"
redshift_db_name = "dev"
redshift_table_name = "aggregated_sales"
catalog_connection_name = "redshift-demo-connection"

# -----------------------
# READ CSV FILES FROM S3 (RECURSIVE)
# -----------------------
datasource_dyf = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={
        "paths": [s3_input_path],
        "recurse": True
    },
    format="csv",
    format_options={"withHeader": True}
)

# -----------------------
# OPTIONAL: DATA CLEANING OR TRANSFORMATION
# -----------------------
# Example: apply mappings or resolve choice
# datasource_dyf = ApplyMapping.apply(frame=datasource_dyf, mappings=[...])
# datasource_dyf = datasource_dyf.resolveChoice(...)

# -----------------------
# WRITE TO REDSHIFT USING CATALOG CONNECTION
# -----------------------
glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=datasource_dyf,
    catalog_connection=catalog_connection_name,
    connection_options={
        "dbtable": redshift_table_name,
        "database": redshift_db_name
    },
    redshift_tmp_dir=redshift_tmp_dir,
    transformation_ctx="redshift_output"
)

job.commit()