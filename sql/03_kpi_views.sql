# 03_kpi_views.sql
# We now create reusable views.
# AOV View
# Now you have analytics-ready tables.
CREATE OR REPLACE VIEW kpi_aov AS
SELECT 
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

# Create Revenue Summary Table

CREATE OR REPLACE VIEW kpi_monthly_revenue AS
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;

SELECT * FROM kpi_monthly_revenue;

# Build Customer-Level Revenue Table
CREATE OR REPLACE VIEW kpi_customer_revenue AS
SELECT 
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_spent,
    ROUND(AVG(oi.price), 2) AS avg_item_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id;

# Test
SELECT * 
FROM kpi_customer_revenue
ORDER BY total_spent DESC
LIMIT 10;

# built reusable KPI views for business analysis.

#  Final KPI Summary View
CREATE OR REPLACE VIEW kpi_executive_summary AS
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price),2) AS total_revenue,
    ROUND(SUM(oi.price)/COUNT(DISTINCT o.order_id),2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';
