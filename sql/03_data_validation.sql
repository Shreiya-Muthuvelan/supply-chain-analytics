-- Check for row counts

SELECT COUNT(*) as total_count FROM supply_chain_data;
SELECT COUNT(*) as total_count FROM orders;
SELECT COUNT(*) as total_count FROM sales_details;
SELECT COUNT(*) as total_count FROM shipping_details;

SELECT COUNT(*) as total_count FROM product_details;
SELECT COUNT(*) as total_count FROM category_details;
SELECT COUNT(*) as total_count FROM customers;

SELECT COUNT(*) as total_order_active FROM orders_active;
SELECT COUNT(*) as total_order_clean FROM orders_clean;

-- Check for referential integrity
-- Any orders referencing customers that don't exist?
SELECT COUNT(*) AS orphaned_customers
FROM orders o
LEFT JOIN customers c ON o.order_customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Any orders referencing products that don't exist?
SELECT COUNT(*) AS orphaned_products
FROM orders o
LEFT JOIN product_details p ON o.order_item_cardprod_id = p.product_card_id
WHERE p.product_card_id IS NULL;

-- Any shipping rows without a matching order?
SELECT COUNT(*) AS orphaned_shipping
FROM shipping_details s
LEFT JOIN orders o ON s.order_item_id = o.order_item_id
WHERE o.order_item_id IS NULL;

-- Any sales rows without a matching order?
SELECT COUNT(*) AS orphaned_sales
FROM sales_details s
LEFT JOIN orders o ON s.order_item_id = o.order_item_id
WHERE o.order_item_id IS NULL;

-- Any products referencing categories that don't exist?
SELECT COUNT(*) AS orphaned_categories
FROM product_details p
LEFT JOIN category_details c ON p.product_category_id = c.category_id
WHERE c.category_id IS NULL;

-- Check if derived columns have no null value
SELECT profit_flag, COUNT(*) FROM orders GROUP BY profit_flag;
SELECT delivery_performance, COUNT(*) FROM shipping_details GROUP BY delivery_performance;


-- Range checks
SELECT 
  MIN(order_item_total) AS min_total,
  MAX(order_item_total) AS max_total,
  MIN(order_item_quantity) AS min_qty,
  MAX(order_item_quantity) AS max_qty,
  MIN(order_item_discount_rate) AS min_discount,
  MAX(order_item_discount_rate) AS max_discount
FROM orders;

SELECT 
  MIN(shipping_delay_days) AS min_delay,
  MAX(shipping_delay_days) AS max_delay,
  MIN(days_for_shipping_real) AS min_real,
  MAX(days_for_shipping_real) AS max_real
FROM shipping_details;

SELECT MIN(product_price), MAX(product_price), AVG(product_price) 
FROM product_details;

-- Shipping date should not be before order date
SELECT COUNT(*) AS ship_before_order
FROM orders o
JOIN shipping_details s ON o.order_item_id = s.order_item_id
WHERE s.shipping_date < o.order_date;



