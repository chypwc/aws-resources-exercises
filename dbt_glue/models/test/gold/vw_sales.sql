{{ config(
    mmaterialized='table',
    schema='sales_gold', 
    custom_location='s3://data-bucket-chien/output/silver/vw_sales') }}

with prep as (
    select o.order_date, c.customer, o.total_price,
           ctry.country,
           r.region
    from {{ source('silver_source', 'orders') }} o
    join {{ source('silver_source', 'dim_customer') }} c
      on o.customer_key = c.customer_key
    join {{ source('silver_source', 'dim_country') }} ctry 
      on c.country_key = ctry.country_key
    join {{ source('silver_source', 'dim_region') }} r 
      on ctry.region_key = r.region_key
)
select distinct region, country, order_date, sum(total_price) as sales
from prep
group by region, country, order_date