{{ config(
    materialized='incremental',
    file_format='parquet',
    incremental_strategy='insert_overwrite',
    partition_by=['eval_set']
) }}

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