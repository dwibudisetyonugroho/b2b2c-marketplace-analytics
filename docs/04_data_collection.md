# Step 4: Data Collection
## Automated Ingestion Pipeline & Relational Storage Architecture

### 4.1 Strategic Overview: "Code-First" Data Engineering
In junior-level portfolios, data collection is often performed manually via GUI wizards (e.g., right-clicking in SSMS and selecting "Import Flat File"). While functional, this approach lacks reproducibility and auditability.

For **The B2B2C Marketplace Growth & Retention Framework**, I adopted a **Code-First Ingestion Strategy**. I engineered a single, idempotent T-SQL script (`sql/00_data_collection.sql`) that:
1.  Initializes the isolated database container (`marketplace_analytics`).
2.  Constructs flexible staging tables with `VARCHAR` data types to prevent ingestion errors from malformed dates or currency strings.
3.  Executes programmatic `BULK INSERT` commands to stream raw CSV data directly from my local file system into the SQL Server instance (`BUDI\setyo`).

This approach demonstrates to hiring managers that I understand **ETL (Extract, Transform, Load) principles** and prioritize automation over manual intervention.

### 4.2 Database Initialization & Schema Design
Before ingesting data, I established a clean storage environment. I chose to store all incoming data in `VARCHAR` formats initially. This is a defensive engineering tactic: it ensures that if a date string in the CSV is slightly malformed (e.g., extra spaces or non-standard separators), the entire ingestion process does not crash. We will handle strict type casting in the subsequent *Data Preparation* phase.

#### A. The Staging Table Blueprint
I designed five core staging tables to mirror the relational structure of the Olist dataset:

| Table Name | Purpose | Key Columns |
| :--- | :--- | :--- |
| `dbo.leads_qualified` | Top-of-Funnel Marketing Data | `mql_id`, `first_contact_date`, `origin` |
| `dbo.leads_closed` | Mid-Funnel Sales Conversion | `mql_id`, `seller_id`, `won_date` |
| `dbo.order_items` | Transactional Line Items | `order_id`, `seller_id`, `price`, `freight_value` |
| `dbo.customers` | Master Customer Identity | `customer_id`, `customer_unique_id` |
| `dbo.orders` | Purchase Lifecycle Events | `order_id`, `customer_id`, `order_status`, `order_purchase_timestamp` |

*Note: For `dbo.order_items`, I explicitly defined `order_item_id` as `VARCHAR(50)` instead of `INT` to accommodate any potential non-numeric formatting in the raw source, ensuring maximum ingestion stability.*

### 4.3 The Automated Ingestion Script (`00_data_collection.sql`)
The core of this step is the execution of the following T-SQL logic. This script is designed to be **idempotent**, meaning it can be run multiple times without creating duplicate tables or errors.

#### Key Technical Components:
1.  **Database Creation Check:**
    ```sql
    IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'marketplace_analytics')
    BEGIN
        CREATE DATABASE marketplace_analytics;
    END;
    ```
2.  **Table Dropping for Clean Runs:**
    Using `DROP TABLE IF EXISTS` ensures that every time I refine my ingestion logic, I start with a fresh schema.
3.  **Bulk Insert Configuration:**
    I utilized the `BULK INSERT` command with specific parameters to handle the CSV format correctly:
    *   `FIRSTROW = 2`: Skips the header row in the CSV files.
    *   `FIELDTERMINATOR = ','`: Defines the comma as the column separator.
    *   `ROWTERMINATOR = '\n'`: Defines the new line character as the row separator.
    *   `TABLOCK`: Optimizes performance by locking the table during the bulk load.

#### Example Ingestion Block (Leads Qualified):
```sql
BULK INSERT dbo.leads_qualified
FROM 'C:\b2b2c-marketplace-analytics\data\raw\leads_qualified.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
```

### 4.4 Execution Environment & Path Management
To execute this collection step successfully, I adhered to the following environmental constraints:
* **Server Instance:** `BUDI\setyo` (Local SQL Server Express/Standard).
* **File Path Alignment:** The `FROM` path in the `BULK INSERT` command must match the absolute physical path of the `data/raw/` directory on my local machine.
* **Action Taken:** I verified that all 11 raw CSV files were present in `C:\b2b2c-marketplace-analytics\data\raw\` before execution.
* **Execution Tool:** VS Code with the official `mssql` extension.
* **Command:** Highlighted the entire script and executed it via `Ctrl+Shift+E`.

### 4.5 Verification & Quality Assurance
Upon successful execution of `00_data_collection.sql`, I performed an immediate sanity check to ensure data integrity:

#### A. Row Count Validation
I ran simple `COUNT(*)` queries against each staging table to verify that the row counts matched the expected volume from the raw files:
* **`leads_qualified`:** ~8,000 rows
* **`leads_closed`:** ~842 rows
* **`orders`:** ~99,441 rows
* **`customers`:** ~99,441 rows
* **`order_items`:** ~112,650 rows

#### B. Schema Inspection
I queried `sys.columns` to confirm that all columns were created as `VARCHAR` types as intended, ensuring the environment is perfectly staged for the next phase of type-safe transformation.

### 4.6 Constraints & Future-Proofing
* **Local Dependency:** This collection step relies on the local file system path. If this project were moved to a cloud environment (e.g., Azure SQL Database), the `BULK INSERT` operations would be replaced with `COPY INTO` syntax or abstracted out into an Azure Data Factory pipeline.
* **Security Framework:** The script currently leverages Windows Authentication (`Trusted_Connection=yes`). In a production enterprise environment, I would implement SQL Authentication with encrypted credentials pulled securely from environment variables or a key vault.
