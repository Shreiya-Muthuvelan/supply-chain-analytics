# Supply Chain Analytics — SQL Case Study

End-to-end SQL analytics project on the DataCo Smart Supply Chain dataset, covering schema design, data cleaning, validation, and multi-dimensional business analysis across 180,000+ order-item records.

---

## Project Structure

```
supply-chain-sql/
│
├── data/
│   └── supply_chain_data.csv          # Raw source dataset (Kaggle)
│
├── sql/
│   ├── 01_schema.sql                  # Table design, indexes, PK/FK constraints
│   ├── 02_data_cleaning.sql           # Type casting, null handling, derived columns, analysis views
│   ├── 03_data_validation.sql         # Row counts, referential integrity, range checks
│   ├── 04_exploratory_analysis.sql    # Revenue, profit, category and product breakdown
│   ├── 05_operational_analysis.sql    # Late delivery rates, shipping duration, regional performance
│   ├── 06_customer_analysis.sql       # RFM segmentation, CLV, discount sensitivity, retention
│   ├── 07_geographical_analysis.sql   # Revenue and margin by market, region and country
│   ├── 08_time_analysis.sql           # Seasonality, YoY trends, rolling metrics
│   └── 09_advanced_analysis.sql       # Risk scoring, cohort retention, profit leakage, recommendations
│
└── report/
    └── insights_report.md             # Full findings, implications and recommendations
```

---

## Dataset

**Source:** [DataCo Smart Supply Chain for Big Data Analysis — Kaggle](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis)  
**Size:** ~180,000 rows, order-item grain  
**Domain:** Global e-commerce supply chain — orders, customers, products, shipping, geography  

The raw flat file was normalized into six relational tables (`orders`, `customers`, `product_details`, `category_details`, `shipping_details`, `sales_details`) with explicit primary keys, foreign key constraints, and indexed join columns.

> **Note:** The raw dataset is not included in this repository due to file size.
> Download directly from the Kaggle link above and place as `data/supply_chain_data.csv` before running.

---

## Key Findings

**1. Late delivery is systemic, not targeted.**  
~55% of all shipments are delivered late — a rate that is virtually identical across all shipping modes, markets, regions, order quantities, days of the week, and months of the year. This uniformity rules out any mode- or region-specific cause and points to a scheduling methodology problem: delivery windows are set too optimistically at order creation across the board.

**2. First Class shipping is structurally misconfigured.**  
First Class shows a near-100% late delivery rate in every region and every month without exception — not due to carrier failure, but because its contracted scheduled window is tighter than its actual average shipping duration of ~2 days. Correcting the scheduled window would reclassify the majority of First Class "late" shipments to "on time" at zero operational cost.

**3. The most popular discount tier is the least profitable.**  
94% of all orders carry a discount. The High (11–20%) discount bucket contains the most orders (30,856) but produces the lowest average profit ($20.46) and the highest loss rate. No-discount orders outperform on both metrics. The discount strategy is structural rather than promotional and is consistently suppressing margin that would otherwise be recoverable.

---

## SQL Techniques Used

- Schema normalization and referential integrity enforcement
- Window functions: `RANK()`, `NTILE()`, `LAG()`, `SUM() OVER`, rolling averages with `ROWS BETWEEN`
- Multi-CTE query design (3–4 chained CTEs for complex transformations)
- Cohort retention analysis using `DATE_TRUNC` and `AGE()`
- Composite risk scoring combining late rate, delay magnitude and volume via `NTILE`
- Profit leakage identification using dual `NTILE` quartile ranking
- Conditional aggregation with `SUM(CASE WHEN ...)` for rate calculations
- `DISTINCT ON` for first-order isolation in customer lifetime analysis

---

## Tools

- **Database:** PostgreSQL
- **Environment:** pgAdmin / psql
- **Dataset format:** CSV loaded via `COPY` into PostgreSQL

---

## How to Run

```sql
-- 1. Load raw data from Kaggle

-- 2. Run files in order
-- 01_schema.sql       → creates and indexes all tables
-- 02_data_cleaning.sql → applies fixes and creates analysis views
-- 03_data_validation.sql → verify data quality before analysis
-- 04 through 09       → run independently in any order after 01-03
```

> Files 04–09 query from `orders_clean` (revenue/profit analysis) or `orders_active` (volume analysis) — both views are created in `02_data_cleaning.sql`.
