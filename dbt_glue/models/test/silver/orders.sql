{{ config(
    materialized='table',
    schema='sales_silver', 
    custom_location='s3://data-bucket-chien/output/silver/orders') }}

{#
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    schema='sales_silver',
    custom_location='s3://source-bucket-chien/output/silver/orders'
) }}
#}

select o.o_orderkey as order_key,
       CAST(o.o_orderdate AS DATE) as order_date,
       o.o_custkey as customer_key,
       o.o_totalprice as total_price
from {{ source('bronze_source', 'orders_raw_csv') }} o
where o.o_totalprice > 0 and o.o_orderdate is not null