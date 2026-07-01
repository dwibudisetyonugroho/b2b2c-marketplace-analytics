# Step 9: Deployment
## Interactive Dashboards & Portfolio Visualization Strategy

### 9.1 Strategic Overview: "Accessibility & Impact"
In the previous steps (**Modeling** and **Evaluation**), we successfully engineered two high-value analytical outputs: the **B2B Channel Yield Report** and the **B2C Cohort Retention Matrix**. However, a SQL script or a static table is rarely consumed by business leaders. 

As the lead analyst, my objective in this phase is to **deploy** these insights through two distinct channels:
1.  **Executive Dashboard (Power BI):** A unified, single-page interactive dashboard for internal stakeholders (CMO, Head of Product) to monitor B2B acquisition efficiency and B2C retention health side-by-side.
2.  **Portfolio Validation (Python/Jupyter):** A static, publication-ready visualization suite for my GitHub portfolio, demonstrating technical proficiency in `seaborn` and `pyodbc`.

This dual-deployment strategy ensures that the project delivers immediate business value while simultaneously serving as a robust professional artifact.

### 9.2 Deployment Channel 1: The Executive Power BI Dashboard
**File:** `reports/b2b2c_marketplace_growth_&_retention.pbix`

To ensure maximum performance and interactivity, I connected Power BI directly to my local SQL Server instance (`BUDI\setyo`) using the `marketplace_analytics` database. I did not import raw CSVs; instead, I imported the pre-aggregated views created in the Modeling step.

#### A. Unified Dashboard Architecture
Rather than separating the analysis into multiple tabs, I designed a **Single-Page Executive Command Center**. This layout allows leadership to instantly correlate top-of-funnel acquisition spend (Left Side) with bottom-of-funnel customer loyalty (Right Side).

**Layout Blueprint:**

1.  **Header Title Block (Top-Left):**
    *   *Content:* "The B2B2C Marketplace Growth & Retention Framework"
    *   *Purpose:* Clearly establishes the strategic scope of the report.

2.  **KPI Cards (Top Row, Center-to-Right):**
    *   *Metrics Displayed:* 
        *   Total Marketing Qualified Leads (MQLs)
        *   Total Converted Sellers
        *   Average Days to Close (Velocity)
        *   Average Month-1 Retention Rate
    *   *Purpose:* Provides an immediate "health check" of the marketplace ecosystem at a glance.

3.  **B2B Combo Chart (Middle-Left):**
    *   *Visualization:* Clustered Column and Line Chart.
    *   *Columns:* `total_gmv_generated` (Bar)
    *   *Line:* `revenue_yield_per_mql` (Line)
    *   *Axis:* `marketing_channel`
    *   *Purpose:* Visually highlights the disconnect between volume and value, exposing high-yield anomalies like the `unknown` channel.

4.  **B2B Data Table (Bottom-Left):**
    *   *Columns:* `marketing_channel`, `conversion_rate_pct`, `avg_days_to_close`, `total_gmv_generated`.
    *   *Purpose:* Allows stakeholders to drill down into the exact efficiency metrics for each acquisition source.

5.  **B2C Cohort Retention Matrix (Entire Right Half):**
    *   *Visualization:* Matrix Visual with Conditional Formatting.
    *   *Rows:* `cohort_month` (Formatted as YYYY-MM)
    *   *Values:* `cohort_size`, `month_1_retention_pct`, `month_2_retention_pct`, `month_3_retention_pct`.
    *   *Formatting:* Background color gradient (Light Gray to Blue) to visually emphasize the "Leaky Bucket" drop-off.
    *   *Purpose:* Dominates the visual space to underscore the critical retention crisis, showing exactly how many customers return after their first purchase.

#### B. Technical Implementation Details
*   **Data Source:** DirectQuery/Import from `analytics.b2b_growth_yield` and `analytics.b2c_cohort_retention`.
*   **DAX Measures:** Minimal DAX was required because the heavy aggregation was handled in T-SQL. I used simple `SUM` and `AVERAGE` measures to ensure fast rendering.
*   **Theme:** A professional, dark-mode compatible theme was applied to ensure readability in executive presentations.

### 9.3 Deployment Channel 2: Python Portfolio Visualization
**Script:** `notebooks/executive_charts.ipynb`

For my public portfolio, I utilized Python to create static, high-resolution charts that demonstrate my ability to bridge SQL and Data Science libraries.

#### A. Library Stack
*   **`pyodbc`:** To establish a secure connection to the local SQL Server instance.
*   **`pandas`:** To load the SQL result sets into DataFrames for manipulation.
*   **`seaborn` & `matplotlib`:** To generate publication-quality statistical graphics.

#### B. Key Visualizations Generated
1.  **B2B Yield Comparison:** A `sns.barplot` comparing `revenue_per_mql` across channels, highlighting the `unknown` channel anomaly with a distinct color.
2.  **B2C Retention Heatmap:** A `sns.heatmap` of the cohort matrix, using a `YlGnBu` color palette to clearly show the decay in customer loyalty over time.

#### C. Code Snippet: SQL-to-Python Bridge

```python
import pyodbc
import pandas as pd
import seaborn as sns

# Connection to Local Instance
conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=BUDI\\setyo;'
    'DATABASE=marketplace_analytics;'
    'Trusted_Connection=yes;'
)

# Load Pre-Modeled Data
df_cohorts = pd.read_sql("SELECT * FROM analytics.b2c_cohort_retention", conn)

# Generate Heatmap
pivot_table = df_cohorts.pivot(index='cohort_month', columns='month_index', values='retention_rate')
sns.heatmap(pivot_table, annot=True, fmt=".2f", cmap="YlGnBu")
```

### 9.4 Documentation & Handover
To ensure this project is maintainable and reproducible, I have included the following artifacts in the root directory:
*   `README.md`: A high-level summary of the project, including setup instructions for the local SQL Server environment.
*   `docs/`: The complete nine-step methodology documentation we have built together.
*   `sql/`: All T-SQL scripts for Collection, Preparation, and Modeling.
*   `notebooks/`: The Python visualization script notebook.
