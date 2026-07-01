# Step 7: Modeling
## Advanced T-SQL Logic for B2B Yield & B2C Cohort Retention

### 7.1 Strategic Overview: "Logic in the Database"
In some analytics projects, complex calculations are often pushed to the visualization layer (Power BI or Python), causing dashboard lag and making the logic hard to audit. 

For **The B2B2C Marketplace Growth & Retention Framework**, I adopted a **Database-First Modeling Strategy**. I engineered two distinct, high-performance T-SQL scripts that execute all heavy lifting—including window functions, temporal truncations, and multi-table aggregations—directly within the `marketplace_analytics` database on my local instance (`BUDI\setyo`). 

This approach ensures that:
1.  **Performance:** The downstream visualization tools only receive lightweight, pre-aggregated result sets.
2.  **Reproducibility:** The business logic is version-controlled in SQL scripts, not hidden inside proprietary .pbix files or Jupyter notebooks.
3.  **Accuracy:** All financial and temporal calculations are performed using native SQL Server data types (`DECIMAL`, `DATETIME2`), eliminating floating-point errors.

### 7.2 Phase 1 Model: B2B Merchant Acquisition Yield & Funnel Velocity
**Script:** `sql/03_b2b_growth_yield.sql`

To solve the **B2B Capital Allocation Risk**, I needed to connect marketing leads to downstream revenue. The core challenge was that `leads_qualified` and `leads_closed` do not contain revenue data; that lives in `order_items`.

#### A. The Aggregation Strategy (CTE)
I used a Common Table Expression (CTE) named `seller_gmv_aggregate` to pre-calculate the total Gross Merchandise Value (GMV) for every seller. This prevents row duplication when joining the many-to-one relationship between orders and sellers.

```sql
WITH seller_gmv_aggregate AS (
    SELECT
        seller_id,
        SUM(item_price) AS total_seller_gmv
    FROM analytics.fact_orders
    GROUP BY seller_id
)
```

#### B. The Diagnostic Metrics
I joined this aggregate back to the `dim_sellers` table to compute four critical KPIs per marketing channel:
* **Conversion Rate (%):** Measures funnel efficiency.
  * *Logic:* `ROUND(100.0 * COUNT(DISTINCT seller_id) / COUNT(DISTINCT mql_id), 2)`
* **Average Days to Close:** Measures sales velocity.
  * *Logic:* `ROUND(AVG(CAST(DATEDIFF(day, lead_generation_date, closed_won_timestamp) AS FLOAT)), 1)`
  * *Note:* I cast the `DATEDIFF` result to `FLOAT` before averaging to ensure decimal precision in the final output.
* **Total GMV Generated:** The absolute financial impact of the channel.
  * *Logic:* `ROUND(SUM(gmv.total_seller_gmv), 2)`
* **Revenue Yield per MQL:** The North Star Metric for capital efficiency.
  * *Logic:* `ROUND(SUM(gmv.total_seller_gmv) / COUNT(DISTINCT mql_id), 2)`

#### C. Key Insight from the Model
The model revealed that the unknown channel, despite its ambiguous name, generated the highest yield ($194.49 per lead) with a 16.29% conversion rate, significantly outperforming paid social channels. This finding directly informs the strategic recommendation to audit and scale this specific traffic source.

### 7.3 Phase 2 Model: B2C Customer Cohort Retention Matrix
**Script:** `sql/04_b2c_user_cohorts.sql`

To solve the **B2C Leaky Bucket Problem**, I needed to track individual customers over time. The core challenge was that `customer_id` changes with every transaction. I resolved this by mapping all transactions to the static `customer_unique_id` found in `dim_customers`.

#### A. Temporal Standardization (`DATETRUNC`)
To compare customers across different months, I standardized all purchase timestamps to the first day of their respective month.
* **Function:** `DATETRUNC(month, fo.order_purchase_timestamp)`
* **Result:** A `purchase_month` column that allows for clean monthly grouping.

#### B. Cohort Definition (Window Function)
I used a window function to identify the "first purchase month" for every unique customer. This permanently tags each user with their arrival cohort.
* **Function:** `MIN(purchase_month) OVER(PARTITION BY customer_unique_id)`
* **Result:** A `cohort_month` column that remains constant for a user, regardless of when they make subsequent purchases.

#### C. Retention Interval Calculation
I calculated the "Month Index" to determine how many months had passed since a customer's first purchase.
* **Logic:** `DATEDIFF(month, cohort_month, purchase_month)`
* **Output:** An integer (0, 1, 2, 3...) representing the retention period.

#### D. The Pivot Logic (Conditional Aggregation)
Instead of using a rigid `PIVOT` operator, I implemented conditional aggregation to build the retention matrix columns dynamically:
* **Cohort Size (Month 0):** `COUNT(CASE WHEN month_index = 0 THEN customer_unique_id END)`
* **Month 1 Retention %:** `ROUND(100.0 * COUNT(CASE WHEN month_index = 1 THEN customer_unique_id END) / COUNT(CASE WHEN month_index = 0 THEN customer_unique_id END), 2)`

#### E. Key Insight from the Model
The model exposed a critical retention crisis: Month 1 retention rates consistently hovered below 1% across all 2017 cohorts. For example, the January 2017 cohort of 717 users saw only 0.28% return in February. This quantitative proof validates the "Leaky Bucket" hypothesis and justifies a pivot toward retention-focused product initiatives.

### 7.4 Technical Constraints & Optimization
* **Filtering:** Both models strictly filter for `order_status = 'delivered'` in the B2C phase to ensure we are measuring satisfied customers, and `marketing_channel IS NOT NULL` in the B2B phase to ensure accurate attribution.
* **Data Types:** All financial metrics are cast to `DECIMAL(18, 2)` to prevent rounding errors in yield calculations. All temporal metrics use `DATETIME2` for maximum precision.
* **Idempotency:** Both scripts are designed to be run repeatedly without error, producing consistent results as long as the underlying analytics schema remains unchanged.
