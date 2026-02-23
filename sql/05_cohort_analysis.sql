# 05_cohort_analysis.sql
# 1. Build Full Cohort Table
WITH first_purchase AS (
    SELECT 
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_purchase_date
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

cohort_data AS (
    SELECT 
        DATE_FORMAT(fp.first_purchase_date, '%Y-%m') AS cohort_month,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        c.customer_unique_id,
        TIMESTAMPDIFF(
            MONTH,
            fp.first_purchase_date,
            o.order_purchase_timestamp
        ) AS month_offset
    FROM first_purchase fp
    JOIN customers c 
        ON fp.customer_unique_id = c.customer_unique_id
    JOIN orders o 
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
)

SELECT 
    cohort_month,
    month_offset,
    COUNT(DISTINCT customer_unique_id) AS active_customers
FROM cohort_data
GROUP BY cohort_month, month_offset
ORDER BY cohort_month, month_offset;

# 2. Calculate Cohort Size
WITH first_purchase AS (
    SELECT 
        c.customer_unique_id,
        MIN(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')) AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT 
    cohort_month,
    COUNT(customer_unique_id) AS cohort_size
FROM first_purchase
GROUP BY cohort_month
ORDER BY cohort_month;

# 3. Final Retention %
CREATE OR REPLACE VIEW kpi_cohort_retention AS
WITH first_purchase AS (
    SELECT 
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_purchase_date
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

cohort_data AS (
    SELECT 
        DATE_FORMAT(fp.first_purchase_date, '%Y-%m') AS cohort_month,
        TIMESTAMPDIFF(
            MONTH,
            fp.first_purchase_date,
            o.order_purchase_timestamp
        ) AS month_offset,
        c.customer_unique_id
    FROM first_purchase fp
    JOIN customers c 
        ON fp.customer_unique_id = c.customer_unique_id
    JOIN orders o 
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),

cohort_size AS (
    SELECT 
        DATE_FORMAT(first_purchase_date, '%Y-%m') AS cohort_month,
        COUNT(customer_unique_id) AS cohort_size
    FROM first_purchase
    GROUP BY cohort_month
)

SELECT 
    cd.cohort_month,
    cd.month_offset,
    COUNT(DISTINCT cd.customer_unique_id) AS active_customers,
    cs.cohort_size,
    ROUND(
    COUNT(DISTINCT cd.customer_unique_id)
    / NULLIF(cs.cohort_size,0) * 100
    ,2
) AS retention_percentage
FROM cohort_data cd
JOIN cohort_size cs
    ON cd.cohort_month = cs.cohort_month
GROUP BY cd.cohort_month, cd.month_offset, cs.cohort_size
ORDER BY cd.cohort_month, cd.month_offset;

SELECT * FROM kpi_cohort_retention;

