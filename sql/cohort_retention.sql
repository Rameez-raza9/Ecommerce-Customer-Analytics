-- ==============================================================================
-- PROJECT: E-Commerce Customer Analytics (Olist Brazilian E-Commerce)
-- SCRIPT:  cohort_retention.sql
-- DIALECT: MySQL 8.0+
-- DESCRIPTION:
--   Complete customer cohort retention and revenue retention analysis.
--   Tracks customer repeat purchasing behavior over time across acquisition cohorts.
--
-- SECTIONS:
--   1. Core Cohort Retention Analysis (Monthly Active Customers & Retention Rate)
--   2. Cohort Retention Pivot Matrix (Months 0-12 for Key Cohorts 2017-01 to 2018-06)
--   3. Average Retention Rate by Month Number Across All Cohorts (Benchmark Curve)
--   4. Best and Worst Performing Cohorts by Month-1 Retention
--   5. Cohort Revenue Retention (Monetary Retention & Decay Matrix)
--   6. Rolling 3-Month Active Customer Calculation (Multi-Month Window Retention)
--   7. Database View Definition: v_cohort_retention
-- ==============================================================================

USE olist; -- Adjust database name as appropriate for your local setup

-- ==============================================================================
-- SECTION 1: CORE COHORT RETENTION ANALYSIS (STANDARD LONG FORMAT)
-- ==============================================================================
-- Cohort Definition: Customer's first delivered purchase month (customer_unique_id)
-- Month Offset (months_since_first_purchase): Calendar months elapsed between cohort month and order month
-- Active Customers: Distinct customers who placed at least one delivered order in month N
-- Retention Rate: (Active Customers in Month N / Initial Cohort Size in Month 0) * 100

