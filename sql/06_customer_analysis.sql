/*
RFM Segmentation 
computes recency, frequency and monetary value per customer
then scores each 1-3 using NTILE and summarizes by segment
Higher avg_rfm_score -> more engaged, higher-value segment
*/

-- compute RFM per customer
WITH rfm AS (SELECT o.order_customer_id,c.customer_segment,MAX(o.order_date) AS last_purchase_date,
CURRENT_DATE - MAX(o.order_date) AS recency_days,COUNT(o.order_item_id) AS frequency,
ROUND(SUM(o.order_item_total), 2) AS monetary FROM orders_clean o JOIN customers c ON 
o.order_customer_id = c.customer_id GROUP BY o.order_customer_id, c.customer_segment),

rfm_scored AS (SELECT *,NTILE(3) OVER (ORDER BY recency_days ASC) AS r_score,
NTILE(3) OVER (ORDER BY frequency DESC) AS f_score,NTILE(3) OVER (ORDER BY monetary DESC) AS m_score FROM rfm
)
--  summarize by segment
SELECT customer_segment,COUNT(*) AS customer_count,ROUND(AVG(recency_days), 0) AS avg_recency_days,
ROUND(AVG(frequency), 2) AS avg_frequency,ROUND(AVG(monetary), 2) AS avg_monetary,
ROUND(AVG(r_score + f_score + m_score), 2) AS avg_rfm_score FROM rfm_scored GROUP BY customer_segment
ORDER BY avg_rfm_score DESC;

/*
Repeat Customer Rate (Q12)

Counts orders per customer then checks what % placed more than one order
 repeat_rate_pct is more meaningful than avg frequency alone */

-- by segment
WITH orders_per_customer AS (SELECT c.customer_id,c.customer_segment,c.customer_country,
COUNT(o.order_item_id) AS order_count FROM orders_clean o JOIN customers c ON o.order_customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_segment, c.customer_country)

SELECT customer_segment, COUNT(*) AS total_customers,ROUND(AVG(order_count), 2) AS avg_orders_per_customer,
SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
ROUND(SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS repeat_rate_pct
FROM orders_per_customer GROUP BY customer_segment ORDER BY repeat_rate_pct DESC;


-- by country
WITH orders_per_customer AS (SELECT c.customer_id,c.customer_segment,c.customer_country,COUNT(o.order_item_id) 
AS order_count FROM orders_clean o JOIN customers c ON o.order_customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_segment, c.customer_country
)
SELECT customer_country,COUNT(*) AS total_customers,ROUND(AVG(order_count), 2) AS avg_orders_per_customer,
ROUND(SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS repeat_rate_pct
FROM orders_per_customer GROUP BY customer_country ORDER BY repeat_rate_pct DESC;


/*
Late Delivery Exposure by Segment 
Measures both the rate of late delivery risk and the revenue value exposed
*/
SELECT c.customer_segment, COUNT(*) AS total_orders,
SUM(CASE WHEN sd.late_delivery_risk = true THEN 1 ELSE 0 END) AS late_risk_orders,
ROUND(SUM(CASE WHEN sd.late_delivery_risk = true THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_risk_pct,
ROUND(SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN o.order_item_total ELSE 0 END), 2) AS revenue_at_risk
FROM shipping_details sd JOIN orders o ON sd.order_item_id = o.order_item_id 
JOIN customers c ON c.customer_id = o.order_customer_id
GROUP BY c.customer_segment ORDER BY late_risk_pct DESC;

/*
Customer Lifetime Value by Segment 
Approximates CLV as total revenue and profit per customer over their active lifespan
avg_lifespan_days shows how long customers stay engaged with the business */

WITH clv AS (SELECT c.customer_id,c.customer_segment,COUNT(o.order_item_id) AS total_orders,
ROUND(SUM(o.order_item_total), 2) AS total_revenue,ROUND(SUM(o.order_profit_per_order), 2) AS total_profit,
MAX(o.order_date) - MIN(o.order_date) AS customer_lifespan_day FROM orders_clean o JOIN customers c
ON o.order_customer_id = c.customer_id GROUP BY c.customer_id, c.customer_segment)
SELECT customer_segment,COUNT(*) AS total_customers,ROUND(AVG(total_revenue), 2) AS avg_clv,
ROUND(AVG(total_profit), 2) AS avg_profit_per_customer,ROUND(AVG(total_orders), 2) AS avg_orders,
ROUND(AVG(customer_lifespan_days), 0) AS avg_lifespan_days FROM clv
GROUP BY customer_segment ORDER BY avg_clv DESC;

/*
Discount Sensitivity 
Buckets discount rates and measures profit erosion at each level
loss_rate_pct shows at what discount threshold orders become loss-making
*/
SELECT CASE 
WHEN order_item_discount_rate = 0 THEN 'No discount'
WHEN order_item_discount_rate <= 0.05 THEN 'Low (1-5%)'
WHEN order_item_discount_rate <= 0.10 THEN 'Medium (6-10%)'
WHEN order_item_discount_rate <= 0.20 THEN 'High (11-20%)'
ELSE 'Very high (>20%)'END AS discount_bucket,
COUNT(*) AS total_orders,ROUND(AVG(order_profit_per_order), 2) AS avg_profit,
ROUND(AVG(order_item_total), 2) AS avg_order_value,SUM(CASE WHEN order_profit_per_order < 0 THEN 1 ELSE 0 END) 
AS loss_making_orders,ROUND(SUM(CASE WHEN order_profit_per_order < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) 
AS loss_rate_pct FROM orders_clean GROUP BY discount_bucket ORDER BY MIN(order_item_discount_rate);

