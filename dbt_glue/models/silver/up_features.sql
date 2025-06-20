{{ config(
    materialized='table',
    schema='imba_silver', 
    custom_location='s3://data-bucket-chien/imba-output/silver/up_feature') }}

SELECT
    user_id,
    product_id,
    COUNT(order_id) AS total_number_orders,
    MIN(order_number) AS min_order_number,
    MAX(order_number) AS max_order_number,
    AVG(add_to_cart_order) AS avg_add_to_cart_order
FROM {{ ref('order_products_prior') }}
GROUP BY user_id, product_id