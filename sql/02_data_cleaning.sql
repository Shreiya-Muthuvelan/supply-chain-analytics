/*Inspecting Data*/

SELECT COUNT(*) FROM supply_chain_data;
SELECT * from supply_chain_data limit 10;

-- Check for null values
SELECT COUNT(*) as total_rows,
COUNT(*) FILTER (WHERE order_id is NULL) as null_order_id,
COUNT(*) FILTER (WHERE order_customer_id is NULL) as null_customer_id,
COUNT(*) FILTER (WHERE order_date is NULL) as null_order_date,
COUNT(*) FILTER (WHERE order_item_total IS NULL) AS null_total,
COUNT(*) FILTER (WHERE order_profit_per_order IS NULL) AS null_profit,
COUNT(*) FILTER (WHERE shipping_mode IS NULL) AS null_shipping_mode,
COUNT(*) FILTER (WHERE delivery_status IS NULL) AS null_delivery_status,
COUNT(*) FILTER (WHERE late_delivery_risk IS NULL) AS null_late_risk
FROM supply_chain_data;

/* CUSTOMERS TABLE*/
SELECT * from customers limit 10;
-- Upon checking we notice that customer_email is masked as 'XXXXX' across all columns so we verify that and drop it
SELECT DISTINCT customer_email FROM customers LIMIT 5;

-- Check for blank strings
SELECT COUNT(*) FILTER (WHERE TRIM(customer_email) = '') AS blank_email,
COUNT(*) FILTER (WHERE TRIM(customer_fname) = '') AS blank_fname,
COUNT(*) FILTER (WHERE TRIM(customer_city) = '') AS blank_city
FROM customers;

ALTER TABLE customers DROP COLUMN customer_email;
SELECT customer_segment, COUNT(*) FROM customers GROUP BY customer_segment;


/*ORDERS TABLE*/
SELECT * from orders limit 10;

-- Check for duplicate values
SELECT order_item_id, COUNT(*) FROM supply_chain_data GROUP BY order_item_id
HAVING COUNT(*) > 1;

-- Check for 0 or negative values where it shouldnt exist
SELECT COUNT(*) FILTER (WHERE order_item_total<=0) AS zero_neg_total,
COUNT(*) FILTER (WHERE order_item_quantity<=0) AS zero_neg_qty,
COUNT(*) FILTER (WHERE order_profit_per_order IS NULL) AS null_profit from orders;

-- Check distribution of order status
SELECT order_status ,COUNT(*) AS n,ROUND(COUNT(*)*100 / SUM(COUNT(*)) OVER(),2) as pct
FROM orders GROUP BY order_status ORDER BY n desc;

-- Create a view with only completed / closed deals for revenue based analysis 
CREATE VIEW orders_clean AS
SELECT * FROM orders
WHERE order_status IN ('COMPLETE','CLOSED')
AND order_item_total > 0
AND order_item_quantity > 0;

-- Create a view with other values for volume or demand related analysis 
CREATE VIEW orders_active AS
SELECT * FROM orders
WHERE order_status NOT IN ('CANCELED','SUSPECTED_FRAUD')
AND order_item_total > 0
AND order_item_quantity > 0;

-- Create derived column based on profit
ALTER TABLE orders ADD COLUMN profit_flag VARCHAR(20);
UPDATE orders SET profit_flag = CASE 
  WHEN order_profit_per_order > 0 THEN 'profitable'
  WHEN order_profit_per_order = 0 THEN 'breakeven'
  WHEN order_profit_per_order < 0 THEN 'loss_making'
END;


-- Check if profit value is consistent across tables
SELECT COUNT(*) AS inconsistent_rows
FROM sales_details s
JOIN orders o ON s.order_item_id = o.order_item_id
WHERE (s.benefit_per_order < 0 AND o.order_profit_per_order > 0)
   OR (s.benefit_per_order > 0 AND o.order_profit_per_order < 0);

/*SHIPPING DETAILS TABLE*/
SELECT * from shipping_details limit 10;

/* For shipping details we have two columns late_delivery_risk and delivery_status if we have rows with late_delivery_risk is false 
but order is delivered late those need to be removed*/
SELECT delivery_status,late_delivery_risk, COUNT(*) AS n
FROM shipping_details GROUP BY delivery_status, late_delivery_risk ORDER BY delivery_status, late_delivery_risk;


-- Check for unusual values
SELECT COUNT(*) FILTER (WHERE days_for_shipping_real < 0) AS negative_real, COUNT(*) FILTER (WHERE days_for_shipment_scheduled < 0) 
AS negative_scheduled, COUNT(*) FILTER (WHERE days_for_shipping_real > 60) AS suspiciously_long
FROM shipping_details;

-- Create a derived colummn to see the different between scheduled and actaul gap  - helps with operational analysis
ALTER TABLE shipping_details ADD COLUMN shipping_delay_days INT; 
UPDATE shipping_details SET shipping_delay_days = days_for_shipping_real - days_for_shipment_scheduled;

-- Create a derived column to measure performance of delivery
ALTER TABLE shipping_details ADD COLUMN delivery_performance VARCHAR(20);
UPDATE shipping_details SET delivery_performance = CASE
  WHEN shipping_delay_days < 0 THEN 'early'
  WHEN shipping_delay_days = 0 THEN 'on_time'
  WHEN shipping_delay_days > 0 THEN 'late'
END;
  

/*PRODUCT DETAILS TABLE*/
SELECT * from product_details limit 10;

-- product_description columns hold null values for all rows so verify it and drop it
SELECT COUNT(*) FILTER (WHERE product_description is not NULL)  FROM product_details; 
ALTER TABLE product_details DROP COLUMN product_description;

-- Check for null values
SELECT COUNT(*) FILTER (WHERE product_name is NULL OR product_price is NULL) from product_details;

-- Alter product_price to include only two decimal places
ALTER TABLE product_details ALTER COLUMN product_price TYPE NUMERIC(12,2);


/*CATEGORY DETAILS*/
SELECT * from category_details limit 10;

SELECT category_name, COUNT(*) from category_details GROUP BY category_name;

/*SALES DETAILS TABLE*/
SELECT * from sales_details limit 10;

-- Check for null values
SELECT COUNT(*) FILTER (WHERE benefit_per_order is NULL) AS null_benefit, COUNT(*) FILTER (WHERE sales_per_customer is NULL) AS null_sales
FROM sales_details;

-- Check for markert distribution
SELECT market, COUNT(*) AS n FROM sales_details GROUP BY market ORDER BY n DESC;

-- Negative benefit checking
SELECT COUNT(*) FILTER (WHERE benefit_per_order < 0) AS negative_benefit FROM sales_details;





