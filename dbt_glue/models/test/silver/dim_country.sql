{{ config(materialized='table', schema='silver') }}

select n_nationkey as country_key,
       n_name as country,
       n_regionkey as region_key
from {{ source('bronze_source', 'nations_raw') }}