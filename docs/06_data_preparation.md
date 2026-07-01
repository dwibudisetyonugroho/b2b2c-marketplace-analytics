# Step 6: Data Preparation
## Type-Safe Schema Materialization & Analytical Layer Construction

### 6.1 Strategic Overview: "Staging vs. Production"
In the previous steps (**Data Collection** and **Data Understanding**), we successfully ingested raw CSVs into flexible `VARCHAR` staging tables within the `dbo` schema. While this ensured zero ingestion errors, `VARCHAR` fields are computationally expensive for mathematical operations and temporal logic.

As the lead analyst, my objective in this phase is to construct a dedicated, type-safe **Analytical Layer**. Instead of altering the raw staging tables (which preserves our audit trail), I will engineer a new schema named `analytics`. This schema will house three core tables (`dim_customers`, `dim_sellers`, `fact_orders`) where:
1.  **Temporal Fields** are cast to native `DATE` and `DATETIME2` types, enabling efficient `DATEDIFF` and `DATETRUNC` operations.
2.  **Financial Fields** are cast to `DECIMAL(18, 2)`, ensuring precise currency arithmetic without floating-point errors.
3.  **String Artifacts** (such as double quotes `"` often found in CSV exports) are programmatically stripped using `REPLACE()` before casting.

This approach demonstrates **Data Modeling maturity**—separating raw ingestion from analytical consumption to optimize query performance and data integrity.

### 6.2 The Transformation Logic: Cleaning & Casting
To ensure robustness, I applied specific cleaning rules during the `SELECT...INTO` transformation process. These rules address common data quality issues found in flat-file exports.

#### A. String Sanitization Strategy
Raw CSV files often wrap text fields in double quotes (e.g., `"SP"` or `"2017-01-01"`). If we attempt to cast these directly, SQL Server will throw conversion errors.
*   **Technique:** `REPLACE(column_name, '"', '')`
*   **Application:** Applied to `customer_city`, `customer_state`, `origin`, `order_status`, `price`, and all date fields.

#### B. Safe Temporal Conversion
Since some date fields in the source might contain minor inconsistencies, I utilized `TRY_CAST()` instead of standard `CAST()`.
*   **Technique:** `TRY_CAST(REPLACE(date_column, '"', '') AS DATETIME2)`
*   **Benefit:** If a specific row contains an invalid date string, `TRY_CAST` returns `NULL` rather than crashing the entire script. This allows us to isolate and inspect bad records later if necessary, though our audit showed clean formats.

#### C. Financial Precision
Currency values must be exact.
*   **Technique:** `CAST(REPLACE(price, '"', '') AS DECIMAL(18, 2))`
*   **Benefit:** Ensures that `SUM(price)` calculations for Gross Merchandise Value (GMV) are accurate to the cent, avoiding the rounding errors associated with `FLOAT` types.

### 6.3 The Analytical Schema Implementation (`sql/02_data_preparation.sql`)
I executed the following T-SQL script to materialize the analytical layer. This script is **idempotent**, meaning it can be run multiple times safely by dropping existing tables before recreation.

#### Key Technical Components:
1.  **Schema Creation:**
    ```sql
    IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'analytics')
    BEGIN
        EXEC('CREATE SCHEMA analytics;');
    END;
    ```
2.  **Dimension Table: `analytics.dim_customers`**
    *   Preserves `customer_id` and `customer_unique_id` as `VARCHAR` (as they are identifiers, not numbers).
    *   Cleans city and state strings.
    *   Establishes `customer_id` as the Primary Key.
3.  **Dimension Table: `analytics.dim_sellers`**
    *   Joins `leads_qualified` and `leads_closed` to create a unified seller profile.
    *   Converts `first_contact_date` to `DATE` and `won_date` to `DATETIME2`.
    *   Renames `origin` to `marketing_channel` for clearer business semantics.
4.  **Fact Table: `analytics.fact_orders`**
    *   Joins `orders` and `order_items` to create a granular transactional record.
    *   Converts `order_purchase_timestamp` to `DATETIME2`.
    *   Converts `price` and `freight_value` to `DECIMAL(18, 2)`.
    *   Adds an identity column `line_item_id` to serve as a unique surrogate key for the fact table.

### 6.4 Verification & Quality Assurance
Upon executing `sql/02_data_preparation.sql`, I ran a final schema inspection query to confirm that all data types were correctly mapped.

#### Result Set: Analytical Schema Profile
| Analytical Table | Column Name | Data Type | Status |
| :--- | :--- | :--- | :--- |
| `analytics.dim_customers` | `customer_id` | `varchar` | ✅ ID Preserved |
| `analytics.dim_customers` | `customer_unique_id` | `varchar` | ✅ ID Preserved |
| `analytics.dim_sellers` | `lead_generation_date` | `date` | ✅ Temporal Ready |
| `analytics.dim_sellers` | `closed_won_timestamp` | `datetime2` | ✅ Temporal Ready |
| `analytics.fact_orders` | `order_purchase_timestamp` | `datetime2` | ✅ Temporal Ready |
| `analytics.fact_orders` | `item_price` | `decimal` | ✅ Financial Ready |
| `analytics.fact_orders` | `shipping_cost` | `decimal` | ✅ Financial Ready |
| `analytics.fact_orders` | `line_item_id` | `int` | ✅ Surrogate Key |

**Interpretation:** The analytical layer is now fully typed. We have successfully transitioned from "raw text storage" to "structured analytical objects." This allows us to proceed to **Data Modeling** with confidence, knowing that our `DATEDIFF` and `SUM` operations will execute efficiently without implicit conversion overhead.

### 6.5 Constraints & Future-Proofing
*   **Read-Only Staging:** The original `dbo` tables remain untouched. This allows us to re-run the preparation step if we discover new cleaning rules, without needing to re-ingest the raw CSVs.
*   **Surrogate Keys:** By adding `line_item_id` to `fact_orders`, we have created a stable key for potential future joins or indexing strategies, even though the natural key is the composite of `order_id` and `order_item_id`.
