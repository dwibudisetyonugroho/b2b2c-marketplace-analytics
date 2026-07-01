USE marketplace_analytics;
GO

WITH seller_gmv_aggregate AS (
    SELECT
        seller_id,
        SUM(item_price) AS total_seller_gmv
    FROM analytics.fact_orders
    GROUP BY seller_id
)
SELECT
    ds.marketing_channel,
    COUNT(DISTINCT ds.mql_id) AS total_marketing_qualified_leads,
    COUNT(DISTINCT ds.seller_id) AS total_converted_sellers,
    -- Calculating conversion percentage rates
    ROUND(100.0 * COUNT(DISTINCT ds.seller_id) / COUNT(DISTINCT ds.mql_id), 2) AS conversion_rate_pct,
    -- Calculating average days to close
    ROUND(AVG(CAST(DATEDIFF(day, ds.lead_generation_date, ds.closed_won_timestamp) AS FLOAT)), 1) AS avg_days_to_close,
    -- Aggregating financial channel yield
    ROUND(SUM(gmv.total_seller_gmv), 2) AS total_gmv_generated,
    ROUND(SUM(gmv.total_seller_gmv) / COUNT(DISTINCT ds.mql_id), 2) AS revenue_yield_per_mql
FROM analytics.dim_sellers AS ds
LEFT JOIN seller_gmv_aggregate AS gmv ON ds.seller_id = gmv.seller_id
WHERE ds.marketing_channel IS NOT NULL
GROUP BY ds.marketing_channel
ORDER BY total_gmv_generated DESC;
GO
