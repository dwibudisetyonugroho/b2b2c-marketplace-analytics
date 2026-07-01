# The B2B2C Marketplace Growth & Retention Framework

## 1. Executive Summary & Rationale
I deliberately engineered this dual-phase relational analytics pipeline to dismantle standard operational silos between **B2B Merchant Acquisition** and **B2C Product Loyalty** operations. Instead of calculating metrics in isolated corporate vacuums, my architecture traces value from the exact second a business lead is first touched down to the multi-month retention trends of the consumers buying their goods.

### Core Architecture Rationale:
*   **Bypassing Front-End Bottlenecks:** Rather than forcing downstream BI layers (Power BI) to loop over millions of raw transaction records, I explicitly computed window functions (`MIN() OVER()`) and time-series boundaries (`DATETRUNC()`, `DATEDIFF()`) directly within the database tier using T-SQL.
*   **Capital Protection Strategy:** Calculating conversion rates alone is a dangerous proxy for performance. My pipeline surfaces the `revenue_yield_per_mql`, ensuring the organization targets high-GMV merchants rather than rapid-closing but low-yield seller categories.

---

## 2. Advanced Relational T-SQL Pipeline Structure
My code execution repository is structured across four clean, idempotent phases to allow quick deployment and complete code scannability:

*   **`sql/00_data_collection.sql`:** Initializes the isolated `marketplace_analytics` relational database layer on my local instance (`BUDI\setyo`) and utilizes automated programmatic `BULK INSERT` statements to stream raw CSV files.
*   **`sql/01_data_understanding.sql`:** Performs metadata audits, row count validations, and null-checks to ensure data integrity before transformation.
*   **`sql/02_data_preparation.sql`:** Replaces structural text anomalies (such as double quotes) and materializes clean primary keys under a secure, decoupled production schema named `analytics`.
*   **`sql/03_b2b_growth_yield.sql`:** Aggregates Gross Merchandise Value (GMV) and processes conversion velocity days across marketing campaign buckets.
*   **`sql/04_b2c_user_cohorts.sql`:** Executes entity resolution across changing transaction IDs, pinning users to their arrival vintage to construct an executive cohort grid.

---

## 3. High-Impact Strategic Data Insights

### Phase 1: B2B Channel Capital Efficiencies
My T-SQL extraction script uncovered a critical operational anomaly across primary marketing acquisition avenues:
*   **The Search Drivers:** `organic_search` ($207k GMV) and `paid_search` ($155k GMV) serve as stable baseline revenue generators with ~12% conversion rates.
*   **The High-Yield Anomaly:** The `unknown` category surfaces as the absolute highest capital performer, yielding **$194.49 revenue per MQL** with a **16.29% conversion rate**. This suggests a highly efficient, untracked traffic source that warrants immediate engineering audit.
*   **The Capital Drain:** `social` traffic attracts high volume but suffers from a dismal **5.56% conversion rate** and a slow **61-day sales cycle**, indicating poor capital efficiency.

### Phase 2: B2C Platform Loyalty Audit
While top-of-funnel conversion mechanics are performant, the cohort retention engine reveals an urgent systemic platform danger:
*   **The Leaky Bucket Reality:** Month 1 customer retention drops precipitously below **1%** across nearly every historical vintage (e.g., Nov 2017 cohort retained only **0.57%** in Month 1).
*   **Strategic Playbook:** This mathematically proves the business model is operating inside a "leaky bucket" lifecycle. Product leadership must pivot from expensive top-of-funnel acquisition toward bottom-of-funnel lifecycle nurture programs (loyalty rewards, email re-engagement) to plug the retention leak.

---

## 4. Unified Executive Dashboard Layout
To bridge database tables to executive decision-making, I designed a **Single-Page Command Center** in Power BI. This layout allows leadership to instantly correlate acquisition spend (Left Side) with customer loyalty health (Right Side).

### Dashboard Blueprint:
1.  **Header Title Block (Top-Left):** Establishes the strategic scope ("The B2B2C Marketplace Growth & Retention Framework").
2.  **KPI Cards (Top Row, Center-to-Right):**
    *   Total Marketing Qualified Leads (MQLs)
    *   Total Converted Sellers
    *   Average Days to Close (Velocity)
    *   Average Month-1 Retention Rate
3.  **B2B Combo Chart (Middle-Left):**
    *   **Visual:** Clustered Column (Total GMV) + Line Overlay (Revenue Yield per MQL).
    *   **Insight:** Visually highlights the disconnect between volume and value, exposing high-yield anomalies like the `unknown` channel.
4.  **B2B Data Table (Bottom-Left):**
    *   **Metrics:** Marketing Channel, Conversion Rate %, Avg Days to Close, Total GMV.
    *   **Purpose:** Allows stakeholders to drill down into exact efficiency metrics for each acquisition source.
5.  **B2C Cohort Retention Matrix (Entire Right Half):**
    *   **Visual:** Matrix Visual with Conditional Formatting (Heatmap).
    *   **Rows:** Cohort Month (YYYY-MM).
    *   **Values:** Cohort Size, Month 1–3 Retention %.
    *   **Purpose:** Dominates the visual space to underscore the critical retention crisis, showing exactly how many customers return after their first purchase.

---

## 5. Project Repository Structure

```plaintext
b2b2c-marketplace-analytics/
│
├── data/
│   └── raw/
│
├── docs/
│   ├── 01_business_understanding.md
│   ├── 02_analytic_approach.md
│   ├── 03_data_requirements.md
│   ├── 04_data_collection.md
│   ├── 05_data_understanding.md
│   ├── 06_data_preparation.md
│   ├── 07_modeling.md
│   ├── 08_evaluation.md
│   └── 09_deployment.md
│
├── notebooks/
│   └── executive_charts.ipynb
│
├── reports/
│   ├── b2b2c_marketplace_growth_&_retention.pbix
│   ├── b2b2c_marketplace_growth_retention_report.pdf
│   └── b2b2c_marketplace_growth_retention_presentation.pptx
│
├── sql/
│   ├── 00_data_collection.sql
│   ├── 01_data_understanding.sql
│   ├── 02_data_preparation.sql
│   ├── 03_b2b_growth_yield.sql
│   └── 04_b2c_user_cohorts.sql
│
├── .gitignore
└── README.md
```

## 6. How to Replicate This Project
*   **Database Setup:** Ensure you have SQL Server installed and running. Update the server name in `sql/00_data_collection.sql` if your instance differs from `BUDI\setyo`.
*   **Data Ingestion:** Place all 11 raw CSV files into the `data/raw/` folder. Update the file paths in `sql/00_data_collection.sql` to match your local directory structure.
*   **Execution Order:** Run the SQL scripts in numerical order (`00` through `04`) in VS Code or SSMS.
*   **Visualization:**
    *   **Power BI:** Open `reports/b2b2c_marketplace_growth_&_retention.pbix`. Refresh the data to pull from your local SQL instance.
    *   **Python:** Open `notebooks/executive_charts.ipynb` in VS Code. Ensure `pyodbc`, `pandas`, and `seaborn` are installed in your environment.

---

## 7. License & Attribution
*   **Dataset:** This project utilizes the Olist Brazilian E-Commerce Dataset, licensed under CC BY-NC 4.0.
*   **Source:** Olist
*   **Authors:** André Sionek, Terenci Claramunt
*   **Coverage:** Jan 2017 – Aug 2018, Brazil
*   **Note:** All customer and seller IDs in this repository and datdaset have been anonymized to protect privacy.
