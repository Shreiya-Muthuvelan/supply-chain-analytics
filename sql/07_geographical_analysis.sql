/*
Revenue and Profit by region
Three-level  breakdown: market → region → country
*/


SELECT sd.market,o.order_region,c.customer_country,COUNT(o.order_item_id) AS total_orders,
ROUND(SUM(o.order_item_total), 2) AS revenue,ROUND(SUM(o.order_profit_per_order), 2) AS profit,
ROUND(SUM(o.order_profit_per_order) / NULLIF(SUM(o.order_item_total), 0) * 100, 2) AS margin_pct FROM orders_clean o
JOIN sales_details sd ON o.order_item_id = sd.order_item_id JOIN customers c ON o.order_customer_id = c.customer_id
GROUP BY sd.market, o.order_region, c.customer_country ORDER BY revenue DESC;


/*
Late delivery rate by Region
SUM(late rows) / COUNT(all rows) *100
*/

SELECT o.order_region,COUNT(*) AS total_orders,
SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) AS late_orders,
ROUND(SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_rate_pct,
ROUND(AVG(sd.shipping_delay_days), 2) AS avg_delay_days
FROM orders_clean o JOIN shipping_details sd ON o.order_item_id = sd.order_item_id
GROUP BY o.order_region ORDER BY late_rate_pct DESC;

/*
Shipping mode by Region
What % of each regions orders use each shipping mode */

SELECT o.order_region,sd.shipping_mode,COUNT(*) AS total_orders,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY o.order_region), 2) AS pct_within_region
FROM orders_clean o JOIN shipping_details sd ON o.order_item_id = sd.order_item_id
GROUP BY o.order_region, sd.shipping_mode ORDER BY o.order_region, total_orders DESC;

/*
Profit margin by Region
Shows which regions have higher revenue but low margin
*/


SELECT o.order_region,sd.market,COUNT(*) AS total_orders,
ROUND(SUM(o.order_item_total), 2) AS total_revenue, ROUND(SUM(o.order_profit_per_order), 2) AS total_profit,
ROUND(AVG(o.order_profit_per_order), 2) AS avg_profit_per_order,
ROUND(SUM(o.order_profit_per_order) / NULLIF(SUM(o.order_item_total), 0) * 100, 2) AS margin_pct
FROM orders_clean o JOIN sales_details sd ON o.order_item_id = sd.order_item_id
GROUP BY o.order_region, sd.market ORDER BY total_revenue DESC;


/*Region by Shipping mode 
Which areas are late rate regions and check if they are from a specific shipping mode*/
SELECT o.order_region,sd.shipping_mode,COUNT(*) AS total_orders,
SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) AS late_orders,
ROUND(SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_rate_pct,
ROUND(AVG(sd.shipping_delay_days), 2) AS avg_delay_days
FROM orders_clean o JOIN shipping_details sd ON o.order_item_id = sd.order_item_id
GROUP BY o.order_region, sd.shipping_mode ORDER BY o.order_region, late_rate_pct DESC;