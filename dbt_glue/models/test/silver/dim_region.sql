{{ config(
    materialized='table',
    schema='sales_silver', 
    custom_location='s3://source-bucket-chien/output/silver/dim_region') }}

{#
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    schema='sales_silver',
    custom_location='s3://source-bucket-chien/output/silver/dim_region'
) }}
#}



select r_regionkey as region_key,
       r_name as region
from {{ source('bronze_source', 'regions_raw_csv') }}