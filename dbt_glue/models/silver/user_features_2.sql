{{ config(
    materialized='table',
    schema='imba_silver', 
    custom_location='s3://data-bucket-chien/imba-output/silver/user_features_2') }}

SELECT
    user_id,
    COUNT(product_id) AS total_number_products,
    COUNT(DISTINCT product_id) AS total_number_distinct_products,
    SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END) * 1.0 /
        COUNT(CASE WHEN order_number > 1 THEN 1 ELSE NULL END) AS user_reorder_ratio
FROM {{ ref('order_products_prior') }}
GROUP BY user_id