

/* Composite late delivery risk score - scores each combination of category , region and shipping mode
by combining late rate, avg delay and order volume*/
WITH base AS (SELECT cd.category_name,o.order_region,sd.shipping_mode,COUNT(*) AS total_orders,
ROUND(SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_rate_pct,
ROUND(AVG(CASE WHEN sd.shipping_delay_days > 0 THEN sd.shipping_delay_days END), 2) AS avg_delay_when_late,
ROUND(SUM(o.order_item_total), 2) AS total_revenue FROM orders_clean o
JOIN shipping_details sd ON o.order_item_id = sd.order_item_id
JOIN product_details pd ON o.order_item_cardprod_id = pd.product_card_id
JOIN category_details cd ON pd.product_category_id = cd.category_id
GROUP BY cd.category_name, o.order_region, sd.shipping_mode
HAVING COUNT(*) >= 50 ),scored AS (SELECT *,
    -- Normalize each signal to 1-3 using NTILE then combine 
NTILE(3) OVER (ORDER BY late_rate_pct ASC) AS late_rate_score,NTILE(3) OVER (ORDER BY avg_delay_when_late ASC) AS delay_magnitude_score,
NTILE(3) OVER (ORDER BY total_orders DESC) AS volume_score FROM base)
SELECT category_name, order_region, shipping_mode,  total_orders, late_rate_pct, avg_delay_when_late, total_revenue,
late_rate_score + delay_magnitude_score + volume_score AS risk_score FROM scored ORDER BY risk_score DESC, total_revenue DESC LIMIT 20;



/*Customer cohort retention - groups customers by month of their first order, and then trackes what % of each cohort
placed a second order in following months */
WITH first_orders AS (SELECT order_customer_id,MIN(order_date) AS first_order_date,DATE_TRUNC('month', MIN(order_date)) AS cohort_month
FROM orders_active GROUP BY order_customer_id),
customer_orders AS (SELECT o.order_customer_id,fo.cohort_month,DATE_TRUNC('month', o.order_date) AS order_month,
EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', o.order_date), fo.cohort_month)) * 12 +
EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', o.order_date), fo.cohort_month)) AS months_since_first
FROM orders_active o JOIN first_orders fo ON o.order_customer_id = fo.order_customer_id),
cohort_size AS (SELECT cohort_month, COUNT(DISTINCT order_customer_id) AS total_customers FROM first_orders GROUP BY cohort_month),
retention AS (SELECT co.cohort_month,co.months_since_first,COUNT(DISTINCT co.order_customer_id) AS active_customers
FROM customer_orders co GROUP BY co.cohort_month, co.months_since_first)
SELECT r.cohort_month,cs.total_customers AS cohort_size,r.months_since_first,r.active_customers,
ROUND(r.active_customers * 100.0 / cs.total_customers, 2) AS retention_pct FROM retention r
JOIN cohort_size cs ON r.cohort_month = cs.cohort_month ORDER BY r.cohort_month, r.months_since_first;




/*Profit leakage analysis - identifies which category, region , shipping mode have high volume but very low profit*/
WITH combo AS (SELECT cd.category_name,o.order_region,sd.shipping_mode,sl.market,
COUNT(*) AS total_orders,ROUND(SUM(o.order_item_total), 2) AS total_revenue,
ROUND(SUM(o.order_profit_per_order), 2) AS total_profit,ROUND(SUM(o.order_profit_per_order) / NULLIF(SUM(o.order_item_total), 0) * 100, 2) AS margin_pct,
ROUND(AVG(o.order_item_discount_rate), 4) AS avg_discount_rate FROM orders_clean o
JOIN shipping_details sd ON o.order_item_id = sd.order_item_id
JOIN sales_details sl ON o.order_item_id = sl.order_item_id
JOIN product_details pd ON o.order_item_cardprod_id = pd.product_card_id
JOIN category_details cd ON pd.product_category_id = cd.category_id
GROUP BY cd.category_name, o.order_region, sd.shipping_mode, sl.market HAVING COUNT(*) >= 30),
ranked AS (SELECT *,NTILE(4) OVER (ORDER BY total_orders DESC) AS volume_quartile,NTILE(4) OVER (ORDER BY margin_pct ASC) AS margin_quartile
FROM combo)
SELECT category_name, order_region, shipping_mode, market, total_orders, total_revenue, total_profit, margin_pct, avg_discount_rate,
volume_quartile, margin_quartile FROM ranked WHERE volume_quartile = 1 AND margin_quartile = 1 ORDER BY total_profit ASC;


/*Rolling 3 month revenue and late rate*/
WITH monthly AS (SELECT EXTRACT(YEAR FROM o.order_date) AS year,EXTRACT(MONTH FROM o.order_date) AS month,TO_CHAR(o.order_date, 'YYYY-MM') AS year_month,
COUNT(o.order_item_id) AS total_orders,ROUND(SUM(o.order_item_total), 2) AS total_revenue,
ROUND(SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_rate_pct
FROM orders_clean o JOIN shipping_details sd ON o.order_item_id = sd.order_item_id
GROUP BY year, month, year_month )
SELECT year_month, total_orders, total_revenue, late_rate_pct,ROUND(AVG(total_revenue) OVER (ORDER BY year, month ROWS BETWEEN 2 
PRECEDING AND CURRENT ROW), 2) AS rolling_3m_revenue,
ROUND(AVG(late_rate_pct) OVER (ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS 
rolling_3m_late_rate,ROUND(AVG(total_orders) OVER (ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0) 
AS rolling_3m_orders FROM monthly ORDER BY year, month;


-- ============================================
-- SECTION 5: First Order Predicts Long-Term Value (Extension)
-- ============================================

-- Tests whether a customer's first order value or category
-- predicts their total lifetime spend — useful for identifying
-- high-value customer acquisition signals early

/*First order predicts long term value - checks if a customers first order value or category can predict
their lifetime spend */
WITH first_order AS (SELECT DISTINCT ON (order_customer_id) order_customer_id, order_item_total AS first_order_value,
order_item_cardprod_id AS first_product_id,order_date AS first_order_date FROM orders_clean
ORDER BY order_customer_id, order_date ASC ),
lifetime AS (SELECT order_customer_id,COUNT(order_item_id) AS total_orders,ROUND(SUM(order_item_total), 2) AS lifetime_revenue,
ROUND(SUM(order_profit_per_order), 2) AS lifetime_profit FROM orders_clean GROUP BY order_customer_id)
SELECT CASE 
    WHEN fo.first_order_value < 50 THEN 'Low first order (<$50)'
    WHEN fo.first_order_value < 200 THEN 'Mid first order ($50-200)'
    ELSE 'High first order (>$200)'
  END AS first_order_bucket,
COUNT(*) AS customer_count,ROUND(AVG(l.total_orders), 2) AS avg_subsequent_orders,ROUND(AVG(l.lifetime_revenue), 2) AS avg_lifetime_revenue,
ROUND(AVG(l.lifetime_profit), 2) AS avg_lifetime_profit FROM first_order fo
JOIN lifetime l ON fo.order_customer_id = l.order_customer_id GROUP BY first_order_bucket
ORDER BY avg_lifetime_revenue DESC;



/*Rolling discount window vs profit- checks is discount rate is creeping up over time*/
WITH monthly AS (SELECT EXTRACT(YEAR FROM order_date) AS year, EXTRACT(MONTH FROM order_date) AS month,
TO_CHAR(order_date, 'YYYY-MM') AS year_month,ROUND(AVG(order_item_discount_rate), 4) AS avg_discount_rate,
ROUND(AVG(order_profit_per_order), 2) AS avg_profit,ROUND(SUM(order_profit_per_order) / NULLIF(SUM(order_item_total), 0) * 100, 2) AS margin_pct
FROM orders_clean GROUP BY year, month, year_month)
SELECT year_month, avg_discount_rate, avg_profit, margin_pct,ROUND(AVG(avg_discount_rate) OVER (
ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 4) AS rolling_3m_discount,
ROUND(AVG(margin_pct) OVER (ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_3m_margin
FROM monthly ORDER BY year, month;




/*Operational recommendation query - combines late delivery rate , order volumne and profit impact*/
WITH combo AS (SELECT o.order_region,cd.category_name,sl.market,
COUNT(*) AS total_orders,
ROUND(SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_rate_pct,
ROUND(SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN o.order_item_total ELSE 0 END), 2) AS revenue_at_risk,
ROUND(SUM(o.order_profit_per_order), 2) AS total_profit,
ROUND(SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN o.order_profit_per_order ELSE 0 END), 2) AS profit_at_risk
FROM orders_clean o JOIN shipping_details sd ON o.order_item_id = sd.order_item_id
JOIN sales_details sl ON o.order_item_id = sl.order_item_id
JOIN product_details pd ON o.order_item_cardprod_id = pd.product_card_id
JOIN category_details cd ON pd.product_category_id = cd.category_id
GROUP BY o.order_region, cd.category_name, sl.market
HAVING COUNT(*) >= 50),
scored AS (SELECT *,NTILE(3) OVER (ORDER BY late_rate_pct ASC) AS late_score,
NTILE(3) OVER (ORDER BY revenue_at_risk ASC) AS revenue_risk_score,
NTILE(3) OVER (ORDER BY total_orders DESC) AS volume_score FROM combo)
SELECT order_region, category_name, market,total_orders, late_rate_pct,revenue_at_risk, profit_at_risk, total_profit,
late_score + revenue_risk_score + volume_score AS priority_score FROM scored
ORDER BY priority_score DESC, revenue_at_risk DESC LIMIT 10;