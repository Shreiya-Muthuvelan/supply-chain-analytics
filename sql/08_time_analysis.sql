/*
Monthy seasonality - checks for order volumne, revenue and late delivery spikes across months */


SELECT EXTRACT(MONTH FROM o.order_date) AS month_num,TO_CHAR(o.order_date, 'Month') AS month_name,
COUNT(o.order_item_id) AS total_orders,ROUND(SUM(o.order_item_total), 2) AS total_revenue,
SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) AS late_orders,
ROUND(SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_rate_pct
FROM orders_clean o JOIN shipping_details sd ON o.order_item_id = sd.order_item_id
GROUP BY month_num, month_name ORDER BY month_num;

/*Day of the week ordering patterns - identify volume, revenue and avg order value by day of the week*/
SELECT EXTRACT(DOW FROM o.order_date) AS day_num,TO_CHAR(o.order_date, 'Day') AS day_name,COUNT(o.order_item_id) AS total_orders,
ROUND(SUM(o.order_item_total), 2) AS total_revenue,ROUND(AVG(o.order_item_total), 2) AS avg_order_value,
ROUND(SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_rate_pct
FROM orders_clean o JOIN shipping_details sd ON o.order_item_id = sd.order_item_id
GROUP BY day_num, day_name ORDER BY day_num;



/*Year by year delivery performance - tracks on time vs late delivery rates between years*/
SELECT EXTRACT(YEAR FROM sd.shipping_date) AS year,COUNT(*) AS total_shipments,
SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) AS late_count,
SUM(CASE WHEN sd.delivery_status != 'Late delivery' THEN 1 ELSE 0 END) AS on_time_count,
ROUND(SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_rate_pct,
ROUND(SUM(CASE WHEN sd.delivery_status != 'Late delivery' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS on_time_rate_pct
FROM shipping_details sd GROUP BY year ORDER BY year;

/*Year by year revenue and volume growth*/
WITH yearly AS (SELECT EXTRACT(YEAR FROM order_date) AS year,COUNT(order_item_id) AS total_orders,
ROUND(SUM(order_item_total), 2) AS total_revenue,ROUND(SUM(order_profit_per_order), 2) AS total_profit
FROM orders_clean GROUP BY year)
SELECT year,total_orders,total_revenue,total_profit, LAG(total_revenue) OVER (ORDER BY year) AS prev_year_revenue,
ROUND((total_revenue - LAG(total_revenue) OVER (ORDER BY year)) / NULLIF(LAG(total_revenue) OVER (ORDER BY year), 0) * 100, 2) AS revenue_growth_pct,
ROUND((total_orders - LAG(total_orders) OVER (ORDER BY year)) / NULLIF(LAG(total_orders) OVER (ORDER BY year), 0) * 100, 2) AS volume_growth_pct
FROM yearly ORDER BY year;


/*Lead Time Trend Over Time (Q24)- Tracks avg actual shipping days per month over time*/

WITH monthly AS (SELECT EXTRACT(YEAR FROM sd.shipping_date) AS year,EXTRACT(MONTH FROM sd.shipping_date) AS month,
TO_CHAR(sd.shipping_date, 'YYYY-MM') AS year_month,ROUND(AVG(sd.days_for_shipping_real), 2) AS avg_actual_days,
ROUND(AVG(sd.days_for_shipment_scheduled), 2) AS avg_scheduled_days, ROUND(AVG(sd.shipping_delay_days), 2) AS avg_delay_days,
COUNT(*) AS total_shipments FROM shipping_details sd GROUP BY year, month, year_month)
SELECT *,LAG(avg_actual_days) OVER (ORDER BY year, month) AS prev_month_actual_days,
ROUND(avg_actual_days - LAG(avg_actual_days) OVER (ORDER BY year, month), 2) AS mom_change_days
FROM monthly ORDER BY year, month;



/*Discount Timing and Profit Impact - Checks whether discounts cluster around specific months */

SELECT EXTRACT(MONTH FROM o.order_date) AS month_num,TO_CHAR(o.order_date, 'Month') AS month_name,
COUNT(o.order_item_id) AS total_orders,ROUND(AVG(o.order_item_discount_rate), 4) AS avg_discount_rate,
SUM(CASE WHEN o.order_item_discount_rate > 0 THEN 1 ELSE 0 END) AS discounted_orders,
ROUND(SUM(CASE WHEN o.order_item_discount_rate > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_discounted,
ROUND(AVG(o.order_profit_per_order), 2) AS avg_profit,ROUND(SUM(o.order_profit_per_order), 2) AS total_profit
FROM orders_clean o GROUP BY month_num, month_name ORDER BY month_num;


/*Month by Shipping Mode Late Rate - Checks whether seasonal late delivery spikes are driven by a specific shipping mode*/

SELECT EXTRACT(MONTH FROM o.order_date) AS month_num,TO_CHAR(o.order_date, 'Month') AS month_name,
sd.shipping_mode,COUNT(*) AS total_orders,
ROUND(SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_rate_pct
FROM orders_clean o JOIN shipping_details sd ON o.order_item_id = sd.order_item_id
GROUP BY month_num, month_name, sd.shipping_mode ORDER BY month_num, late_rate_pct DESC;