WITH customer_cohorts AS (
    -- Step 1: Assign each customer their cohort (first purchase month)
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month,
        DATE(MIN(o.order_purchase_timestamp)) AS first_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    -- Step 2: All delivered orders per customer mapped to cohort and month offset
    SELECT 
        cc.customer_unique_id,
        cc.cohort_month,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        PERIOD_DIFF(
            DATE_FORMAT(o.order_purchase_timestamp, '%Y%m'),
            DATE_FORMAT(cc.first_order_date, '%Y%m')
        ) AS months_since_first_purchase
    FROM customer_cohorts cc
    JOIN customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_sizes AS (
    -- Step 3: Cohort sizes (Month 0 baseline count of unique customers)
    SELECT 
        cohort_month, 
        COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
cohort_activity AS (
    -- Step 4: Active customers per cohort per month offset
    SELECT 
        cohort_month,
        months_since_first_purchase AS month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM customer_orders
    GROUP BY cohort_month, months_since_first_purchase
)
-- Step 5: Retention matrix with retention rates
SELECT 
    ca.cohort_month,
    cs.cohort_size,
    ca.month_number,
    ca.active_customers,
    ROUND(100.0 * ca.active_customers / cs.cohort_size, 2) AS retention_rate
FROM cohort_activity ca
JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
ORDER BY ca.cohort_month, ca.month_number;


-- ==============================================================================
-- SECTION 2: COHORT RETENTION PIVOT MATRICES (FIRST 12 MONTHS: M0 TO M12)
-- Key Cohorts: 2017-01 through 2018-06
-- ==============================================================================

-- 2A. Retention Rate (%) Pivot Matrix
-- Shows retention percentage from Month 0 (100.00%) to Month 12 for key cohorts
WITH customer_cohorts AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month,
        DATE(MIN(o.order_purchase_timestamp)) AS first_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    SELECT 
        cc.customer_unique_id,
        cc.cohort_month,
        PERIOD_DIFF(
            DATE_FORMAT(o.order_purchase_timestamp, '%Y%m'),
            DATE_FORMAT(cc.first_order_date, '%Y%m')
        ) AS months_since_first_purchase
    FROM customer_cohorts cc
    JOIN customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_sizes AS (
    SELECT 
        cohort_month, 
        COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
cohort_activity AS (
    SELECT 
        cohort_month,
        months_since_first_purchase AS month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM customer_orders
    GROUP BY cohort_month, months_since_first_purchase
),
retention_rates AS (
    SELECT 
        ca.cohort_month,
        cs.cohort_size,
        ca.month_number,
        ROUND(100.0 * ca.active_customers / cs.cohort_size, 2) AS retention_rate
    FROM cohort_activity ca
    JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
)
SELECT 
    cohort_month,
    cohort_size,
    MAX(CASE WHEN month_number = 0  THEN retention_rate END) AS m0,
    MAX(CASE WHEN month_number = 1  THEN retention_rate END) AS m1,
    MAX(CASE WHEN month_number = 2  THEN retention_rate END) AS m2,
    MAX(CASE WHEN month_number = 3  THEN retention_rate END) AS m3,
    MAX(CASE WHEN month_number = 4  THEN retention_rate END) AS m4,
    MAX(CASE WHEN month_number = 5  THEN retention_rate END) AS m5,
    MAX(CASE WHEN month_number = 6  THEN retention_rate END) AS m6,
    MAX(CASE WHEN month_number = 7  THEN retention_rate END) AS m7,
    MAX(CASE WHEN month_number = 8  THEN retention_rate END) AS m8,
    MAX(CASE WHEN month_number = 9  THEN retention_rate END) AS m9,
    MAX(CASE WHEN month_number = 10 THEN retention_rate END) AS m10,
    MAX(CASE WHEN month_number = 11 THEN retention_rate END) AS m11,
    MAX(CASE WHEN month_number = 12 THEN retention_rate END) AS m12
FROM retention_rates
WHERE cohort_month BETWEEN '2017-01' AND '2018-06'
GROUP BY cohort_month, cohort_size
ORDER BY cohort_month;


-- 2B. Active Customer Count Pivot Matrix
-- Shows the raw number of distinct repeating customers each month
WITH customer_cohorts AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month,
        DATE(MIN(o.order_purchase_timestamp)) AS first_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    SELECT 
        cc.customer_unique_id,
        cc.cohort_month,
        PERIOD_DIFF(
            DATE_FORMAT(o.order_purchase_timestamp, '%Y%m'),
            DATE_FORMAT(cc.first_order_date, '%Y%m')
        ) AS months_since_first_purchase
    FROM customer_cohorts cc
    JOIN customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
cohort_activity AS (
    SELECT 
        cohort_month,
        months_since_first_purchase AS month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM customer_orders
    GROUP BY cohort_month, months_since_first_purchase
)
SELECT 
    ca.cohort_month,
    cs.cohort_size,
    MAX(CASE WHEN ca.month_number = 0  THEN ca.active_customers END) AS m0_active,
    MAX(CASE WHEN ca.month_number = 1  THEN ca.active_customers END) AS m1_active,
    MAX(CASE WHEN ca.month_number = 2  THEN ca.active_customers END) AS m2_active,
    MAX(CASE WHEN ca.month_number = 3  THEN ca.active_customers END) AS m3_active,
    MAX(CASE WHEN ca.month_number = 4  THEN ca.active_customers END) AS m4_active,
    MAX(CASE WHEN ca.month_number = 5  THEN ca.active_customers END) AS m5_active,
    MAX(CASE WHEN ca.month_number = 6  THEN ca.active_customers END) AS m6_active,
    MAX(CASE WHEN ca.month_number = 7  THEN ca.active_customers END) AS m7_active,
    MAX(CASE WHEN ca.month_number = 8  THEN ca.active_customers END) AS m8_active,
    MAX(CASE WHEN ca.month_number = 9  THEN ca.active_customers END) AS m9_active,
    MAX(CASE WHEN ca.month_number = 10 THEN ca.active_customers END) AS m10_active,
    MAX(CASE WHEN ca.month_number = 11 THEN ca.active_customers END) AS m11_active,
    MAX(CASE WHEN ca.month_number = 12 THEN ca.active_customers END) AS m12_active
FROM cohort_activity ca
JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
WHERE ca.cohort_month BETWEEN '2017-01' AND '2018-06'
GROUP BY ca.cohort_month, cs.cohort_size
ORDER BY ca.cohort_month;


-- ==============================================================================
-- SECTION 3: AVERAGE RETENTION RATE BY MONTH NUMBER ACROSS ALL COHORTS
-- Benchmark curve showing expected customer retention decay across lifecycle months
-- ==============================================================================

WITH customer_cohorts AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month,
        DATE(MIN(o.order_purchase_timestamp)) AS first_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    SELECT 
        cc.customer_unique_id,
        cc.cohort_month,
        PERIOD_DIFF(
            DATE_FORMAT(o.order_purchase_timestamp, '%Y%m'),
            DATE_FORMAT(cc.first_order_date, '%Y%m')
        ) AS months_since_first_purchase
    FROM customer_cohorts cc
    JOIN customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
cohort_activity AS (
    SELECT 
        cohort_month,
        months_since_first_purchase AS month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM customer_orders
    GROUP BY cohort_month, months_since_first_purchase
),
retention_matrix AS (
    SELECT 
        ca.cohort_month,
        cs.cohort_size,
        ca.month_number,
        ca.active_customers,
        ROUND(100.0 * ca.active_customers / cs.cohort_size, 2) AS retention_rate
    FROM cohort_activity ca
    JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
)
SELECT 
    month_number,
    COUNT(DISTINCT cohort_month) AS cohorts_observed,
    SUM(cohort_size) AS total_cohort_customer_pool,
    SUM(active_customers) AS total_active_customers,
    ROUND(AVG(retention_rate), 2) AS avg_retention_rate,
    ROUND(100.0 * SUM(active_customers) / SUM(cohort_size), 2) AS weighted_retention_rate,
    MIN(retention_rate) AS min_retention_rate,
    MAX(retention_rate) AS max_retention_rate
FROM retention_matrix
WHERE month_number <= 18
GROUP BY month_number
ORDER BY month_number ASC;


-- ==============================================================================
-- SECTION 4: BEST AND WORST PERFORMING COHORTS BY MONTH-1 RETENTION
-- Month 1 retention is the primary early indicator of customer stickiness.
-- ==============================================================================

WITH customer_cohorts AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month,
        DATE(MIN(o.order_purchase_timestamp)) AS first_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    SELECT 
        cc.customer_unique_id,
        cc.cohort_month,
        PERIOD_DIFF(
            DATE_FORMAT(o.order_purchase_timestamp, '%Y%m'),
            DATE_FORMAT(cc.first_order_date, '%Y%m')
        ) AS months_since_first_purchase
    FROM customer_cohorts cc
    JOIN customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
month_1_activity AS (
    SELECT 
        co.cohort_month,
        COUNT(DISTINCT co.customer_unique_id) AS active_customers_m1
    FROM customer_orders co
    WHERE co.months_since_first_purchase = 1
    GROUP BY co.cohort_month
),
cohort_m1_performance AS (
    SELECT 
        cs.cohort_month,
        cs.cohort_size,
        COALESCE(m1.active_customers_m1, 0) AS active_customers_m1,
        ROUND(100.0 * COALESCE(m1.active_customers_m1, 0) / cs.cohort_size, 2) AS m1_retention_rate,
        DENSE_RANK() OVER (ORDER BY ROUND(100.0 * COALESCE(m1.active_customers_m1, 0) / cs.cohort_size, 2) DESC) AS rank_desc,
        DENSE_RANK() OVER (ORDER BY ROUND(100.0 * COALESCE(m1.active_customers_m1, 0) / cs.cohort_size, 2) ASC) AS rank_asc
    FROM cohort_sizes cs
    LEFT JOIN month_1_activity m1 ON cs.cohort_month = m1.cohort_month
    -- Exclude cohorts that haven't matured past month 1 or historical anomalies with < 50 customers
    WHERE cs.cohort_size >= 50
)
-- Unified view highlighting Top 5 and Bottom 5 cohorts
SELECT 
    cohort_month,
    cohort_size,
    active_customers_m1,
    m1_retention_rate,
    CASE 
        WHEN rank_desc <= 5 THEN CONCAT('Top Performer #', rank_desc)
        WHEN rank_asc <= 5  THEN CONCAT('Bottom Performer #', rank_asc)
        ELSE 'Mid-Tier Cohort'
    END AS performance_category
FROM cohort_m1_performance
WHERE rank_desc <= 5 OR rank_asc <= 5
ORDER BY m1_retention_rate DESC;


-- ==============================================================================
-- SECTION 5: COHORT REVENUE RETENTION (NET REVENUE RETENTION / MONETARY DECAY)
-- Calculates monetary retention by tracking SUM(payment_value) over time
-- ==============================================================================

-- 5A. Detailed Revenue Retention Matrix
WITH customer_cohorts AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month,
        DATE(MIN(o.order_purchase_timestamp)) AS first_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
order_payment_totals AS (
    -- Pre-aggregate payments per order to prevent duplication
    SELECT 
        order_id, 
        ROUND(SUM(payment_value), 2) AS total_order_value
    FROM order_payments
    GROUP BY order_id
),
customer_orders AS (
    SELECT 
        cc.cohort_month,
        cc.customer_unique_id,
        o.order_id,
        opt.total_order_value,
        PERIOD_DIFF(
            DATE_FORMAT(o.order_purchase_timestamp, '%Y%m'),
            DATE_FORMAT(cc.first_order_date, '%Y%m')
        ) AS months_since_first_purchase
    FROM customer_cohorts cc
    JOIN customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payment_totals opt ON o.order_id = opt.order_id
    WHERE o.order_status = 'delivered'
),
cohort_revenue_activity AS (
    SELECT 
        cohort_month,
        months_since_first_purchase AS month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers,
        ROUND(SUM(total_order_value), 2) AS month_revenue
    FROM customer_orders
    GROUP BY cohort_month, months_since_first_purchase
),
cohort_initial_revenue AS (
    SELECT 
        cohort_month,
        month_revenue AS initial_revenue
    FROM cohort_revenue_activity
    WHERE month_number = 0
)
SELECT 
    cra.cohort_month,
    cir.initial_revenue AS cohort_initial_revenue,
    cra.month_number,
    cra.active_customers,
    cra.month_revenue AS retained_revenue,
    ROUND(100.0 * cra.month_revenue / cir.initial_revenue, 2) AS revenue_retention_rate,
    ROUND(cra.month_revenue / cra.active_customers, 2) AS arpu_retained_customers
FROM cohort_revenue_activity cra
JOIN cohort_initial_revenue cir ON cra.cohort_month = cir.cohort_month
ORDER BY cra.cohort_month, cra.month_number;


-- 5B. Revenue Retention Rate (%) Pivot Matrix (Months 0-12)
WITH customer_cohorts AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month,
        DATE(MIN(o.order_purchase_timestamp)) AS first_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
order_payment_totals AS (
    SELECT 
        order_id, 
        ROUND(SUM(payment_value), 2) AS total_order_value
    FROM order_payments
    GROUP BY order_id
),
customer_orders AS (
    SELECT 
        cc.cohort_month,
        cc.customer_unique_id,
        opt.total_order_value,
        PERIOD_DIFF(
            DATE_FORMAT(o.order_purchase_timestamp, '%Y%m'),
            DATE_FORMAT(cc.first_order_date, '%Y%m')
        ) AS months_since_first_purchase
    FROM customer_cohorts cc
    JOIN customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payment_totals opt ON o.order_id = opt.order_id
    WHERE o.order_status = 'delivered'
),
cohort_revenue_activity AS (
    SELECT 
        cohort_month,
        months_since_first_purchase AS month_number,
        ROUND(SUM(total_order_value), 2) AS month_revenue
    FROM customer_orders
    GROUP BY cohort_month, months_since_first_purchase
),
cohort_initial_revenue AS (
    SELECT 
        cohort_month,
        month_revenue AS initial_revenue
    FROM cohort_revenue_activity
    WHERE month_number = 0
),
revenue_matrix AS (
    SELECT 
        cra.cohort_month,
        cir.initial_revenue,
        cra.month_number,
        ROUND(100.0 * cra.month_revenue / cir.initial_revenue, 2) AS rev_retention_rate
    FROM cohort_revenue_activity cra
    JOIN cohort_initial_revenue cir ON cra.cohort_month = cir.cohort_month
)
SELECT 
    cohort_month,
    initial_revenue,
    MAX(CASE WHEN month_number = 0  THEN rev_retention_rate END) AS m0_rev_pct,
    MAX(CASE WHEN month_number = 1  THEN rev_retention_rate END) AS m1_rev_pct,
    MAX(CASE WHEN month_number = 2  THEN rev_retention_rate END) AS m2_rev_pct,
    MAX(CASE WHEN month_number = 3  THEN rev_retention_rate END) AS m3_rev_pct,
    MAX(CASE WHEN month_number = 4  THEN rev_retention_rate END) AS m4_rev_pct,
    MAX(CASE WHEN month_number = 5  THEN rev_retention_rate END) AS m5_rev_pct,
    MAX(CASE WHEN month_number = 6  THEN rev_retention_rate END) AS m6_rev_pct,
    MAX(CASE WHEN month_number = 7  THEN rev_retention_rate END) AS m7_rev_pct,
    MAX(CASE WHEN month_number = 8  THEN rev_retention_rate END) AS m8_rev_pct,
    MAX(CASE WHEN month_number = 9  THEN rev_retention_rate END) AS m9_rev_pct,
    MAX(CASE WHEN month_number = 10 THEN rev_retention_rate END) AS m10_rev_pct,
    MAX(CASE WHEN month_number = 11 THEN rev_retention_rate END) AS m11_rev_pct,
    MAX(CASE WHEN month_number = 12 THEN rev_retention_rate END) AS m12_rev_pct
FROM revenue_matrix
WHERE cohort_month BETWEEN '2017-01' AND '2018-06'
GROUP BY cohort_month, initial_revenue
ORDER BY cohort_month;


-- ==============================================================================
-- SECTION 6: ROLLING 3-MONTH ACTIVE CUSTOMER CALCULATION
-- In retail e-commerce, repurchase cycles often span 60-90 days rather than 30 days.
-- A customer is rolling active in month T if they purchased in months T-2, T-1, or T.
-- ==============================================================================

WITH customer_cohorts AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month,
        DATE(MIN(o.order_purchase_timestamp)) AS first_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    SELECT DISTINCT
        cc.customer_unique_id,
        cc.cohort_month,
        PERIOD_DIFF(
            DATE_FORMAT(o.order_purchase_timestamp, '%Y%m'),
            DATE_FORMAT(cc.first_order_date, '%Y%m')
        ) AS month_number
    FROM customer_cohorts cc
    JOIN customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
-- Generate integer series for month numbers 0 to 12
numbers AS (
    SELECT 0 AS m UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
    UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
    UNION ALL SELECT 12
),
cohort_month_grid AS (
    -- Cartesian grid of cohorts and month offsets
    SELECT cs.cohort_month, cs.cohort_size, n.m AS target_month
    FROM cohort_sizes cs
    CROSS JOIN numbers n
    WHERE cs.cohort_month BETWEEN '2017-01' AND '2018-05'
),
rolling_active_counts AS (
    -- Count customers who ordered in target_month OR target_month-1 OR target_month-2
    SELECT 
        g.cohort_month,
        g.cohort_size,
        g.target_month,
        COUNT(DISTINCT co.customer_unique_id) AS rolling_3m_active_customers
    FROM cohort_month_grid g
    LEFT JOIN customer_orders co 
        ON g.cohort_month = co.cohort_month 
        AND co.month_number BETWEEN GREATEST(0, g.target_month - 2) AND g.target_month
    GROUP BY g.cohort_month, g.cohort_size, g.target_month
)
SELECT 
    cohort_month,
    cohort_size,
    target_month AS month_number,
    rolling_3m_active_customers,
    ROUND(100.0 * rolling_3m_active_customers / cohort_size, 2) AS rolling_3m_retention_rate
FROM rolling_active_counts
WHERE target_month >= 2 -- Meaningful starting after the first 3-month window
ORDER BY cohort_month, target_month;


-- ==============================================================================
-- SECTION 7: PRODUCTION DATABASE VIEW: v_cohort_retention
-- Encapsulates customer and revenue cohort retention for BI dashboards & reporting.
-- ==============================================================================

CREATE OR REPLACE VIEW v_cohort_retention AS
WITH customer_cohorts AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month,
        DATE(MIN(o.order_purchase_timestamp)) AS first_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
order_payment_totals AS (
    SELECT 
        order_id, 
        ROUND(SUM(payment_value), 2) AS total_order_value
    FROM order_payments
    GROUP BY order_id
),
customer_orders AS (
    SELECT 
        cc.cohort_month,
        cc.customer_unique_id,
        o.order_id,
        opt.total_order_value,
        PERIOD_DIFF(
            DATE_FORMAT(o.order_purchase_timestamp, '%Y%m'),
            DATE_FORMAT(cc.first_order_date, '%Y%m')
        ) AS month_number
    FROM customer_cohorts cc
    JOIN customers c ON cc.customer_unique_id = c.customer_unique_id
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payment_totals opt ON o.order_id = opt.order_id
    WHERE o.order_status = 'delivered'
),
cohort_sizes AS (
    SELECT 
        cohort_month, 
        COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
cohort_activity AS (
    SELECT 
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers,
        ROUND(SUM(total_order_value), 2) AS retained_revenue
    FROM customer_orders
    GROUP BY cohort_month, month_number
),
cohort_initial_revenue AS (
    SELECT 
        cohort_month,
        retained_revenue AS initial_revenue
    FROM cohort_activity
    WHERE month_number = 0
)
SELECT 
    ca.cohort_month,
    cs.cohort_size,
    cir.initial_revenue AS cohort_initial_revenue,
    ca.month_number,
    ca.active_customers,
    ROUND(100.0 * ca.active_customers / cs.cohort_size, 2) AS customer_retention_rate,
    ca.retained_revenue,
    ROUND(100.0 * ca.retained_revenue / NULLIF(cir.initial_revenue, 0), 2) AS revenue_retention_rate,
    ROUND(ca.retained_revenue / NULLIF(ca.active_customers, 0), 2) AS arpu_retained
FROM cohort_activity ca
JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
JOIN cohort_initial_revenue cir ON ca.cohort_month = cir.cohort_month;

-- Verification query for the view:
-- SELECT * FROM v_cohort_retention WHERE cohort_month = '2017-01' ORDER BY month_number;
