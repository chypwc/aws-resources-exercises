

CREATE OR REPLACE TABLE order_products (
    order_id           INTEGER NOT NULL,
    product_id         INTEGER NOT NULL,
    add_to_cart_order  INTEGER NOT NULL,
    reordered          BOOLEAN NOT NULL,
    eval_set           VARCHAR(10) NOT NULL,  -- 'prior', 'train', or 'test'

    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

INSERT INTO order_products (order_id, product_id, add_to_cart_order, reordered, eval_set)
SELECT order_id, product_id, add_to_cart_order, reordered, 'prior'
FROM order_products__prior
UNION ALL
SELECT order_id, product_id, add_to_cart_order, reordered, 'train'
FROM order_products__train;