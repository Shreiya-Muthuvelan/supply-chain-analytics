
-- Overall distribution of delivery_performance flag 
select delivery_performance ,count(*) from shipping_details group by delivery_performance;

-- Late delivery rate by shipping mode
SELECT shipping_mode,ROUND(AVG(CASE WHEN delivery_status='Late delivery' THEN 1 ELSE 0 END)*100,2)
AS late_delivery_rate FROM shipping_details GROUP BY shipping_mode;

-- Avg actual vs scheduled shipping days per mode and market
SELECT shipping_mode,ROUND(AVG(days_for_shipping_real),2) AS avg_shipping_duration,market FROM shipping_details shd join sales_details sd
on shd.order_item_id=sd.order_item_id GROUP BY shipping_mode,market;

-- Comparing difference between processing gap and actual transit days
SELECT shipping_mode,ROUND(AVG(shipping_date-order_date),2) AS avg_processing_delay,
ROUND(AVG(days_for_shipping_real),2) AS avg_transit_days FROM shipping_details sd JOIN orders o
on sd.order_item_id=o.order_item_id GROUP BY shipping_mode ORDER BY avg_processing_delay DESC;

-- Late delivery rate by product categories
SELECT product_category_id,category_name,ROUND(AVG(CASE WHEN delivery_status='Late delivery' THEN 1 ELSE 0 END)*100,2)
AS late_delivery_rate FROM shipping_details sd JOIN orders o on sd.order_item_id=o.order_item_id 
JOIN product_details pd on o.order_item_cardprod_id=pd.product_card_id JOIN category_details cd 
on pd.product_category_id=cd.category_id GROUP BY product_category_id,category_name ORDER BY late_delivery_rate DESC;

-- Quantity vs Late Delivery Risk
SELECT order_item_quantity,ROUND(AVG(CASE WHEN delivery_status='Late delivery' THEN 1 ELSE 0 END)*100,2)
AS late_delivery_rate FROM shipping_details sd JOIN orders o on sd.order_item_id=o.order_item_id 
GROUP BY order_item_quantity ;

-- Among late orders, measures avg delay and worst case per shipping mode
SELECT shipping_mode,ROUND(AVG(shipping_delay_days), 2) AS avg_delay,
ROUND(AVG(CASE WHEN shipping_delay_days > 0 THEN shipping_delay_days END), 2) AS avg_delay_when_late,
MAX(shipping_delay_days) AS worst_delay FROM shipping_details WHERE delivery_status = 'Late delivery'
GROUP BY shipping_mode ORDER BY avg_delay_when_late DESC;


-- Late delivery rate by market/region
SELECT sl.market,COUNT(*) AS total_orders, ROUND(SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_rate_pct,
ROUND(AVG(sd.shipping_delay_days), 2) AS avg_delay_days FROM shipping_details sd
JOIN sales_details sl ON sd.order_item_id = sl.order_item_id GROUP BY sl.market ORDER BY late_rate_pct DESC;

-- Checks whether high-late-rate categories (Golf Bags, Lacrosse, Cameras) belong to a specific shipping mode
SELECT cd.category_name, sd.shipping_mode, COUNT(*) AS total_orders,
ROUND(SUM(CASE WHEN sd.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_rate_pct
FROM shipping_details sd JOIN orders o ON sd.order_item_id = o.order_item_id
JOIN product_details pd ON o.order_item_cardprod_id = pd.product_card_id
JOIN category_details cd ON pd.product_category_id = cd.category_id
WHERE cd.category_name IN ('Golf Bags & Carts','Lacrosse','Cameras')
GROUP BY cd.category_name, sd.shipping_mode ORDER BY cd.category_name, late_rate_pct DESC;
