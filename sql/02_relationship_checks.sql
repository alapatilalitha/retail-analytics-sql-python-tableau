# 02_relationship_checks.sql

/*INNER JOIN Example
Revenue by customer*/

SELECT 
    c.customer_unique_id,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY total_revenue DESC;       

/* LEFT JOIN Example
Orders without payments (data quality check)*/

# validate referential integrity.

SELECT o.order_id
FROM orders o
LEFT JOIN payments p 
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL;

/* FULL JOIN (Simulated in MySQL)

MySQL doesn’t support FULL JOIN directly.
So we simulate using UNION.*/

# I understand SQL engine limitations.

SELECT o.order_id, p.order_id
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id

UNION

SELECT o.order_id, p.order_id
FROM orders o
RIGHT JOIN payments p ON o.order_id = p.order_id;

/* Join Explosion Handling
Check if joining order_items inflates rows:*/

# One-to-many relationships increase row count — always aggregate at correct grain.

SELECT 
    COUNT(*) AS joined_rows,
    COUNT(DISTINCT o.order_id) AS distinct_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id;
