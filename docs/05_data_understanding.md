# Step 5: Data Understanding
## The Metadata Profile & Structural Integrity Audit

### 5.1 Strategic Overview: "Trust but Verify"
In the previous step (**Data Collection**), we successfully ingested raw CSV files into our local SQL Server instance (`BUDI\setyo`) using a defensive `VARCHAR` staging strategy. However, ingestion success does not equal data quality. 

As the lead analyst, I must now perform a rigorous **Metadata Profile Audit**. My objective in this phase is not to transform the data, but to *diagnose* it. I need to answer three critical questions before proceeding to Data Preparation:
1.  **Volume Integrity:** Did the `BULK INSERT` commands capture every row, or were records truncated due to formatting errors?
2.  **Null Blindspots:** Are there critical missing values in key segmentation columns (like `origin` or `order_status`) that could skew our B2B yield or B2C retention calculations?
3.  **Format Readiness:** Do the date strings stored in our `VARCHAR` columns follow a standard ISO format (`YYYY-MM-DD`), ensuring they can be safely cast to `DATETIME2` in the next step without crashing the pipeline?

This step demonstrates to hiring managers that I do not blindly trust source data; I validate it programmatically using T-SQL system views and diagnostic queries.

### 5.2 Diagnostic Methodology: The Four-Query Audit Suite
To execute this understanding phase, I created and executed a dedicated script: `sql/01_data_understanding.sql`. This script runs four distinct diagnostic checks against the `marketplace_analytics` database.

#### A. Schema Snapshot (System View Inspection)
I queried `sys.tables`, `sys.columns`, and `sys.types` to verify that my staging tables were created with the expected flexible data types.
*   **Objective:** Confirm that `order_item_id` is `VARCHAR(50)` (as per my adjustment) and that all date fields are currently `VARCHAR(50)` or `VARCHAR(100)`.
*   **Why:** This confirms the "landing pad" is ready for type-safe transformation later.

#### B. Volume Verification (Row Count Validation)
I executed `COUNT(*)` aggregations across all five core tables to compare against the known source file volumes.
*   **Expected Baselines:**
    *   `leads_qualified`: ~8,000 rows
    *   `leads_closed`: ~842 rows
    *   `orders`: ~99,441 rows
    *   `customers`: ~99,441 rows
    *   `order_items`: ~112,650 rows

#### C. Null Value Diagnosis
I specifically targeted high-risk categorical columns to check for missing data.
*   **Target Columns:** `leads_qualified.origin` (Critical for B2B Channel Analysis) and `orders.order_status` (Critical for B2C Retention Filtering).
*   **Logic:** `COUNT(*) - COUNT(column_name)` reveals the exact number of NULL records.

#### D. String Format Sampling
I used `SELECT TOP 5` to inspect the raw string representation of date fields.
*   **Target Fields:** `first_contact_date`, `won_date`, and `order_purchase_timestamp`.
*   **Objective:** Visually confirm that dates look like `'2017-11-14'` or `'2018-04-24 03:00:00'` rather than malformed strings like `'14/11/2017'` or `'N/A'`, which would break `TRY_CAST` operations.

### 5.3 Audit Results & Interpretation
Upon executing the diagnostic suite in VS Code, the following results were returned, confirming the health of our staging environment.

#### Result Set 1: Schema Confirmation
The system view query confirmed that all 38 columns across the 5 tables are currently stored as `VARCHAR`. Crucially, `order_item_id` in `dbo.order_items` is correctly set to `VARCHAR(50)`, preserving our defensive ingestion strategy.

#### Result Set 2: Volume Integrity Check
| Table Name | Total Rows | Status |
| :--- | :--- | :--- |
| `leads_qualified` | 8,000 | ✅ Match |
| `leads_closed` | 842 | ✅ Match |
| `order_items` | 112,650 | ✅ Match |
| `customers` | 99,441 | ✅ Match |
| `orders` | 99,441 | ✅ Match |

**Interpretation:** The `BULK INSERT` pipeline was 100% successful. No rows were dropped or truncated during ingestion.

#### Result Set 3: Null Value Audit
| Table | Column | Total Null Records |
| :--- | :--- | :--- |
| `leads_qualified` | `origin` | 0 |
| `orders` | `order_status` | 0 |

**Interpretation:** We have zero missing values in our primary segmentation keys. This simplifies our subsequent SQL logic, as we do not need to write complex `ISNULL()` or `COALESCE()` fallbacks for these specific fields. We can proceed with direct `GROUP BY` operations.

#### Result Set 4: Date Format Sampling
*   `leads_qualified.first_contact_date`: Samples showed `'2017-11-14'`, `'2018-04-05'`.
*   `leads_closed.won_date`: Samples showed `'2018-04-24 03:00:00'`, `'2018-09-14 14:43:50'`.
*   `orders.order_purchase_timestamp`: Samples showed `'2017-09-13 08:59:02'`, `'2018-08-08 10:00:35'`.

**Interpretation:** All temporal data follows standard ISO 8601 formatting. This confirms that we can safely use `TRY_CAST(... AS DATE)` and `TRY_CAST(... AS DATETIME2)` in the next step without encountering conversion errors.

### 5.4 Key Insights & Next Steps
Based on this understanding phase, I have established the following technical directives for the **Data Preparation** step:

1.  **No Data Cleaning Required for Nulls:** Since `origin` and `order_status` are complete, we can focus purely on type conversion.
2.  **Safe Casting Strategy:** The consistent date formats allow us to use efficient T-SQL casting functions. We will not need complex string manipulation (like `SUBSTRING` or `REPLACE` for date reordering), though we will still use `REPLACE` to strip any potential double-quote artifacts (`"`) from numeric fields like `price`.
3.  **Schema Evolution Plan:** We are ready to move from the `dbo` (staging) schema to a new `analytics` (production) schema, where we will materialize these `VARCHAR` fields into their native `DATE`, `DATETIME2`, and `DECIMAL` types.
