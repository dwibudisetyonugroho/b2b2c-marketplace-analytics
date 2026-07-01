-- 1. Building the database
USE master;
GO

IF NOT EXISTS (
    SELECT *
    FROM sys.databases
    WHERE name = 'marketplace_analytics'
)
BEGIN
    CREATE DATABASE marketplace_analytics;
END;
GO

USE marketplace_analytics;
GO

-- 2. Resetting the schema
IF OBJECT_ID('dbo.leads_qualified', 'U')    IS NOT NULL DROP TABLE dbo.leads_qualified;
IF OBJECT_ID('dbo.leads_closed', 'U')       IS NOT NULL DROP TABLE dbo.leads_closed;
IF OBJECT_ID('dbo.order_items', 'U')        IS NOT NULL DROP TABLE dbo.order_items;
IF OBJECT_ID('dbo.customers', 'U')          IS NOT NULL DROP TABLE dbo.customers;
IF OBJECT_ID('dbo.orders', 'U')             IS NOT NULL DROP TABLE dbo.orders;
GO

-- 3. Building the tables
CREATE TABLE dbo.leads_qualified (
    mql_id              VARCHAR(100)    NOT NULL,
    first_contact_date  VARCHAR(50)     NULL,
    landing_page_id     VARCHAR(100)    NULL,
    origin              VARCHAR(100)    NULL,
    CONSTRAINT PK_leads_qualified PRIMARY KEY CLUSTERED (mql_id)
);

CREATE TABLE dbo.leads_closed (
    mql_id                          VARCHAR(100)    NOT NULL,
    seller_id                       VARCHAR(100)    NULL,
    sdr_id                          VARCHAR(100)    NULL,
    sr_id                           VARCHAR(100)    NULL,
    won_date                        VARCHAR(50)     NULL,
    business_segment                VARCHAR(100)    NULL,
    lead_type                       VARCHAR(100)    NULL,
    lead_behaviour_profile          VARCHAR(100)    NULL,
    has_company                     VARCHAR(10)     NULL,
    has_gtin                        VARCHAR(10)     NULL,
    average_stock                   VARCHAR(50)     NULL,
    business_type                   VARCHAR(50)     NULL,
    declared_product_catalog_size   VARCHAR(50)     NULL,
    declared_monthly_revenue        VARCHAR(50)     NULL,
    CONSTRAINT PK_leads_closed PRIMARY KEY CLUSTERED (mql_id)
);

CREATE TABLE dbo.order_items (
    order_id                VARCHAR(100)    NOT NULL,
    order_item_id           VARCHAR(50)     NOT NULL,
    product_id              VARCHAR(100)    NULL,
    seller_id               VARCHAR(100)    NULL,
    shipping_limit_date     VARCHAR(50)     NULL,
    price                   VARCHAR(50)     NULL,
    freight_value           VARCHAR(50)     NULL,
    CONSTRAINT PK_order_items PRIMARY KEY CLUSTERED (order_id, order_item_id)
);

CREATE TABLE dbo.customers (
    customer_id                 VARCHAR(100)    NOT NULL,
    customer_unique_id          VARCHAR(100)    NULL,
    customer_zip_code_prefix    VARCHAR(50)     NULL,
    customer_city               VARCHAR(100)    NULL,
    customer_state              VARCHAR(10)     NULL,
    CONSTRAINT PK_customers PRIMARY KEY CLUSTERED (customer_id)
);

CREATE TABLE dbo.orders (
    order_id                        VARCHAR(100)    NOT NULL,
    customer_id                     VARCHAR(100)    NULL,
    order_status                    VARCHAR(50)     NULL,
    order_purchase_timestamp        VARCHAR(50)     NULL,
    order_approved_at               VARCHAR(50)     NULL,
    order_delivered_carrier_date    VARCHAR(50)     NULL,
    order_delivered_customer_date   VARCHAR(50)     NULL,
    order_estimated_delivery_date   VARCHAR(50)     NULL,
    CONSTRAINT PK_orders PRIMARY KEY CLUSTERED (order_id)
);
GO

-- 4. Data ingestion
BULK INSERT dbo.leads_qualified
FROM 'C:\Users\setyo\Documents\projects\b2b2c-marketplace-analytics\data\raw\leads_qualified.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

BULK INSERT dbo.leads_closed
FROM 'C:\Users\setyo\Documents\projects\b2b2c-marketplace-analytics\data\raw\leads_closed.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

BULK INSERT dbo.order_items
FROM 'C:\Users\setyo\Documents\projects\b2b2c-marketplace-analytics\data\raw\order_items.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

BULK INSERT dbo.customers
FROM 'C:\Users\setyo\Documents\projects\b2b2c-marketplace-analytics\data\raw\customers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

BULK INSERT dbo.orders
FROM 'C:\Users\setyo\Documents\projects\b2b2c-marketplace-analytics\data\raw\orders.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO