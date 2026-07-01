# Step 2: Analytic Approach
## The Decoupled T-SQL & Python Visualization Strategy

### 2.1 Strategic Overview: "Heavy Backend, Light Frontend"
In enterprise data science, a common failure mode is forcing visualization tools (like Power BI or Tableau) to perform complex row-by-row calculations on millions of records. This leads to sluggish dashboards and poor user experience.

My analytic approach for **The B2B2C Marketplace Growth & Retention Framework** is built on a **Decoupled Architecture**:
1.  **The Heavy Lifting (SQL Server):** All complex temporal logic, window functions, and aggregations are executed directly within the `marketplace_analytics` database on my local instance (`BUDI\setyo`). This ensures type safety and maximum performance.
2.  **The Lightweight Bridge (Python/Power BI):** My visualization layer only receives pre-aggregated, clean result sets. This allows for instant rendering and interactive exploration without computational lag.

This approach demonstrates to hiring managers that I understand **Data Engineering principles**—specifically, pushing computation to the data source rather than pulling raw data to the client.

### 2.2 Phase 1 Analytic Logic: B2B Funnel Velocity & Yield
To solve the **B2B Capital Allocation Risk**, I need to connect three distinct operational stages: Lead Generation → Sales Closure → Post-Sale Revenue.

#### A. The Relational Join Strategy
I will construct a single analytical view by joining:
*   `leads_qualified` (Top of Funnel): Provides the `origin` (marketing channel) and `first_contact_date`.
*   `leads_closed` (Mid Funnel): Provides the `won_date` and links to the `seller_id`.
*   `order_items` (Bottom Funnel): Provides the `price` to calculate Gross Merchandise Value (GMV).

#### B. Key Mathematical Transformations (T-SQL)
1.  **Funnel Velocity Calculation:**
    To measure sales efficiency, I will calculate the time delta between the first marketing touch and the closed deal.
    *   *Function:* `DATEDIFF(day, first_contact_date, won_date)`
    *   *Aggregation:* `AVG()` grouped by `origin`.

2.  **Revenue Yield Per Lead (The North Star Metric):**
    Standard conversion rates are misleading if high-volume channels bring low-value sellers. I will calculate the true financial return on every lead generated.
    *   *Logic:* `SUM(item_price) / COUNT(DISTINCT mql_id)`
    *   *Implementation:* I will use a Common Table Expression (CTE) to pre-aggregate GMV per `seller_id` before joining it back to the lead data to avoid row duplication errors.

3.  **Conversion Rate Efficiency:**
    *   *Logic:* `(COUNT(DISTINCT seller_id) / COUNT(DISTINCT mql_id)) * 100`

### 2.3 Phase 2 Analytic Logic: B2C Cohort Retention Modeling
To solve the **B2C Leaky Bucket Problem**, I must track individual customer behavior over time. The core challenge is that `customer_id` changes with every transaction in the Olist dataset.

#### A. Entity Resolution Strategy
I will resolve customer identity by joining `orders` with `customers` to map every transaction to a static `customer_unique_id`. This allows me to track a single human’s purchasing history across multiple orders.

#### B. Cohort Definition via Window Functions
To build a retention matrix, I need to know when a customer *first* arrived.
*   *Technique:* I will use the `MIN()` window function partitioned by `customer_unique_id`.
*   *SQL Logic:* `MIN(order_purchase_timestamp) OVER (PARTITION BY customer_unique_id)`
*   *Result:* This creates a permanent "Cohort Month" label for every user, regardless of when they make subsequent purchases.

#### C. Temporal Standardization & Indexing
To compare apples-to-apples across different months, I must standardize dates and calculate intervals.
1.  **Date Truncation:**
    I will use `DATETRUNC(month, order_purchase_timestamp)` to snap all dates to the 1st of the month. This groups all January transactions together, regardless of the specific day.
2.  **Retention Interval Calculation:**
    I will calculate the "Month Index" to determine how many months have passed since the cohort start.
    *   *SQL Logic:* `DATEDIFF(month, cohort_month, purchase_month)`
    *   *Output:* An integer (0, 1, 2, 3...) representing the retention period.

#### D. The Retention Matrix Construction
Finally, I will pivot this data to create a classic right-triangular heatmap.
*   *Rows:* Cohort Month (e.g., Jan 2017, Feb 2017).
*   *Columns:* Month Index (0, 1, 2, 3).
*   *Values:* Count of Unique Customers.
*   *Normalization:* I will divide the count of returning users in Month N by the total cohort size in Month 0 to get the **Retention Percentage**.

### 2.4 Visualization & Reporting Strategy
Once the SQL logic is validated, I will use two distinct visualization paths to communicate findings to different stakeholders.

#### A. Executive Dashboard (Power BI)
*   **Purpose:** Interactive, real-time monitoring for business leaders.
*   **Connection Method:** Direct SQL Query Import from `BUDI\setyo`.
*   **Key Visuals:**
    *   *B2B Tab:* Clustered Column Chart (GMV by Channel) with a Line Overlay (Yield per Lead).
    *   *B2C Tab:* Conditional Formatting Matrix (Heatmap) showing retention drop-off rates.

#### B. Portfolio Validation (Python/Jupyter)
*   **Purpose:** Static, publication-ready charts for my GitHub portfolio.
*   **Library Stack:** `pyodbc` (Connection), `pandas` (Data Manipulation), `seaborn` (Visualization).
*   **Key Visuals:**
    *   *Seaborn Heatmap:* To visually prove the "Leaky Bucket" hypothesis with color gradients.
    *   *Bar Plot:* To highlight the anomaly of the "Unknown" high-yield channel.

### 2.5 Technical Constraints & Assumptions
*   **Temporal Scope:** Analysis is restricted to data between **01/01/2017** and **08/31/2018**.
*   **Status Filtering:** For B2C retention, I will strictly filter for `order_status = 'delivered'` to ensure we are measuring satisfied customers, not cancelled orders.
*   **Null Handling:** In the B2B phase, I will exclude records where `marketing_channel` is NULL to ensure accurate channel attribution.
