{{ config(materialized='table', schema='silver') }}

select r_regionkey as region_key,
       r_name as region
from {{ source('bronze_source', 'regions_raw') }}