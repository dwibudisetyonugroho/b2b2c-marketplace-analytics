USE marketplace_analytics;
GO

-- 1. Create schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'analytics')
BEGIN
    EXEC('CREATE SCHEMA analytics;');
END;
GO

-- 2. Clearing pre_existing tables
DROP TABLE IF EXISTS analytics.dim_customers;
DROP TABLE IF EXISTS analytics.dim_sellers;
DROP TABLE IF EXISTS analytics.fact_orders;

-- 3. Building analytical core tables
-- Table A: Master customer identity layer
SELECT
    CAST(customer_id                        AS VARCHAR(100))    AS customer_id,
    CAST(customer_unique_id                 AS VARCHAR(100))    AS customer_unique_id,
    CAST(REPLACE(customer_city, '"', '')    AS VARCHAR(100))    AS customer_city,
    CAST(REPLACE(customer_state, '"', '')   AS VARCHAR(10))     AS customer_state
INTO analytics.dim_customers
FROM dbo.customers;

ALTER TABLE analytics.dim_customers ALTER COLUMN customer_id VARCHAR(100) NOT NULL;
GO
ALTER TABLE analytics.dim_customers ADD CONSTRAINT PK_dim_customers PRIMARY KEY CLUSTERED (customer_id);
GO

-- Table B: B2B merchant conversion & funnel timeline layer
SELECT
    CAST(lq.mql_id AS VARCHAR(100))                             AS mql_id,
    CAST(lc.seller_id AS VARCHAR(100))                          AS seller_id,
    CAST(REPLACE(lq.origin, '"', '') AS VARCHAR(100))           AS marketing_channel,
    -- Cast text string dates into date and datetime type
    TRY_CAST(REPLACE(lq.first_contact_date, '"', '') AS DATE)   AS lead_generation_date,
    TRY_CAST(REPLACE(lc.won_date, '"', '') AS DATETIME2)        AS closed_won_timestamp
INTO analytics.dim_sellers
FROM dbo.leads_qualified AS lq
LEFT JOIN dbo.leads_closed AS lc ON lq.mql_id = lc.mql_id;

ALTER TABLE analytics.dim_sellers ALTER COLUMN mql_id VARCHAR(100) NOT NULL;
GO
ALTER TABLE analytics.dim_sellers ADD CONSTRAINT PK_dim_sellers PRIMARY KEY CLUSTERED (mql_id);
GO

-- Table C: B2C transactional performance & order items layer
SELECT
    CAST(o.order_id AS VARCHAR(100))                                    AS order_id,
    CAST(o.customer_id AS VARCHAR(100))                                 AS customer_id,
    CAST(oi.seller_id AS VARCHAR(100))                                  AS seller_id,
    CAST(REPLACE(o.order_status, '"', '') AS VARCHAR(50))               AS order_status,
    -- Cast order string timestamps into datetime
    TRY_CAST(REPLACE(o.order_purchase_timestamp, '"', '') AS DATETIME2) AS order_purchase_timestamp,
    -- Strip double quotes from transactional prices and map to decimal currency
    CAST(REPLACE(oi.price, '"', '') AS DECIMAL(18, 2))                  AS item_price,
    CAST(REPLACE(oi.freight_value, '"', '') AS DECIMAL(18, 2))          AS shipping_cost
INTO analytics.fact_orders
FROM dbo.orders AS o
JOIN dbo.order_items AS oi ON o.order_id = oi.order_id;

-- Add auto increment primary key
ALTER TABLE analytics.fact_orders ADD line_item_id INT NOT NULL IDENTITY(1, 1);
GO
ALTER TABLE analytics.fact_orders ADD CONSTRAINT PK_fact_orders PRIMARY KEY CLUSTERED (line_item_id);
GO

-- 4. Verify
SELECT
    OBJECT_SCHEMA_NAME(object_id) + '.' + OBJECT_NAME(object_id) AS analytical_table,
    name AS column_name,
    TYPE_NAME(system_type_id) AS data_type
FROM sys.columns
WHERE object_id IN (
    OBJECT_ID('analytics.dim_customers'),
    OBJECT_ID('analytics.dim_sellers'),
    OBJECT_ID('analytics.fact_orders')
)
ORDER BY analytical_table;
GO