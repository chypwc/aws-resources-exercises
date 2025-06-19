{{ config(
    materialized='table',
    schema='imba_silver', 
    custom_location='s3://source-bucket-chien/imba-output/silver/prd_features') }}

WITH product_seqquence AS (
    SELECT
        user_id,
        product_id,
        order_number,
        add_to_cart_order,
        reordered,
        ROW_NUMBER() OVER (
            PARTITION BY user_id, product_id
            ORDER BY order_number
        ) AS product_seq_time
    FROM {{ ref('order_products_prior') }}
)
SELECT
    product_id,
    COUNT(*) AS total_purchases,
    SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END) AS total_reorder,
    SUM(CASE WHEN product_seq_time = 1 THEN 1 ELSE 0 END) AS first_time_purchases,
    SUM(CASE WHEN product_seq_time = 2 THEN 1 ELSE 0 END) AS second_time_purchases
FROM product_seqquence
GROUP BY product_id
ORDER BY product_id