import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col, unix_timestamp, to_date, year, quarter, sum
from awsglue.dynamicframe import DynamicFrame

# Initialize Glue job
args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Load DynamicFrame from AWS Glue Catalog
dyf = glueContext.create_dynamic_frame.from_catalog(
    database="sales_db",
    table_name="sales_records_csv"
)

# Drop null fields
dyf = DropNullFields.apply(frame=dyf)
# dyf.printSchema()

# Convert to Spark DataFrame
df = dyf.toDF()
# df.show()

# Parse dates
spark.sql("set spark.sql.legacy.timeParserPolicy=LEGACY")

sales_df = df.withColumn("Order_Date",
                         to_date(unix_timestamp(col("order_date"), "MM/dd/yyyy").cast("timestamp"))) \
             .withColumn("Ship_Date",
                         to_date(unix_timestamp(col("ship_date"), "MM/dd/yyyy").cast("timestamp")))

# sales_df.show(10, truncate=True)

# Group by Region, Country, and time
aggregate_df = sales_df.groupBy(
    "Region", "Country",
    year("Order_Date").alias("year"),
    quarter("Order_Date").alias("quarter")
).agg(
    sum("Total_Revenue").alias("Total_Revenue_By_Region_Country"),
    sum("Total_Cost").alias("Total_Cost_By_Region_Country"),
    sum("Total_Profit").alias("Total_Profit_By_Region_Country")
)

aggregate_df = aggregate_df.orderBy("year", "quarter")
# aggregate_df.show()

# Rename columns for output table
aggregate_df = aggregate_df \
    .withColumnRenamed("Total_Revenue_By_Region_Country", "Total_Revenue") \
    .withColumnRenamed("Total_Cost_By_Region_Country", "Total_Cost") \
    .withColumnRenamed("Total_Profit_By_Region_Country", "Total_Profit")

# Convert to DynamicFrame for Redshift output
output_dyf = DynamicFrame.fromDF(aggregate_df, glueContext, "dymamic_frame")
output_dyf.toDF().show(5, truncate=False)

# Write to Redshift
glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=output_dyf,
    catalog_connection="redshift-demo-connection",
    connection_options={
        "dbtable": "aggregated_sales",
        "database": "dev"
    },
    redshift_tmp_dir="s3://data-bucket-chien/tmp/",
    transformation_ctx="redshift_output"
)

# Commit the job
job.commit()