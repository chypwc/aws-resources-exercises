{{ config(materialized='table', schema='silver') }}

select c_custkey as customer_key,
       c_name as customer,
       c_nationkey as country_key,
       c_mktsegment as market_segment
from {{ source('bronze_source', 'customers_raw') }}