USE marketplace_analytics;
GO

WITH customer_purchases AS (
    SELECT
        dc.customer_unique_id,
        fo.order_purchase_timestamp,
        -- Standardizing order dates to the first of the month
        DATETRUNC(month, fo.order_purchase_timestamp) AS purchase_month
    FROM analytics.fact_orders AS fo 
    JOIN analytics.dim_customers AS dc ON fo.customer_id = dc.customer_id
    WHERE fo.order_status = 'delivered'
),
cohort_stamps AS (
    SELECT
        customer_unique_id,
        purchase_month,
        -- Finding each customer's first purchase date
        MIN(purchase_month) OVER(PARTITION BY customer_unique_id) AS cohort_month
    FROM customer_purchases
),
cohort_intervals AS (
    SELECT DISTINCT 
        customer_unique_id,
        cohort_month,
        -- Calculating monthly intervals
        DATEDIFF(month, cohort_month, purchase_month) AS month_index
    FROM cohort_stamps
)
SELECT 
    cohort_month,
    COUNT(CASE WHEN month_index = 0 THEN customer_unique_id END) AS cohort_size,
    -- Compiling matrix columns based on the cohort month index
    ROUND(100.0 * COUNT(CASE WHEN month_index = 1 THEN customer_unique_id END) / COUNT(CASE WHEN month_index = 0 THEN customer_unique_id END), 2) AS month_1_retention_pct,
    ROUND(100.0 * COUNT(CASE WHEN month_index = 2 THEN customer_unique_id END) / COUNT(CASE WHEN month_index = 0 THEN customer_unique_id END), 2) AS month_2_retention_pct,
    ROUND(100.0 * COUNT(CASE WHEN month_index = 3 THEN customer_unique_id END) / COUNT(CASE WHEN month_index = 0 THEN customer_unique_id END), 2) AS month_3_retention_pct
FROM cohort_intervals
GROUP BY cohort_month
ORDER BY cohort_month ASC;
GO