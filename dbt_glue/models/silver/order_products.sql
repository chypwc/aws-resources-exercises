{{ config(
    materialized='table',
    schema='imba_silver', 
    custom_location='s3://data-bucket-chien/imba-output/silver/order_products') }}

SELECT
    order_id,
    product_id,
    add_to_cart_order,
    reordered,
    'prior' AS eval_set
FROM {{ source('sources', 'order_products__prior') }}

UNION ALL

SELECT
    order_id,
    product_id,
    add_to_cart_order,
    reordered,
    'train' AS eval_set
FROM {{ source('sources', 'order_products__train') }}