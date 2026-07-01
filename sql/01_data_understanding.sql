USE marketplace_analytics;
GO

-- 1. Check data type
SELECT
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length AS max_byte_length
FROM sys.tables AS t
JOIN sys.columns AS c ON t.object_id = c.object_id
JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('leads_qualified', 'leads_closed', 'order_items', 'customers', 'orders')
ORDER BY 
    table_name, 
    column_name;

-- 2. Check data volume
SELECT 'dbo.leads_qualified' AS table_name, COUNT(*) AS total_rows  FROM dbo.leads_qualified
UNION ALL
SELECT 'dbo.leads_closed',                  COUNT(*)                FROM dbo.leads_closed
UNION ALL
SELECT 'dbo.order_items',                   COUNT(*)                FROM dbo.order_items
UNION ALL
SELECT 'dbo.customers',                     COUNT(*)                FROM dbo.customers
UNION ALL
SELECT 'dbo.orders',                        COUNT(*)                FROM dbo.orders;

-- 3. Check missing data
SELECT
    'leads_qualified' AS table_name,
    'origin' AS column_name,
    COUNT(*) - COUNT(origin) AS total_null_records
FROM dbo.leads_qualified
UNION ALL
SELECT
    'orders',
    'order_status',
    COUNT(*) - COUNT(order_status)
FROM dbo.orders;

-- 4. Check string date columns
SELECT TOP 5
    'leads_qualified.first_contact_date' AS source_column,
    first_contact_date AS sample_value
FROM dbo.leads_qualified
UNION ALL
SELECT TOP 5
    'leads_closed.won_date',
    won_date
FROM dbo.leads_closed
UNION ALL
SELECT TOP 5
    'orders.order_purchase_timestamp',
    order_purchase_timestamp
FROM dbo.orders;
GO
