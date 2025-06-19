{{ config(
    materialized='table',
    schema='imba_silver', 
    custom_location='s3://source-bucket-chien/imba-output/silver/order_products_prior') }}

select o.*,
            op.product_id,
            op.add_to_cart_order,
            op.reordered
from {{ source('sources', 'orders') }} o
join {{ ref('order_products') }} op
on o.order_id = op.order_id
where o.eval_set = 'prior' 