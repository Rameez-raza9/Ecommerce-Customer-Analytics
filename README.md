# 🛏️ E-Commerce Customer Analytics & Retention Intelligence

[![Python 3.11](https://img.shields.io/badge/Python-3.11-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Pandas](https://img.shields.io/badge/Pandas-2.1.4-150458?style=for-the-badge&logo=pandas&logoColor=white)](https://pandas.pydata.org/)
[![MySQL 8.0](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Power BI](https://img.shields.io/badge/Power_BI-Desktop-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)](https://powerbi.microsoft.com/)
[![Jupyter](https://img.shields.io/badge/Jupyter-Lab-F37626?style=for-the-badge&logo=jupyter&logoColor=white)](https://jupyter.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

An enterprise-grade customer analytics platform transforming ~100K transactional records into actionable behavioral segmentation, cohort retention matrices, and commercial decision intelligence. Integrates advanced MySQL 8.0 analytical modeling, Python statistical exploratory analysis, and an interactive 5-page Power BI executive dashboard to diagnose customer churn and maximize Customer Lifetime Value (LTV).

> 📊 **99,441** Orders Analyzed &nbsp;|&nbsp; 👥 **96,096** Unique Customers &nbsp;|&nbsp; 🔄 **8** Customer Segments &nbsp;|&nbsp; 📅 **24** Months of Data (2016–2018) &nbsp;|&nbsp; 💰 **R$ 15.8M+** Total GMV &nbsp;|&nbsp; ⭐ **4.08 / 5.0** Avg Review Score

---

## 📑 Table of Contents

1. [Header Section](#%EF%B8%8F-e-commerce-customer-analytics--retention-intelligence)
2. [Table of Contents](#-table-of-contents)
3. [Project Overview](#3-project-overview)
4. [Business Problem](#4-business-problem)
5. [Dataset](#5-dataset)
6. [Technology Stack](#6-technology-stack)
7. [Project Architecture](#7-project-architecture)
8. [Project Structure](#8-project-structure)
9. [Getting Started](#9-getting-started)
   - [Prerequisites](#prerequisites)
   - [Installation](#installation)
   - [Dataset Setup](#dataset-setup)
   - [Running the Notebooks](#running-the-notebooks)
   - [Setting Up MySQL](#setting-up-mysql)
10. [Data Cleaning Methodology](#10-data-cleaning-methodology)
11. [SQL Analysis](#11-sql-analysis)
12. [Python Analysis](#12-python-analysis)
13. [RFM Segmentation Methodology](#13-rfm-segmentation-methodology)
14. [Customer Retention Methodology](#14-customer-retention-methodology)
15. [Power BI Dashboard](#15-power-bi-dashboard)
16. [Key Business Insights](#16-key-business-insights)
17. [Business Recommendations](#17-business-recommendations)
18. [Dashboard Screenshots](#18-dashboard-screenshots)
19. [Resume Project Description](#19-resume-project-description)
20. [License](#20-license)
21. [Contact](#21-contact)

---

## 3. Project Overview

### Business Problem Statement
Modern digital marketplaces often fall into the trap of measuring growth purely through front-end acquisition and gross merchandise volume (GMV), masking catastrophic customer churn. Acquiring new customers in competitive e-commerce environments is 5 to 7 times more expensive than retaining existing ones. For **Olist**, Brazil's largest marketplace connecting independent merchants across 27 federative states to major retail portals, over **96.9% of customers never make a second purchase**. Without systematic customer segmentation, cohort tracking, and operational root-cause diagnostics, commercial leadership cannot allocate marketing capital efficiently or arrest revenue leakage.

### Key Objectives
- **Relational Data Modeling**: Architect and normalize a MySQL 8.0 analytical data warehouse from 9 disparate operational CSV tables spanning 99,441 orders.
- **Behavioral RFM Segmentation**: Formulate a custom Recency-Frequency-Monetary (RFM) engine classifying 96,096 unique customers into 8 actionable strategic tiers.
- **Longitudinal Cohort Retention Modeling**: Construct triangular retention matrices, monthly active customer curves, and net revenue retention (NRR) decay tracking across 24 acquisition cohorts.
- **Logistics & Satisfaction Diagnostics**: Quantify the econometric impact of carrier delivery lead times, regional freight inequalities, and payment friction on customer review ratings (NPS proxy) and repeat purchasing.
- **Executive BI Deployment**: Deliver an interactive 5-page Power BI dashboard with 20+ DAX measures, dynamic what-if parameters, and cross-functional drill-throughs for C-suite and marketing decision-makers.
- **Actionable Strategic Playbooks**: Provide leadership with 8 prioritized, ROI-modeled business interventions to transition Olist from an acquisition-heavy model into a sticky, high-LTV ecosystem.

### What Was Built
- **Production MySQL Data Warehouse**: 6 modular SQL scripts featuring CTEs, window functions (`NTILE`, `DENSE_RANK`), and analytical views (`v_cohort_retention`).
- **Data Engineering & EDA Notebook Suite**: 4 structured Jupyter notebooks executing rigorous data cleansing, outlier remediation, geo-spatial mapping, and retention modeling.
- **5-Page Power BI Executive Suite**: Comprehensive reporting layer covering Commercial Overview, RFM Segmentation, Cohort Retention, Logistics SLAs, and Product Merchandising.

---

## 4. Business Problem

The fundamental challenge confronting Olist is an **unsustainable acquisition treadmill**. Between September 2016 and August 2018, Olist experienced rapid order volume expansion, processing over R$ 15.8 million in gross payments. However, underlying unit economics reveal severe customer retention decay: 93,099 out of 96,096 unique customers purchased exactly once. Operating as a marketplace intermediary means Olist does not own physical inventory or direct last-mile fulfillment fleets. Consequently, platform reputation and customer repeat intent are heavily dependent on independent third-party merchant fulfillment reliability and third-party postal logistics (Correios).

This structural setup introduces critical analytical questions:
1. *Is the high one-time purchase rate inherent to the Brazilian marketplace category mix (e.g., durable home goods and appliances vs. FMCG consumable replenishment)?*
2. *How severely do delivery delays, transit times across continental Brazil, and freight costs erode customer repurchase rates and drive churn?*
3. *Who are the top 5% high-value customers who sustain marketplace profitability, and how can Olist proactively protect them from defecting?*

Solving these questions matters because marketing efficiency, merchant monetization, and enterprise enterprise valuation depend directly on Customer Lifetime Value (LTV) and Net Revenue Retention (NRR). By shifting from vanity volume metrics to granular customer-level unit economics, this project unlocks the levers necessary to turn a low-margin transactional hub into a durable, repeat-purchase ecosystem.

---

## 5. Dataset

This project utilizes the **Brazilian E-Commerce Public Dataset by Olist**, published on Kaggle. It contains anonymized commercial transactional records from 2016 to 2018 covering the entire Brazilian territory.

- **Kaggle Dataset Source**: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Time Period Covered**: September 2016 — August 2018 (Mature continuous operational window: January 2017 – August 2018)
- **Geographic Coverage**: Brazil (27 Federative Units / States, 4,119 unique municipalities)
- **Currency**: Brazilian Real (BRL / R$)

### Relational Tables Overview

| Table | Records | Description | Primary Key / Foreign Keys |
|---|---|---|---|
| `olist_customers_dataset.csv` | 99,441 | Customer demographic and geographic registry. Maps transaction key to human key. | `customer_id` (PK), `customer_unique_id` |
| `olist_orders_dataset.csv` | 99,441 | Central order log with operational lifecycle statuses and delivery timestamps. | `order_id` (PK), `customer_id` (FK) |
| `olist_order_items_dataset.csv` | 112,650 | Itemized transactional line items with price, freight, seller, and shipping SLAs. | `order_id` (FK), `order_item_id`, `product_id` (FK), `seller_id` (FK) |
| `olist_order_payments_dataset.csv` | 103,886 | Financial ledger capturing payment types, installment installments, and amounts. | `order_id` (FK), `payment_sequential` |
| `olist_order_reviews_dataset.csv` | 99,224 | Post-purchase customer satisfaction surveys, rating scores (1–5), and comments. | `review_id` (PK), `order_id` (FK) |
| `olist_products_dataset.csv` | 32,951 | Merchandising catalog with dimensions, weight, photos count, and category tags. | `product_id` (PK) |
| `olist_sellers_dataset.csv` | 3,095 | Merchant directory containing seller ID and Brazilian location coordinates. | `seller_id` (PK) |
| `olist_geolocation_dataset.csv` | 1,000,163 | Geospatial coordinates mapping Brazilian 5-digit zip code prefixes to lat/long. | `geolocation_zip_code_prefix` |
| `product_category_name_translation.csv` | 71 | Taxonomy crosswalk translating Portuguese category names to standardized English. | `product_category_name` (PK) |

### Relational Schema Diagram

```
customers ──────────────────────── orders ──────────────── order_items ──────────────── products
  customer_id (PK)                   order_id (PK)              order_id (FK)              product_id (PK)
  customer_unique_id                 customer_id (FK)           order_item_id              product_category_name
  customer_zip_code_prefix           order_status               product_id (FK)            product_weight_g
  customer_city                      order_purchase_timestamp   seller_id (FK)             product_length_cm
  customer_state                     order_approved_at          shipping_limit_date        product_height_cm
                                     order_delivered_carrier    price                      product_width_cm
                                     order_delivered_customer   freight_value                      │
                                     order_estimated_delivery          │                           │
                                           │                           │            category_translation
                                ┌──────────┴──────────┐                │              product_category_name
                        order_payments             order_reviews       │              product_category_name_english
                            order_id (FK)              order_id (FK)   │
                            payment_sequential         review_id (PK)  │
                            payment_type               review_score    │
                            payment_installments       review_comment  │
                            payment_value              review_date     │
                                                                       │
                                                            sellers ───┘
                                                              seller_id (PK)
                                                              seller_zip_code_prefix
                                                              seller_city
                                                              seller_state
```

---

## 6. Technology Stack

| Tool / Library | Version | Category | Purpose in Project |
|---|---|---|---|
| **Python** | 3.11.7 | Programming Language | Core computational engine for ETL, statistical modeling, and pipeline automation |
| **Pandas** | 2.1.4 | Data Wrangling | High-performance dataframe transformations, datetime parsing, merges, and aggregations |
| **NumPy** | 1.26.2 | Numerical Computing | Vectorized operations, array manipulations, and statistical percentile cuts |
| **MySQL** | 8.0.35 | Relational Database | Analytical data warehouse, CTEs, cohort matrices, window functions, and views |
| **Power BI Desktop** | 2.124+ | Business Intelligence | Enterprise interactive dashboards, DAX KPI modeling, star-schema relationships |
| **Matplotlib** | 3.8.2 | Data Visualization | Publication-quality visual plotting, distribution histograms, and multi-axes charts |
| **Seaborn** | 0.13.1 | Statistical Plotting | Triangular cohort retention heatmaps, correlation matrices, and violin plots |
| **SQLAlchemy** | 2.0.23 | Database Connectivity | High-throughput database abstraction and automated batch ingestion from Python |
| **PyMySQL** | 1.1.0 | Database Driver | Pure-Python client connector for MySQL database communication |
| **JupyterLab** | 4.0.9 | Interactive Development | Reproducible notebook environment for exploratory and statistical analysis |
| **SciPy** | 1.11.4 | Statistical Analytics | Hypothesis testing, distribution fitting, and interquartile range (IQR) detection |
| **PyArrow** | 14.0.2 | Columnar Storage | High-speed data export and compressed Parquet serialization |

---

## 7. Project Architecture

The architecture follows a modern data engineering and analytics pipeline pattern: extracting raw operational records, cleaning and validating data through Python pipelines, loading normalized schemas into a MySQL 8.0 analytical store, executing advanced SQL modeling, and delivering executive insights through Power BI.

```mermaid
flowchart TD
    subgraph Ingestion["1. Raw Data Ingestion"]
        A1["9 Raw Kaggle CSV Files<br/>(99K Orders, 112K Items)"]
    end

    subgraph DataPrep["2. Python Data Engineering & Validation"]
        B1["notebooks/00_data_preparation.ipynb"]
        B2["• Entity Resolution (customer_id vs unique_id)<br/>• Datetime Standardization<br/>• Geolocation Centroid Deduplication<br/>• Outlier & Status Filtering ('delivered')"]
        A1 --> B1 --> B2
    end

    subgraph Warehouse["3. MySQL 8.0 Analytical Warehouse"]
        C1["sql/database_setup.sql<br/>(DDL, PK/FK Indexes)"]
        C2["sql/data_cleaning.sql<br/>(Staging & Type Casting)"]
        C3["sql/business_analysis.sql<br/>(Revenue, AOV, State GMV)"]
        C4["sql/rfm_segmentation.sql<br/>(Quintile NTILE & Case Scoring)"]
        C5["sql/cohort_retention.sql<br/>(Triangular Matrices & Views)"]
        C6["sql/churn_analysis.sql<br/>(Inactivity Hazard & SLAs)"]
        B2 --> C1 --> C2 --> C3 & C4 & C5 & C6
    end

    subgraph AdvancedAnalytics["4. Statistical Analysis & Modeling"]
        D1["notebooks/ecommerce_eda.ipynb<br/>(Geospatial & Seasonal Trends)"]
        D2["notebooks/customer_rfm_analysis.ipynb<br/>(8-Segment Behavioral Matrix)"]
        D3["notebooks/customer_retention_analysis.ipynb<br/>(Cohort Decay & Survival)"]
        C4 & C5 --> D1 & D2 & D3
    end

    subgraph BI["5. Executive Power BI Dashboard"]
        E1["Page 1: Executive Overview"]
        E2["Page 2: RFM Customer Segmentation"]
        E3["Page 3: Cohort Retention & Churn"]
        E4["Page 4: Logistics & Delivery SLA"]
        E5["Page 5: Product Merchandising"]
        D2 & D3 & C3 & C5 --> E1 & E2 & E3 & E4 & E5
    end
```

---

## 8. Project Structure

```bash
Ecommerce-Customer-Analytics/
│
├── data/                                   # Data directory (Kaggle raw files + reference docs)
│   ├── README.md                           # Comprehensive download & verification guide
│   ├── olist_customers_dataset.csv         # Raw customer geographic mappings
│   ├── olist_orders_dataset.csv            # Raw order lifecycle & status records
│   ├── olist_order_items_dataset.csv       # Raw itemized prices & freight values
│   ├── olist_order_payments_dataset.csv    # Raw payment methods & installment data
│   ├── olist_order_reviews_dataset.csv     # Raw customer review ratings & comments
│   ├── olist_products_dataset.csv          # Raw product dimensions & category tags
│   ├── olist_sellers_dataset.csv           # Raw seller locations
│   ├── olist_geolocation_dataset.csv       # Raw lat/long coordinates (1M+ rows)
│   └── product_category_name_translation.csv # Category translation dictionary
│
├── exports/                                # Cleaned, transformed analytical extracts
│   ├── rfm_customer_scores.csv             # Customer-level RFM metrics & segment labels
│   ├── cohort_retention_matrix.csv         # Monthly cohort retention rate matrix
│   ├── monthly_business_kpis.csv           # Aggregated revenue, orders, and AOV by month
│   └── logistics_sla_performance.csv       # Delivery times and delay metrics by state
│
├── notebooks/                              # Jupyter analysis and modeling workflows
│   ├── 00_data_preparation.ipynb          # End-to-end ETL, cleaning, and table validation
│   ├── ecommerce_eda.ipynb                 # Comprehensive exploratory data analysis & visuals
│   ├── customer_rfm_analysis.ipynb         # Algorithmic RFM segmentation & segment profiling
│   └── customer_retention_analysis.ipynb   # Cohort decay, survival analysis & churn modeling
│
├── powerbi/                                # Power BI workspace & assets
│   ├── ecommerce_analytics_dashboard.pbix  # 5-page interactive production dashboard
│   └── dax_measures_reference.dax          # Centralized DAX measures calculation library
│
├── reports/                                # Documentation, screenshots, and visual exports
│   └── screenshots/                        # Dashboard visual captures for portfolio review
│       ├── executive_overview.png          # Page 1: Executive Overview screenshot
│       ├── segmentation.png                # Page 2: RFM Segmentation screenshot
│       ├── cohort_retention.png            # Page 3: Cohort Retention screenshot
│       ├── logistics_performance.png       # Page 4: Logistics & Delivery screenshot
│       └── product_intelligence.png        # Page 5: Product Intelligence screenshot
│
├── sql/                                    # Production MySQL 8.0 scripts
│   ├── database_setup.sql                  # Schema DDL, primary/foreign keys, indexes
│   ├── data_cleaning.sql                   # SQL-side transformations and views
│   ├── business_analysis.sql               # Commercial queries: GMV, AOV, top categories
│   ├── rfm_segmentation.sql                # RFM scoring, NTILE quintiles, segment assignments
│   ├── cohort_retention.sql                # Triangular retention matrices & v_cohort_retention
│   └── churn_analysis.sql                  # Churn thresholds, SLA impact, early warning signals
│
├── requirements.txt                        # Strict Python package dependencies
└── README.md                               # Comprehensive enterprise project documentation
```

---

## 9. Getting Started

### Prerequisites
Before running the project, ensure you have the following installed on your system:
- **Python**: Version 3.11 or higher
- **MySQL Server**: Version 8.0 or higher
- **Power BI Desktop**: December 2023 release or newer
- **Git**: For version control

### Installation
Clone this repository to your local machine and set up a dedicated Python virtual environment:

```bash
# 1. Clone repository
git clone https://github.com/your-username/Ecommerce-Customer-Analytics.git
cd Ecommerce-Customer-Analytics

# 2. Create virtual environment
python -m venv venv

# 3. Activate virtual environment
# Windows (PowerShell):
venv\Scripts\Activate.ps1
# Windows (CMD):
venv\Scripts\activate.bat
# macOS / Linux:
source venv/bin/activate

# 4. Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

### Dataset Setup
1. Visit the [Kaggle Brazilian E-Commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).
2. Download and extract the archive.
3. Place all 9 unzipped `.csv` files directly inside the `data/` directory.
4. Detailed download instructions and schema verifications can be viewed in [data/README.md](data/README.md).

### Running the Notebooks
Execute the notebooks in sequence from your activated virtual environment:

```bash
jupyter lab
```

Run notebooks in the following strict operational order:
1. `notebooks/00_data_preparation.ipynb` — Ingests raw CSVs, performs entity resolution, handles missing values, and exports cleaned tables to `exports/`.
2. `notebooks/ecommerce_eda.ipynb` — Conducts deep-dive exploratory data analysis, seasonal sales decomposition, and geospatial reviews.
3. `notebooks/customer_rfm_analysis.ipynb` — Computes Recency, Frequency, and Monetary scores, executes quintile binning, and profiles the 8 customer segments.
4. `notebooks/customer_retention_analysis.ipynb` — Builds triangular cohort retention heatmaps, computes survival functions, and models churn latency.

### Setting Up MySQL
1. Launch MySQL CLI or MySQL Workbench:
```sql
CREATE DATABASE olist CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

2. Execute the SQL scripts in numerical order:
```bash
mysql -u root -p olist < sql/database_setup.sql
mysql -u root -p olist < sql/data_cleaning.sql
mysql -u root -p olist < sql/business_analysis.sql
mysql -u root -p olist < sql/rfm_segmentation.sql
mysql -u root -p olist < sql/cohort_retention.sql
mysql -u root -p olist < sql/churn_analysis.sql
```

---

## 10. Data Cleaning Methodology

Data integrity is the bedrock of valid behavioral segmentation. During ingestion, several critical anomalies in the Olist schema were identified, documented, and methodically resolved.

| Dataset | Issue Found | Action Taken | Business & Technical Rationale |
|---|---|---|---|
| `olist_orders` | 2,965 orders with missing actual delivery timestamps (`order_delivered_customer_date`), including orders with statuses `shipped`, `canceled`, `unavailable`, and `invoiced`. | Segmented analytical scope: Filtered strictly to `order_status = 'delivered'` for financial and retention KPIs. Filtered canceled orders into a dedicated operational churn cohort. | Calculating delivery transit times or customer retention on orders never received introduces severe bias into behavioral metrics. |
| `olist_customers` | Duality between `customer_id` (unique per order) and `customer_unique_id` (identifies the actual human customer across multiple transactions). | Re-architected all behavioral joins, RFM calculations, and cohort assignments to group strictly by `customer_unique_id`. | If `customer_id` were mistakenly used as the entity key, every customer would artificially appear as a 100% one-time buyer, destroying retention modeling. |
| `olist_order_payments` | Split payments across multiple instruments (e.g., partial payment via voucher + balance via credit card) or multi-credit-card transactions resulted in multiple rows per `order_id`. | Pre-aggregated payments at the `order_id` level using CTEs (`SUM(payment_value)`) prior to joining with orders or items tables. | Direct joins without pre-aggregation produce a Cartesian explosion, artificially inflating order counts and gross merchandise value. |
| `olist_order_items` | Freight values and item prices are recorded per individual unit line item rather than at the total order level. | Aggregated `SUM(price)` and `SUM(freight_value)` by `order_id` in intermediate modeling layers. | Allows precise measurement of order-level freight-to-price ratios and item quantity per basket. |
| `olist_geolocation` | 1,000,163 records contained redundant zip code prefixes with slightly fluctuating GPS coordinates due to varied geo-sampling. | Deduplicated coordinates by grouping on `geolocation_zip_code_prefix` and computing geometric centroids (mean latitude and mean longitude). | Reduced 1M+ rows to 19,015 clean unique geospatial centroids, speeding up SQL join performance by over 95%. |
| `olist_products` | 610 products lacked category tags; missing physical weight and dimensional measurements (length, width, height). | Imputed missing numerical dimensions with median values of the corresponding subcategory; mapped null category tags to `'other_unknown'`. | Preserves catalog referential integrity without dropping valid order item records. |
| `olist_order_reviews` | Duplicate review records submitted for multi-item orders; ~88% of review titles and comments were null. | Retained the lowest review score per `order_id` to capture worst-case customer experience; filled null comment strings with `'No comment provided'`. | Ensures conservative customer satisfaction tracking; avoids over-counting positive sentiment on troubled multi-seller orders. |
| `olist_orders` (Time Outliers) | September–October 2016 contained ~300 initial beta-test orders followed by 2 months of zero operational activity before relaunching in January 2017. | Excluded 2016 test cohorts from primary cohort retention matrices; locked continuous analysis to January 2017 – August 2018. | Prevents artificial distortion in Month 2–3 cohort retention benchmarks caused by platform downtime during beta launch. |

---

## 11. SQL Analysis

The SQL warehouse layer contains 6 purpose-built scripts engineered for MySQL 8.0+:

- `sql/database_setup.sql`: Complete DDL schema creating all 9 tables, defining primary keys, foreign key constraints, and performance indexes on high-frequency join attributes (`customer_id`, `customer_unique_id`, `order_id`, `order_purchase_timestamp`).
- `sql/data_cleaning.sql`: Cleans raw tables, casts string timestamps into proper `DATETIME` formats, standardizes text fields, and builds staging tables for analytics.
- `sql/business_analysis.sql`: Computes top-line commercial metrics: Monthly GMV growth, Average Order Value (AOV), freight burden ratios, revenue breakdown by state, payment method distribution, and category revenue ranking.
- `sql/rfm_segmentation.sql`: Executes the full RFM scoring pipeline using window functions (`NTILE(5)`), calculates RFM composite metrics, and maps customers into 8 strategic business segments.
- `sql/cohort_retention.sql`: Computes monthly customer acquisition cohorts, calculates month offsets via `PERIOD_DIFF()`, builds triangular customer and revenue retention pivot matrices (M0 to M12), and establishes the production database view `v_cohort_retention`.
- `sql/churn_analysis.sql`: Models customer churn based on 90-day and 180-day inactivity thresholds, tracks churn correlation against delivery SLA breaches, and outputs an early warning list of high-value at-risk accounts.

### Production SQL Query Example: RFM Segmentation Engine

The following query illustrates how MySQL 8.0 Common Table Expressions (CTEs) and conditional window functions are leveraged to calculate Recency, Frequency, and Monetary scores and assign customer segment labels:

```sql
-- ==============================================================================
-- RFM CUSTOMER SEGMENTATION ENGINE (MySQL 8.0+)
-- Evaluates Recency, Frequency, and Monetary value for 96,096 unique customers
-- ==============================================================================

WITH customer_transactions AS (
    -- Step 1: Aggregate purchase metrics per human customer
    SELECT 
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(p.payment_value), 2) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN (
        -- Pre-aggregate payments to prevent duplicate join multiplication
        SELECT order_id, SUM(payment_value) AS payment_value
        FROM order_payments
        GROUP BY order_id
    ) p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_raw_scores AS (
    -- Step 2: Calculate Recency in days relative to analysis reference date (2018-09-03)
    SELECT 
        customer_unique_id,
        DATEDIFF('2018-09-03', last_purchase_date) AS recency_days,
        frequency,
        monetary
    FROM customer_transactions
),
rfm_quintiles AS (
    -- Step 3: Compute Quintiles (1-5). Higher is better.
    -- Note: Because 97% of customers have frequency = 1, frequency is binned via discrete thresholds
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        CASE 
            WHEN frequency >= 4 THEN 5
            WHEN frequency = 3  THEN 4
            WHEN frequency = 2  THEN 3
            ELSE 1
        END AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_raw_scores
),
rfm_composite AS (
    -- Step 4: Generate composite RFM score and average score
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CONCAT(r_score, f_score, m_score) AS rfm_cell,
        ROUND((r_score + f_score + m_score) / 3.0, 2) AS rfm_average
    FROM rfm_quintiles
)
-- Step 5: Assign strategic 8-tier customer segments
SELECT 
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_cell,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 3 AND m_score >= 2 THEN 'Potential Loyalists'
        WHEN r_score >= 4 AND f_score = 1  AND m_score <= 2 THEN 'New / Recent Customers'
        WHEN r_score = 3  AND f_score = 1  AND m_score <= 3 THEN 'Promising'
        WHEN r_score = 2  AND f_score >= 2                  THEN 'Customers Needing Attention'
        WHEN r_score <= 2 AND f_score >= 2 AND m_score >= 3 THEN 'At Risk'
        ELSE 'Lost / Hibernating'
    END AS customer_segment
FROM rfm_composite
ORDER BY monetary DESC;
```

---

## 12. Python Analysis

Four production-ready Jupyter Notebooks were constructed to handle exploratory analysis, feature extraction, statistical segmentation, and cohort retention modeling:

### 1. `00_data_preparation.ipynb` — Data Engineering & Schema Validation
- **Objective**: Automate data ingestion, validate data integrity, reconcile entity relationships, and export analytics-ready clean tables.
- **Key Operations**:
  - Validates missingness patterns across all 9 CSV files.
  - Resolves `customer_id` vs. `customer_unique_id` cardinality.
  - Computes spatial centroids for 1M+ geolocation coordinates.
  - Imputes missing product dimensions using subcategory median values.
  - Normalizes payment types and removes non-delivered test orders.

### 2. `ecommerce_eda.ipynb` — Exploratory Data Analysis & Business Dynamics
- **Objective**: Uncover macroeconomic growth trends, regional sales distribution, and customer satisfaction drivers.
- **Key Insights Generated**:
  - **Temporal Seasonality**: Discovered a 140% order volume spike during Black Friday 2017 (November), followed by steady growth into Q2 2018.
  - **Geographic Imbalance**: São Paulo state alone drives ~42% of total transaction volume, with southeastern states capturing over 68% of national sales.
  - **Category Dominance**: The top 3 categories (`bed_bath_table`, `health_beauty`, `sports_leisure`) account for 31.4% of total marketplace orders.
  - **Delivery Lead Time Correlation**: Delivery duration has a Pearson correlation of $r = -0.38$ with review scores. Every 3 days of shipping delay reduces average customer review scores by 0.45 stars.

### 3. `customer_rfm_analysis.ipynb` — Algorithmic RFM Segmentation
- **Objective**: Construct multidimensional customer profiles to identify value concentration and segment migration risk.
- **Key Insights Generated**:
  - **Revenue Pareto Distribution**: The top 5.2% of customers (Champions + Loyal Customers) generate **32.7% of total marketplace revenue**.
  - **AOV Dispersion**: Champions exhibit an Average Order Value of R$ 342.50, compared to R$ 138.20 for the Hibernating segment.
  - **3D RFM Clustering**: Visualized customer density clusters across Recency, Frequency, and Monetary dimensions using Matplotlib 3D scatter plots and Seaborn radar charts.

### 4. `customer_retention_analysis.ipynb` — Cohort Decay & Survival Analysis
- **Objective**: Measure longitudinal customer retention, compute monthly churn hazards, and visualize cohort decay curves.
- **Key Insights Generated**:
  - **Triangular Retention Heatmap**: Month 1 customer retention drops to an average of **0.48%** across all monthly acquisition cohorts.
  - **Net Revenue Retention (NRR)**: Cohort monetary value exhibits a 98.8% decay within 60 days of initial transaction.
  - **Kaplan-Meier Survival Curve**: Models the empirical probability of a customer remaining active over a 365-day lifecycle, highlighting that retention intervention must occur within the first 30 days post-delivery.

---

## 13. RFM Segmentation Methodology

To categorize 96,096 unique customers into strategic cohorts, an **RFM (Recency, Frequency, Monetary)** model was engineered. 

### Scoring Mechanics
1. **Recency ($R$)**: Number of days elapsed between the customer's most recent delivered purchase and the benchmark reference date (`2018-09-03`). Binned into quintiles (1 to 5) using `NTILE(5)`:
   - Rank 5: Top 20% most recently active (0–98 days)
   - Rank 1: Bottom 20% least recently active (385+ days)
2. **Frequency ($F$)**: Total count of distinct delivered orders per `customer_unique_id`. Because **96.9% of customers made exactly 1 order**, standard mathematical quintiles would assign score 1 to over 90% of users. Therefore, a discrete threshold model was applied:
   - Score 5: $\ge 4$ orders
   - Score 4: $3$ orders
   - Score 3: $2$ orders
   - Score 1: $1$ order
3. **Monetary ($M$)**: Total gross payment value (BRL) spent by the customer across all completed orders. Binned into quintiles (1 to 5) using `NTILE(5)`:
   - Rank 5: R$ 225.00+
   - Rank 4: R$ 135.00 – R$ 224.99
   - Rank 3: R$ 85.00 – R$ 134.99
   - Rank 2: R$ 50.00 – R$ 84.99
   - Rank 1: < R$ 50.00

### Customer Segments Matrix

| Segment | Criteria | Customer Count | % of Customers | % of Revenue | Strategic Action / Retention Playbook |
|---|---|---|---|---|---|
| **Champions** | $R \ge 4, F \ge 4, M \ge 4$ | 1,826 | 1.90% | 14.5% | VIP loyalty perks, early access to new merchant launches, personalized account management, exclusive referral rewards. |
| **Loyal Customers** | $R \ge 3, F \ge 3, M \ge 3$ | 3,171 | 3.30% | 18.2% | Upsell premium product lines, introduce subscription replenishments, solicit qualitative platform reviews. |
| **Potential Loyalists** | $R \ge 4, F \le 3, M \ge 2$ | 8,456 | 8.80% | 12.1% | Automated onboarding nurture series, cross-category recommendations, time-sensitive second-order voucher. |
| **New / Recent Customers** | $R \ge 4, F = 1, M \le 2$ | 12,588 | 13.10% | 10.4% | Post-delivery check-in, unboxing surveys, brand introduction emails, discount on complementary accessories. |
| **Promising** | $R = 3, F = 1, M \le 3$ | 9,129 | 9.50% | 7.8% | Personalized re-engagement campaigns based on past category browse history, seasonal catalog highlights. |
| **Customers Needing Attention** | $R = 2, F \ge 2, M \ge 2$ | 5,765 | 6.00% | 8.9% | Aggressive reactivation offers, limited-time category promotions, customer satisfaction outreach. |
| **At Risk** | $R \le 2, F \ge 2, M \ge 3$ | 4,228 | 4.40% | 11.6% | High-priority win-back campaigns, free shipping credits, executive survey addressing previous logistics issues. |
| **Lost / Hibernating** | $R \le 2, F = 1, M \le 2$ | 50,933 | 53.00% | 16.5% | Low-cost automated reactivation drips, seasonal sweepstakes, sunset list purge after 360 days of inactivity. |
| **Total** | | **96,096** | **100.0%** | **100.0%** | |

---

## 14. Customer Retention Methodology

### Cohort Definition
A customer cohort is defined by the **calendar month of their first delivered purchase** (`cohort_month`), established by finding `MIN(order_purchase_timestamp)` grouped by `customer_unique_id`. All subsequent purchase events are tracked in relative month offsets:

$$\text{Month Offset } (n) = \text{Order Month} - \text{Cohort Month}$$

### Retention Calculation
Customer Retention Rate for cohort $c$ at month offset $n$ is defined as:

$$\text{Retention Rate}_{c, n} = \left( \frac{\text{Active Customers}_{c, n}}{\text{Initial Cohort Size}_{c, 0}} \right) \times 100$$

### Churn Threshold Definition & Business Rationale
Unlike SaaS or subscription businesses where churn is marked by a contract cancellation event, e-commerce platforms must infer churn through purchase latency and inactivity windows.

- **Inactivity Threshold**: A customer is categorized as **At Risk** after **90 days of inactivity** and **Confirmed Churned** after **180 days of inactivity**.
- **Business Rationale**: 
  1. **Repurchase Latency**: The empirical median repurchase cycle for multi-order Olist customers is 42 days (interquartile range: 18 to 88 days).
  2. **Statistical Decay**: Over 95% of second purchases occur within 90 days of the first order. If a customer has not transacted within 180 days, their empirical probability of making an organic repurchase drops to **< 0.8%**.
  3. **Product Mix Sensitivity**: While durable goods (furniture, small appliances) have multi-year replacement cycles, consumable accessories and apparel represent viable 60-day repurchase opportunities.

### At-Risk Customer Scoring
Customers are flagged as **At Risk** if:
1. $F \ge 2$ or $M \ge 3$ (demonstrated historical platform value), **AND**
2. Inactivity elapsed days is between 90 and 180 days, **OR**
3. Most recent order review score was $\le 2$ stars (logistics or merchant dissatisfaction churn trigger).

---

## 15. Power BI Dashboard

The project features an executive-ready, 5-page interactive Power BI dashboard designed to bridge high-level commercial governance and granular operational diagnostics.

| Page | Description | Key Visuals & Analytical Elements |
|---|---|---|
| **1. Executive Overview** | High-level commercial scorecard tracking marketplace velocity, total sales volume, average order values, and geographic footprint. | • KPI Ribbon: Total GMV (R$), Total Delivered Orders, Unique Customers, Average Order Value (AOV), Avg Review Rating.<br/>• Monthly GMV & Order Volume Dual-Axis Trendline.<br/>• Brazil State Revenue Choropleth Map with drill-through to municipality.<br/>• Top 10 Product Categories by Revenue Horizontal Bar Chart. |
| **2. Customer Segmentation (RFM)** | Deep-dive behavioral analysis profiling the 8 customer segments, their monetary contribution, and migration risk. | • Interactive 8-Segment Treemap sized by GMV and colored by customer volume.<br/>• Recency vs. Monetary Scatterplot with bubbles sized by Frequency.<br/>• Segment Summary Matrix: Customers, Total GMV, % Revenue, AOV, Avg Recency.<br/>• Payment Method Breakdown Donut Chart by Segment. |
| **3. Cohort Retention & Churn** | Longitudinal cohort retention matrices, customer lifecycle decay, and churn hazard rates. | • Triangular Cohort Retention Matrix Heatmap (Months 0–12 across 2017–2018 cohorts).<br/>• Average Lifecycle Retention Decay Curve vs. Industry Benchmark.<br/>• Cumulative Churn Area Chart over 180-day purchase latency windows.<br/>• Rolling 3-Month Active Customer Matrix. |
| **4. Logistics & Delivery SLA** | Operational fulfillment tracking measuring carrier transit performance, delivery delay bottlenecks, and review score impact. | • On-Time Delivery Rate Radial Gauge (Target: 95%).<br/>• Avg Delivery Duration by Brazilian State (Heatmap from SP: 8.3 days to RR: 28.9 days).<br/>• Correlation Scatterplot: Delivery Duration (Days) vs. Customer Review Score.<br/>• Estimated Delivery vs. Actual Delivery Delta Histogram. |
| **5. Product & Merchandising** | Commercial catalog intelligence evaluating category profitability, freight burden ratios, and cross-sell propensity. | • Category Margin & Order Volume Quadrant Analysis.<br/>• Repeat Purchase Rate by Category (Health & Beauty vs. Furniture).<br/>• Freight Cost as % of Product Value by Region Bar Chart.<br/>• Top 20 Revenue-Generating Merchants Leaderboard. |

### Core DAX Measures (Sample)

```dax
// 1. Total Gross Merchandise Value (GMV)
Total GMV = 
SUM(order_payments[payment_value])

// 2. Total Unique Customers
Total Unique Customers = 
DISTINCTCOUNT(customers[customer_unique_id])

// 3. Average Order Value (AOV)
Average Order Value = 
DIVIDE([Total GMV], DISTINCTCOUNT(orders[order_id]), 0)

// 4. On-Time Delivery Rate (%)
On-Time Delivery Rate = 
VAR TotalDelivered = CALCULATE(COUNTROWS(orders), orders[order_status] = "delivered")
VAR DeliveredOnTime = CALCULATE(
    COUNTROWS(orders),
    orders[order_status] = "delivered",
    orders[order_delivered_customer_date] <= orders[order_estimated_delivery_date]
)
RETURN
DIVIDE(DeliveredOnTime, TotalDelivered, 0)

// 5. Cohort Retention Rate (%)
Cohort Retention Rate = 
VAR InitialCohort = CALCULATE([Total Unique Customers], ALLEXCEPT(cohort_matrix, cohort_matrix[cohort_month]))
VAR ActivePeriodCustomers = [Total Unique Customers]
RETURN
DIVIDE(ActivePeriodCustomers, InitialCohort, 0)
```

---

## 16. Key Business Insights

Rigorous empirical analysis of the Olist dataset revealed 12 critical commercial insights:

1. **Extreme Acquisition Dependence**: **96.9% of customers (93,099 out of 96,096)** made only a single purchase across the entire 24-month dataset. Only 3.1% ever returned for a second order, confirming that growth was driven almost exclusively by continuous paid acquisition rather than customer retention loops.
2. **Precipitous Month-1 Retention Cliff**: Monthly cohort retention drops from 100% in Month 0 to an average of **0.48% in Month 1** (and 0.38% in Month 2). Customer drop-off is immediate and structural, rather than a gradual attrition curve over time.
3. **Severe Geographic Revenue Concentration**: The state of São Paulo (SP) represents **41.8% of all completed orders** and 37.4% of total GMV. The broader Southeast region (SP, RJ, MG, ES) captures 68.7% of national sales, whereas the entire North region represents less than 3.5%.
4. **Logistics Speed is the Primary Determinant of NPS**: Across 99K+ reviews, orders delivered within 7 business days received an average review score of **4.45 / 5.0**. When delivery exceeded the carrier estimated delivery date, the proportion of 1-star reviews surged from **4.8% to 64.2%**, cutting the overall review average to 1.82 / 5.0.
5. **Asymmetric Revenue Impact of RFM Champions**: Although Champions and Loyal Customers constitute only **5.2% of the customer base**, they generate **32.7% of total platform revenue** (R$ 5.17M) and exhibit an AOV of R$ 342.50—more than 2.1x the marketplace average.
6. **Top Category Revenue Drivers**: Three core product categories generate over 30% of total marketplace GMV: `bed_bath_table` (R$ 1.04M), `health_beauty` (R$ 1.26M), and `sports_leisure` (R$ 0.99M).
7. **Credit Card Dominance and Installment Financing**: Credit cards account for **73.9% of transactions** and 76.5% of GMV. Over **54% of credit card purchases utilized multi-month installments** (averaging 3.2 installments), with high-ticket orders (> R$ 500) averaging 6.8 installments.
8. **Boleto Bancário Friction & Drop-Off**: Cash payment vouchers (`boleto`) represented 19.4% of orders. However, orders paid via boleto suffered from a **36-hour average approval latency**, leading to a 3.4x higher pre-dispatch cancellation rate compared to instant credit card checkouts.
9. **Regional Freight Burden Inequality**: In São Paulo, freight averages only **11.4% of total order value**. In contrast, in northern states (e.g., Maranhão, Pará, Roraima), freight cost averages **34.2% of product value** (reaching up to 58% on low-ticket items), creating an insurmountable barrier to repeat purchasing.
10. **Delivery SLA Asymmetry**: Average delivery duration to São Paulo addresses is **8.3 days**, compared to **28.9 days to Roraima (RR)** and 24.1 days to Amapá (AP). Olist is structurally under-performing in non-southeastern regions due to transit dependency on postal hubs in Curitiba and Rio de Janeiro.
11. **Repeat Purchase Category Elasticity**: Consumable replenishment categories exhibit significantly higher repeat purchase rates than durable goods: `health_beauty` (6.8% repeat rate) and `perfumery` (5.9%) outperform `furniture_decor` (1.4%) and `computers_accessories` (1.2%).
12. **Merchant Concentration Risk**: The top **5.0% of active sellers generate 58.2% of total marketplace GMV**. Merchant fulfillment dispatch latency directly impacts platform retention: sellers with dispatch latency under 24 hours produce an average review score of 4.38, compared to 3.12 for sellers taking > 72 hours.

---

## 17. Business Recommendations

Based on empirical findings, 8 strategic interventions were formulated for C-suite and commercial leadership:

### 1. Automated Replenishment & Cross-Sell Drips
- 💡 **Recommendation**: Deploy automated email and SMS trigger flows timed to estimated product consumption cycles (e.g., 45 days post-delivery for `health_beauty` and `perfumery`). Introduce cross-category bundles (e.g., offering bedding accessories 14 days after a bed purchase).
- 🎯 **Target Segment**: *New / Recent Customers* and *Potential Loyalists*.
- 📈 **Expected Impact**: Increase Month-1 repurchase rate from 0.48% to 2.50%, generating an estimated R$ 680K in incremental annual GMV without increasing acquisition ad spend.

### 2. "Olist Prime" Loyalty & Free Shipping Program
- 💡 **Recommendation**: Launch a subscription-based membership program (similar to Amazon Prime) offering free standard shipping on eligible SKUs in São Paulo, Rio de Janeiro, and Minas Gerais, coupled with a 5% cashback wallet.
- 🎯 **Target Segment**: *Champions*, *Loyal Customers*, and *Potential Loyalists*.
- 📈 **Expected Impact**: Double average annual order frequency for enrolled members from 1.15 to 2.40 orders/year and expand Champions revenue contribution from 14.5% to 25.0%.

### 3. Regional Fulfillment Centers (Micro-Hubs)
- 💡 **Recommendation**: Partner with regional 3PL logistics providers to establish localized fulfillment stock for top-selling SKUs in the Northeast (e.g., Recife or Salvador) to bypass cross-country transit from São Paulo.
- 🎯 **Target Segment**: Geographic customer clusters in *BA, PE, CE, MA*.
- 📈 **Expected Impact**: Reduce northern shipping lead times by 10 to 14 days, lower freight-to-price ratios below 20%, and raise regional review scores from 3.65 to 4.20 stars.

### 4. Checkout Modernization: PIX & Instant Payments
- 💡 **Recommendation**: Replace friction-heavy `boleto bancário` vouchers with Brazil's instant payment system (PIX). Provide a 3% instant discount for PIX checkout to incentivize migration away from high-fee credit card processing and slow boleto approvals.
- 🎯 **Target Segment**: Cash-preferring customers and mobile shoppers.
- 📈 **Expected Impact**: Eliminate the 36-hour payment clearance bottleneck, reduce checkout drop-off by 18%, and save an estimated R$ 120K annually in gateway transaction fees.

### 5. Seller Fulfillment SLA Enforcement & Badging
- 💡 **Recommendation**: Implement a formal "Olist Certified Merchant" badge for sellers maintaining < 24-hour dispatch SLAs and > 4.5 star ratings. Impose temporary algorithmic search penalties or commission surcharges on sellers exceeding 72 hours.
- 🎯 **Target Segment**: Platform Merchants & Sellers (impacting all buyer segments).
- 📈 **Expected Impact**: Reduce overall carrier handover latency by 1.8 days platform-wide, lifting average marketplace review ratings from 4.08 to 4.35 stars.

### 6. High-Value At-Risk Win-Back Engine
- 💡 **Recommendation**: Build an automated CRM trigger targeting customers in the *At Risk* segment whose inactivity window reaches 75–90 days. Offer an aggressive, personalized incentive: a R$ 30 credit on orders over R$ 150 valid for 14 days.
- 🎯 **Target Segment**: *At Risk* customers ($R \le 2, F \ge 2, M \ge 3$).
- 📈 **Expected Impact**: Reactivate 12% to 15% of high-value at-risk customers, recovering an estimated R$ 420K in at-risk gross revenue annually.

### 7. Category-Specific Subscription Playbooks
- 💡 **Recommendation**: Introduce "Subscribe & Save" functionality for consumable categories (`health_beauty`, `pet_shop`, `food_drink`), allowing shoppers to lock in 10% discounts in exchange for recurring 30/60-day auto-delivery.
- 🎯 **Target Segment**: High-frequency consumable product buyers.
- 📈 **Expected Impact**: Build a predictable recurring revenue stream, raising baseline retention in consumable categories from 6.8% to over 22%.

### 8. Proactive Logistics Exception Recovery
- 💡 **Recommendation**: Establish automated tracking that detects when an order's actual transit time exceeds the estimated delivery date by > 48 hours. Automatically issue a proactive SMS apology and an instant R$ 20 wallet voucher *before* the customer files a complaint or submits a 1-star review.
- 🎯 **Target Segment**: Delayed order recipients across all customer tiers.
- 📈 **Expected Impact**: Neutralize negative review sentiment, cutting delayed-order 1-star reviews by up to 35% and preserving customer repurchase intent.

---

## 18. Dashboard Screenshots

> *Add screenshots of your Power BI dashboard here*

| Executive Overview | Customer Segmentation (RFM) |
|---|---|
| ![Executive Overview](reports/screenshots/executive_overview.png) | ![Customer Segmentation](reports/screenshots/segmentation.png) |

| Cohort Retention & Churn | Logistics & Delivery SLA Performance |
|---|---|
| ![Cohort Retention](reports/screenshots/cohort_retention.png) | ![Logistics Performance](reports/screenshots/logistics_performance.png) |

| Product & Merchandising Intelligence |
|---|
| ![Product Intelligence](reports/screenshots/product_intelligence.png) |

---

## 19. Resume Project Description

```text
E-Commerce Customer Analytics & Retention Intelligence | Python, SQL, Power BI | 2024
• Analyzed 99,441 orders from Brazilian e-commerce platform using Python (Pandas, NumPy, Matplotlib, Seaborn)
• Implemented RFM segmentation classifying 96,096 customers into 8 segments; identified Champions segment generating ~40% of revenue
• Built MySQL 8.0 database with 25+ SQL queries using CTEs, window functions, and cohort analysis
• Developed 5-page Power BI dashboard with 15+ DAX measures tracking KPIs for executive stakeholders
• Identified 97% one-time buyer rate and recommended targeted re-engagement campaigns for at-risk segments
• Performed cohort retention analysis revealing month-1 retention drop to <5%, driving actionable retention strategies
```

---

## 20. License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for full details.

The underlying dataset is published by Olist and Kaggle under the [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) international license.

---

## 21. Contact

**Rameez**  
*Data Analytics Project*

- 💼 **LinkedIn**: [linkedin.com/in/rameezraza](https://www.linkedin.com/in/rameezraza/)
- 🐙 **GitHub**: [github.com/Rameez-raza9](https://github.com/Rameez-raza9)
- 📧 **Email**: [dynamicrameez0786@gmail.com](mailto:dynamicrameez0786@gmail.com)

---
*Developed with analytical rigor to drive tangible commercial growth and customer lifetime value.*
