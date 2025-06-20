{{ config(
    materialized='table',
    schema='sales_silver', 
    custom_location='s3://data-bucket-chien/output/silver/dim_customer') }}

{#
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    schema='sales_silver',
    custom_location='s3://source-bucket-chien/output/silver/dim_customer'
) }}
#}


select c_custkey as customer_key,
       c_name as customer,
       c_nationkey as country_key,
       c_mktsegment as market_segment
from {{ source('bronze_source', 'customers_raw_csv') }}