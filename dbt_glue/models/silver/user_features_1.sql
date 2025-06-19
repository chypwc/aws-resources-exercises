{{ config(
    materialized='table',
    schema='imba_silver', 
    custom_location='s3://source-bucket-chien/imba-output/silver/user_features_1') }}

SELECT
    user_id,
    MAX(order_number) AS max_order_number,
    SUM(days_since_prior) AS total_days_since_prior,
    AVG(days_since_prior) AS avg_days_since_prior
FROM {{ source('sources', 'orders') }}
GROUP BY user_id