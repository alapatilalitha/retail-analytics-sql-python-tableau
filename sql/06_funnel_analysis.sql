# 06_funnel_analysis.sql

/*
For Olist, funnel could be:

Orders placed
→ Approved
→ Delivered */

CREATE OR REPLACE VIEW kpi_funnel_summary AS
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_approved_at IS NOT NULL THEN 1 ELSE 0 END) AS approved_orders,
    SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) AS delivered_orders,
    ROUND(
        SUM(CASE WHEN order_approved_at IS NOT NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*),0) * 100,
    2) AS approval_rate_pct,
    ROUND(
        SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN order_approved_at IS NOT NULL THEN 1 ELSE 0 END),0) * 100,
    2) AS delivery_rate_pct,
    ROUND(
        SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*),0) * 100,
    2) AS overall_conversion_pct
FROM orders;

SELECT * FROM kpi_funnel_summary;

# Funnel by month
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) AS delivered_orders,
    ROUND(
        SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END)
    / NULLIF(COUNT(*),0) * 100

    ,2) AS conversion_pct
FROM orders
GROUP BY month
ORDER BY month;

SELECT * 
FROM customer_rfm_segments 
LIMIT 10;


# Build an Analytics Mart View

CREATE OR REPLACE VIEW customer_analytics_mart AS
SELECT
    r.customer_unique_id,
    r.Recency,
    r.Frequency,
    r.Monetary,
    r.Segment,
    k.total_orders,
    k.total_spent
FROM customer_rfm_segments r
LEFT JOIN kpi_customer_revenue k
ON r.customer_unique_id = k.customer_unique_id;

# Testing the view
SELECT * 
FROM customer_analytics_mart
LIMIT 10;


SELECT * FROM customer_analytics_mart;

