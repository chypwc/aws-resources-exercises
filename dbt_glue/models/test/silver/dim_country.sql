{{ config(
    materialized='table',
    schema='sales_silver', 
    custom_location='s3://source-bucket-chien/output/silver/dim_country') }}

{#
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    schema='sales_silver',
    custom_location='s3://source-bucket-chien/output/silver/dim_country'
) }}
#}

select n_nationkey as country_key,
       n_name as country,
       n_regionkey as region_key
from {{ source('bronze_source', 'nations_raw_csv') }}