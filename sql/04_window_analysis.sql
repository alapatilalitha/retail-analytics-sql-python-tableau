# 04_window_analysis.sql
# MoM Revenue Growth (LAG)
# I can analyze growth trends over time.
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY month
)

SELECT 
    month,
    revenue,
    prev_revenue,
    ROUND(
        (revenue - prev_revenue)
        / NULLIF(prev_revenue,0) * 100
    ,2) AS mom_growth_pct
FROM (
    SELECT 
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS prev_revenue
    FROM monthly_revenue
) t;

# Customer Lifetime Value (Running Total)
# I track value progression over time.

SELECT 
    c.customer_unique_id,
    o.order_purchase_timestamp,
    SUM(oi.price) OVER (
        PARTITION BY c.customer_unique_id
        ORDER BY o.order_purchase_timestamp
    ) AS cumulative_spend
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered';

#Repeat Purchase Gap (LEAD)

SELECT 
    c.customer_unique_id,
    o.order_purchase_timestamp,
    LEAD(o.order_purchase_timestamp) OVER (
        PARTITION BY c.customer_unique_id
        ORDER BY o.order_purchase_timestamp
    ) AS next_purchase,
    DATEDIFF(
        LEAD(o.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ),
        o.order_purchase_timestamp
    ) AS days_between_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered';
