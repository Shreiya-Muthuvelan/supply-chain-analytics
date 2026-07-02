/* Overall bussiness health -  Total orders,revenue and profit */
SELECT COUNT(*) as total_orders,ROUND(SUM(order_item_total),2) as total_revenue,
SUM(order_profit_per_order) as total_profit,ROUND(AVG(order_item_total),2) as avg_order_value,
ROUND(SUM(order_profit_per_order) / NULLIF(SUM(order_item_total),0) * 100, 2) AS overall_margin_pct
from orders_clean;

/* Monthly order volume, revenue and margin trends */
SELECT EXTRACT(YEAR from order_date) as year_label,
SELECT EXTRACT(YEAR from order_date) as year_label,
EXTRACT(MONTH FROM order_date) as month_label,
COUNT(*) as total_orders,ROUND(SUM(order_item_total),2) as total_revenue,
SUM(order_profit_per_order) as total_profit,
ROUND(AVG(orders_active.order_item_total), 2) AS avg_order_value,
ROUND(SUM(orders_active.order_profit_per_order) / NULLIF(SUM(orders_active.order_item_total), 0) * 100, 2) AS margin_pct
FROM orders_active GROUP BY EXTRACT (YEAR from order_date),EXTRACT(MONTH from order_date)
ORDER BY EXTRACT(YEAR from order_date),EXTRACT(MONTH FROM order_date) ;

/* Revenue and profit by category -  Helps identify which category of products are sold more */
SELECT product_category_id,category_name,ROUND(SUM(order_item_total),2) as total_revenue
,SUM(order_profit_per_order) as total_profit
FROM orders_clean join product_details on orders_clean.order_item_cardprod_id=product_details.product_card_id
join category_details on product_details.product_category_id=category_details.category_id
GROUP BY product_category_id,category_name ORDER BY product_category_id;

/* Revenue, profit and margin by customer segment - Helps identify which segment of customers are more profitable */
SELECT customer_segment,ROUND(SUM(order_item_total),2) as total_revenue
,SUM(order_profit_per_order) as total_profit
FROM orders join customers on orders.order_customer_id=customers.customer_id GROUP BY customer_segment;

/* Order share by shipping mode */
SELECT shipping_mode,COUNT(*) AS n, ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM shipping_details GROUP BY shipping_mode ORDER BY n DESC;

/*  What share of orders are loss-making and how much revenue do they represent? */ 
SELECT profit_flag, COUNT(*) AS n,ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct,
ROUND(SUM(order_item_total), 2) AS revenue,ROUND(SUM(order_profit_per_order), 2) AS total_profit
FROM orders GROUP BY profit_flag ORDER BY n DESC;

/* Overall delivery performance distribution */ 
SELECT delivery_status, COUNT(*) AS n, ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM shipping_details GROUP BY delivery_status ORDER BY n DESC;

/* Top 10 products by revenue and volume */ 

-- By revenue
SELECT pd.product_name,ROUND(SUM(o.order_item_total), 2) AS total_revenue,SUM(o.order_item_quantity) AS total_units
FROM orders_clean o JOIN product_details pd ON o.order_item_cardprod_id = pd.product_card_id
GROUP BY pd.product_name ORDER BY total_revenue DESC LIMIT 10;

-- By volume (different products may rank here vs revenue - that contrast is the finding)
SELECT pd.product_name, SUM(o.order_item_quantity) AS total_units, ROUND(SUM(o.order_item_total), 2) AS total_revenue
FROM orders_clean o JOIN product_details pd ON o.order_item_cardprod_id = pd.product_card_id
GROUP BY pd.product_name ORDER BY total_units DESC LIMIT 10;