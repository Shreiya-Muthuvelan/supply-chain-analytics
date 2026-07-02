SELECT * from supply_chain_data limit 10;

-- Inspecting Data types 
ALTER TABLE supply_chain_data 
	ALTER COLUMN benefit_per_order TYPE NUMERIC(12,2),
	ALTER COLUMN sales_per_customer TYPE NUMERIC(12,2),
	ALTER COLUMN latitude TYPE NUMERIC(12,2),
	ALTER COLUMN longitude TYPE NUMERIC(12,2),
	ALTER COLUMN order_item_discount TYPE NUMERIC(12,2),
	ALTER COLUMN order_item_discount_rate TYPE NUMERIC(12,2),
	ALTER COLUMN order_item_profit_ratio TYPE NUMERIC(12,2),
	ALTER COLUMN order_profit_per_order TYPE NUMERIC(12,2);

ALTER TABLE supply_chain_data ALTER COLUMN late_delivery_risk TYPE boolean 
USING late_delivery_risk::boolean;
ALTER TABLE supply_chain_data ALTER COLUMN product_status TYPE boolean 
USING product_status::boolean;

ALTER TABLE supply_chain_data ADD COLUMN order_date DATE, ADD COLUMN order_time TIME;

UPDATE supply_chain_data SET order_date=TO_TIMESTAMP
(order_date_date,'MM/DD/YYYY HH24:MI')::DATE,
order_time=TO_TIMESTAMP(order_date_date,'MM/DD/YYYY HH24:MI')::TIME;

ALTER TABLE supply_chain_data ADD COLUMN shipping_date DATE,ADD COLUMN shipping_time TIME;


UPDATE supply_chain_data SET shipping_date=TO_TIMESTAMP(shipping_date_date,'MM/DD/YYYY HH24:MI')::DATE,
shipping_time=TO_TIMESTAMP(shipping_date_date,'MM/DD/YYYY HH24:MI')::TIME;

-- Creating tables
CREATE TABLE customers AS
SELECT DISTINCT customer_id, customer_city, customer_country, customer_email,
customer_fname, customer_lname, customer_segment, customer_state,
customer_street, customer_zipcode
FROM supply_chain_data;

CREATE TABLE product_details AS
SELECT DISTINCT product_card_id, product_category_id, product_description,
product_name, product_price, product_status
FROM supply_chain_data;

CREATE TABLE category_details AS
SELECT DISTINCT category_id, category_name
FROM supply_chain_data;

CREATE TABLE orders AS
SELECT order_item_id, order_id, order_city, order_country, order_customer_id,
order_date,order_time, order_item_cardprod_id, order_item_discount, order_item_discount_rate,
order_item_product_price, order_item_profit_ratio, order_item_quantity,
order_item_total, order_profit_per_order, order_region, order_state, order_status, type
FROM supply_chain_data;

CREATE TABLE shipping_details AS
SELECT order_item_id, order_id, days_for_shipping_real, days_for_shipment_scheduled,
delivery_status, late_delivery_risk, shipping_mode, shipping_date,shipping_time, latitude, longitude
FROM supply_chain_data;

CREATE TABLE sales_details AS
SELECT order_item_id, order_id, benefit_per_order, sales_per_customer, market
FROM supply_chain_data;

-- Creating Indexes 
CREATE INDEX idx_orders_order_item_id ON orders(order_item_id);
CREATE INDEX idx_orders_order_id ON orders(order_id);
CREATE INDEX idx_orders_customer_id ON orders(order_customer_id);
CREATE INDEX idx_orders_product_id ON orders(order_item_cardprod_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_shipping_order_item_id ON shipping_details(order_item_id);
CREATE INDEX idx_customers_customer_id ON customers(customer_id);
CREATE INDEX idx_products_product_id ON product_details(product_card_id);

-- Primary Key Assignment
SELECT category_id, COUNT(DISTINCT category_name) 
FROM supply_chain_data GROUP BY category_id HAVING COUNT(DISTINCT category_name) > 1;
ALTER TABLE category_details ADD primary key(category_id);

SELECT customer_id,COUNT(DISTINCT customer_email) AS n_email,COUNT(DISTINCT customer_city) AS n_city,
COUNT(DISTINCT customer_zipcode) AS n_zip FROM supply_chain_data
GROUP BY customer_id HAVING COUNT(DISTINCT customer_email) > 1
OR COUNT(DISTINCT customer_city) > 1 OR COUNT(DISTINCT customer_zipcode) > 1;
ALTER TABLE customers ADD PRIMARY KEY (customer_id);


SELECT order_item_id, COUNT(*) FROM orders GROUP BY order_item_id HAVING COUNT(*) > 1;
ALTER TABLE orders ADD PRIMARY KEY (order_item_id);

SELECT * FROM product_details;
SELECT product_card_id,COUNT(*) FROM product_details GROUP BY product_card_id HAVING COUNT(*)>1;
ALTER TABLE product_details ADD PRIMARY KEY(product_card_id);

SELECT order_item_id, COUNT(*) FROM sales_details GROUP BY order_item_id HAVING COUNT(*) > 1;
ALTER TABLE sales_details ADD PRIMARY KEY (order_item_id);


SELECT order_item_id, COUNT(*) FROM shipping_details GROUP BY order_item_id HAVING COUNT(*) > 1;
ALTER TABLE shipping_details ADD PRIMARY KEY (order_item_id);

-- Foreign Key Constraints
ALTER TABLE product_details 
ADD CONSTRAINT fk_product_category 
FOREIGN KEY (product_category_id) REFERENCES category_details(category_id);

ALTER TABLE orders 
ADD CONSTRAINT fk_orders_customer 
FOREIGN KEY (order_customer_id) REFERENCES customers(customer_id);

ALTER TABLE orders 
ADD CONSTRAINT fk_orders_product 
FOREIGN KEY (order_item_cardprod_id) REFERENCES product_details(product_card_id);

ALTER TABLE shipping_details 
ADD CONSTRAINT fk_shipping_order 
FOREIGN KEY (order_item_id) REFERENCES orders(order_item_id);

ALTER TABLE sales_details 
ADD CONSTRAINT fk_sales_order 
FOREIGN KEY (order_item_id) REFERENCES orders(order_item_id);
