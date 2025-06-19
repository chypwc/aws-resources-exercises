{{ config(materialized='table', schema='silver') }}

select o.o_orderkey as order_key,
       o.o_orderdate::date as order_date,
       o.o_custkey as customer_key,
       o.o_totalprice as total_price
from {{ source('bronze_source', 'orders_raw') }} o
where o.o_totalprice > 0 and o.o_orderdate is not null