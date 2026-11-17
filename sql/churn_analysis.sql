-- ==============================================================================
-- PROJECT: E-Commerce Customer Analytics (Olist Brazilian E-Commerce)
-- SCRIPT:  churn_analysis.sql
-- DIALECT: MySQL 8.0+
-- DESCRIPTION:
--   Complete customer churn, attrition risk, and win-back analysis.
--   Classifies customers by recency threshold relative to maximum dataset timestamp.
--
-- CHURN DEFINITIONS:
--   - Active:    Last purchase within 90 days  (days_since_last_purchase < 90)
--   - At Risk:   Last purchase between 90-180 days (days_since_last_purchase BETWEEN 90 AND 180)
--   - Churned:   Last purchase > 180 days ago (days_since_last_purchase > 180)
--   - Analysis Date: MAX(order_purchase_timestamp) from delivered orders
--
-- BUYER TYPES:
--   - One-Time Buyer:   total_orders = 1
--   - Occasional Buyer: total_orders BETWEEN 2 AND 3
--   - Frequent Buyer:   total_orders > 3
--
-- SECTIONS:
--   1. Core Customer Churn Classification (Base CTE Query)
--   2. Overall Churn Summary (Customer Count, %, Revenue, & Revenue %)
--   3. Churn Rate by Buyer Type (One-Time vs Repeat Buyers)
--   4. Revenue at Risk Deep Dive (90-180 Days Inactive)
--   5. Revenue Lost Deep Dive (>180 Days Inactive)
--   6. Churn by Customer State (Top 10 States with Highest Churn Count)
--   7. Churn Rate Trend by Acquisition Cohort Month
--   8. Churn Rate by RFM Segment (Integration with rfm_results)
--   9. Monthly Churn Rate Calculation (Attrition Inactivity Cohorts)
--  10. Average Revenue & Behavioral Comparison: Churned vs Active Customers
--  11. Permanent Table Creation: churn_results (with PK & Performance Indexes)
--  12. High-Value Churned Customers for Win-Back Campaigns (Revenue > 500 BRL)
-- ==============================================================================

USE olist; -- Adjust database name as appropriate for your local setup

-- ==============================================================================
-- SECTION 1: CORE CUSTOMER CHURN CLASSIFICATION (BASE CTE QUERY)
-- ==============================================================================

-- Step 1: Customer last activity calculation
WITH analysis_date AS (
    SELECT DATE(MAX(order_purchase_timestamp)) AS ref_date FROM orders
),
customer_last_activity AS (
    SELECT 
        c.customer_unique_id,
        MAX(DATE(o.order_purchase_timestamp)) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(op.payment_value) AS total_revenue,
        a.ref_date,
        DATEDIFF(a.ref_date, MAX(DATE(o.order_purchase_timestamp))) AS days_since_last_purchase
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    CROSS JOIN analysis_date a
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, a.ref_date
),
-- Step 2: Classify churn status and buyer type
churn_classification AS (
    SELECT 
        customer_unique_id,
        last_purchase_date,
        total_orders,
        total_revenue,
        ref_date,
        days_since_last_purchase,
        CASE 
            WHEN days_since_last_purchase > 180 THEN 'Churned'
            WHEN days_since_last_purchase BETWEEN 90 AND 180 THEN 'At Risk'
            WHEN days_since_last_purchase < 90 THEN 'Active'
        END AS churn_status,
        CASE
            WHEN total_orders = 1 THEN 'One-Time Buyer'
            WHEN total_orders BETWEEN 2 AND 3 THEN 'Occasional Buyer'
            ELSE 'Frequent Buyer'
        END AS buyer_type
    FROM customer_last_activity
)
SELECT * 
FROM churn_classification 
ORDER BY days_since_last_purchase DESC;


-- ==============================================================================
-- SECTION 2: OVERALL CHURN SUMMARY (COUNT & % OF BASE AND REVENUE)
-- High-level executive KPI summary of customer retention health
-- ==============================================================================

WITH analysis_date AS (
    SELECT DATE(MAX(order_purchase_timestamp)) AS ref_date FROM orders
),
customer_last_activity AS (
    SELECT 
        c.customer_unique_id,
        MAX(DATE(o.order_purchase_timestamp)) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(op.payment_value) AS total_revenue,
        a.ref_date,
        DATEDIFF(a.ref_date, MAX(DATE(o.order_purchase_timestamp))) AS days_since_last_purchase
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    CROSS JOIN analysis_date a
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, a.ref_date
),
churn_classification AS (
    SELECT 
        customer_unique_id,
        total_orders,
        total_revenue,
        days_since_last_purchase,
        CASE 
            WHEN days_since_last_purchase > 180 THEN 'Churned'
            WHEN days_since_last_purchase BETWEEN 90 AND 180 THEN 'At Risk'
            WHEN days_since_last_purchase < 90 THEN 'Active'
        END AS churn_status
    FROM customer_last_activity
)
SELECT 
    churn_status,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers,
    ROUND(SUM(total_revenue), 2) AS total_revenue_brl,
    ROUND(100.0 * SUM(total_revenue) / SUM(SUM(total_revenue)) OVER (), 2) AS pct_of_revenue,
    ROUND(AVG(total_revenue), 2) AS avg_revenue_per_customer,
    ROUND(AVG(days_since_last_purchase), 1) AS avg_days_since_last_purchase
FROM churn_classification
GROUP BY churn_status
ORDER BY 
    CASE churn_status
        WHEN 'Active' THEN 1
        WHEN 'At Risk' THEN 2
        WHEN 'Churned' THEN 3
    END;


-- ==============================================================================
-- SECTION 3: CHURN RATE BY BUYER TYPE (ONE-TIME VS REPEAT BUYERS)
-- Analyzes whether higher order frequency reduces customer churn propensity
-- ==============================================================================

WITH analysis_date AS (
    SELECT DATE(MAX(order_purchase_timestamp)) AS ref_date FROM orders
),
customer_last_activity AS (
    SELECT 
        c.customer_unique_id,
        MAX(DATE(o.order_purchase_timestamp)) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(op.payment_value) AS total_revenue,
        a.ref_date,
        DATEDIFF(a.ref_date, MAX(DATE(o.order_purchase_timestamp))) AS days_since_last_purchase
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    CROSS JOIN analysis_date a
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, a.ref_date
),
churn_classification AS (
    SELECT 
        customer_unique_id,
        total_orders,
        total_revenue,
        CASE 
            WHEN days_since_last_purchase > 180 THEN 'Churned'
            WHEN days_since_last_purchase BETWEEN 90 AND 180 THEN 'At Risk'
            WHEN days_since_last_purchase < 90 THEN 'Active'
        END AS churn_status,
        CASE
            WHEN total_orders = 1 THEN 'One-Time Buyer'
            WHEN total_orders BETWEEN 2 AND 3 THEN 'Occasional Buyer'
            ELSE 'Frequent Buyer'
        END AS buyer_type,
        CASE
            WHEN total_orders = 1 THEN 'One-Time Buyer'
            ELSE 'Repeat Buyer'
        END AS purchase_frequency_group
    FROM customer_last_activity
)
-- 3A. Granular Buyer Type Breakdown
SELECT 
    buyer_type,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn_status = 'Active' THEN 1 ELSE 0 END) AS active_customers,
    SUM(CASE WHEN churn_status = 'At Risk' THEN 1 ELSE 0 END) AS at_risk_customers,
    SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN churn_status = 'At Risk' THEN 1 ELSE 0 END) / COUNT(*), 2) AS at_risk_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN churn_status = 'Active' THEN 1 ELSE 0 END) / COUNT(*), 2) AS active_rate_pct,
    ROUND(SUM(total_revenue), 2) AS total_revenue,
    ROUND(SUM(CASE WHEN churn_status = 'Churned' THEN total_revenue ELSE 0 END), 2) AS churned_revenue
FROM churn_classification
GROUP BY buyer_type
ORDER BY total_customers DESC;

-- 3B. One-Time vs Repeat Buyer Comparison
WITH analysis_date AS (
    SELECT DATE(MAX(order_purchase_timestamp)) AS ref_date FROM orders
),
customer_last_activity AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(op.payment_value) AS total_revenue,
        DATEDIFF(a.ref_date, MAX(DATE(o.order_purchase_timestamp))) AS days_since_last_purchase
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    CROSS JOIN analysis_date a
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, a.ref_date
)
SELECT 
    CASE WHEN total_orders = 1 THEN 'One-Time Buyer (1 order)' ELSE 'Repeat Buyer (2+ orders)' END AS customer_group,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN days_since_last_purchase > 180 THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN days_since_last_purchase > 180 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(SUM(total_revenue), 2) AS total_revenue,
    ROUND(AVG(total_revenue), 2) AS avg_clv
FROM customer_last_activity
GROUP BY CASE WHEN total_orders = 1 THEN 'One-Time Buyer (1 order)' ELSE 'Repeat Buyer (2+ orders)' END;


-- ==============================================================================
-- SECTION 4: REVENUE AT RISK (TOTAL REVENUE FROM AT-RISK CUSTOMERS: 90-180 DAYS)
-- Customers in jeopardy of becoming permanently churned; prime target for re-engagement
-- ==============================================================================

WITH analysis_date AS (
    SELECT DATE(MAX(order_purchase_timestamp)) AS ref_date FROM orders
),
customer_last_activity AS (
    SELECT 
        c.customer_unique_id,
        MAX(DATE(o.order_purchase_timestamp)) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(op.payment_value) AS total_revenue,
        a.ref_date,
        DATEDIFF(a.ref_date, MAX(DATE(o.order_purchase_timestamp))) AS days_since_last_purchase
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    CROSS JOIN analysis_date a
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, a.ref_date
),
churn_classification AS (
    SELECT *,
        CASE 
            WHEN days_since_last_purchase > 180 THEN 'Churned'
            WHEN days_since_last_purchase BETWEEN 90 AND 180 THEN 'At Risk'
            WHEN days_since_last_purchase < 90 THEN 'Active'
        END AS churn_status,
        CASE
            WHEN total_orders = 1 THEN 'One-Time Buyer'
            WHEN total_orders BETWEEN 2 AND 3 THEN 'Occasional Buyer'
            ELSE 'Frequent Buyer'
        END AS buyer_type
    FROM customer_last_activity
)
SELECT 
    buyer_type,
    COUNT(*) AS at_risk_customers,
    ROUND(SUM(total_revenue), 2) AS revenue_at_risk_brl,
    ROUND(AVG(total_revenue), 2) AS avg_revenue_per_at_risk_customer,
    ROUND(AVG(days_since_last_purchase), 1) AS avg_inactivity_days,
    ROUND(100.0 * SUM(total_revenue) / (
        SELECT SUM(total_revenue) FROM churn_classification WHERE churn_status = 'At Risk'
    ), 2) AS pct_of_total_revenue_at_risk
FROM churn_classification
WHERE churn_status = 'At Risk'
GROUP BY buyer_type
ORDER BY revenue_at_risk_brl DESC;


-- ==============================================================================
-- SECTION 5: REVENUE LOST (TOTAL REVENUE FROM CHURNED CUSTOMERS: >180 DAYS)
-- Quantifies the financial magnitude of customer attrition over dataset history
-- ==============================================================================

WITH analysis_date AS (
    SELECT DATE(MAX(order_purchase_timestamp)) AS ref_date FROM orders
),
customer_last_activity AS (
    SELECT 
        c.customer_unique_id,
        MAX(DATE(o.order_purchase_timestamp)) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(op.payment_value) AS total_revenue,
        a.ref_date,
        DATEDIFF(a.ref_date, MAX(DATE(o.order_purchase_timestamp))) AS days_since_last_purchase
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    CROSS JOIN analysis_date a
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, a.ref_date
),
churn_classification AS (
    SELECT *,
        CASE 
            WHEN days_since_last_purchase > 180 THEN 'Churned'
            WHEN days_since_last_purchase BETWEEN 90 AND 180 THEN 'At Risk'
            WHEN days_since_last_purchase < 90 THEN 'Active'
        END AS churn_status,
        CASE
            WHEN total_orders = 1 THEN 'One-Time Buyer'
            WHEN total_orders BETWEEN 2 AND 3 THEN 'Occasional Buyer'
            ELSE 'Frequent Buyer'
        END AS buyer_type
    FROM customer_last_activity
)
SELECT 
    buyer_type,
    COUNT(*) AS churned_customer_count,
    ROUND(SUM(total_revenue), 2) AS total_revenue_lost_brl,
    ROUND(AVG(total_revenue), 2) AS avg_revenue_lost_per_customer,
    ROUND(100.0 * SUM(total_revenue) / (
        SELECT SUM(total_revenue) FROM churn_classification
    ), 2) AS pct_of_all_historical_revenue
FROM churn_classification
WHERE churn_status = 'Churned'
GROUP BY buyer_type
ORDER BY total_revenue_lost_brl DESC;


-- ==============================================================================
-- SECTION 6: CHURN BY CUSTOMER STATE (TOP 10 STATES WITH HIGHEST CHURN COUNT)
-- Identifies geographic concentrations of churn to guide local logistics & marketing
-- ==============================================================================

WITH analysis_date AS (
    SELECT DATE(MAX(order_purchase_timestamp)) AS ref_date FROM orders
),
customer_state_activity AS (
    SELECT 
        c.customer_unique_id,
        MAX(c.customer_state) AS customer_state,
        MAX(DATE(o.order_purchase_timestamp)) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(op.payment_value) AS total_revenue,
        a.ref_date,
        DATEDIFF(a.ref_date, MAX(DATE(o.order_purchase_timestamp))) AS days_since_last_purchase
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    CROSS JOIN analysis_date a
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, a.ref_date
),
state_churn_classification AS (
    SELECT 
        customer_unique_id,
        customer_state,
        total_revenue,
        CASE 
            WHEN days_since_last_purchase > 180 THEN 'Churned'
            WHEN days_since_last_purchase BETWEEN 90 AND 180 THEN 'At Risk'
            WHEN days_since_last_purchase < 90 THEN 'Active'
        END AS churn_status
    FROM customer_state_activity
)
SELECT 
    customer_state,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END) AS churned_customers,
    SUM(CASE WHEN churn_status = 'At Risk' THEN 1 ELSE 0 END) AS at_risk_customers,
    SUM(CASE WHEN churn_status = 'Active' THEN 1 ELSE 0 END) AS active_customers,
    ROUND(100.0 * SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(SUM(CASE WHEN churn_status = 'Churned' THEN total_revenue ELSE 0 END), 2) AS churned_revenue_brl,
    DENSE_RANK() OVER (ORDER BY SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END) DESC) AS rank_by_churn_volume
FROM state_churn_classification
GROUP BY customer_state
ORDER BY churned_customers DESC
LIMIT 10;


-- ==============================================================================
-- SECTION 7: CHURN RATE TREND BY ACQUISITION COHORT MONTH
-- Tracks how customer churn rate evolves based on customer acquisition cohort
-- ==============================================================================

WITH analysis_date AS (
    SELECT DATE(MAX(order_purchase_timestamp)) AS ref_date FROM orders
),
customer_cohort_activity AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month,
        MAX(DATE(o.order_purchase_timestamp)) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(op.payment_value) AS total_revenue,
        a.ref_date,
        DATEDIFF(a.ref_date, MAX(DATE(o.order_purchase_timestamp))) AS days_since_last_purchase
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    CROSS JOIN analysis_date a
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, a.ref_date
),
cohort_churn AS (
    SELECT 
        cohort_month,
        customer_unique_id,
        total_revenue,
        CASE 
            WHEN days_since_last_purchase > 180 THEN 'Churned'
            WHEN days_since_last_purchase BETWEEN 90 AND 180 THEN 'At Risk'
            WHEN days_since_last_purchase < 90 THEN 'Active'
        END AS churn_status
    FROM customer_cohort_activity
)
SELECT 
    cohort_month,
    COUNT(DISTINCT customer_unique_id) AS cohort_size,
    SUM(CASE WHEN churn_status = 'Active' THEN 1 ELSE 0 END) AS active_customers,
    SUM(CASE WHEN churn_status = 'At Risk' THEN 1 ELSE 0 END) AS at_risk_customers,
    SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct,
    ROUND(SUM(total_revenue), 2) AS total_cohort_revenue,
    ROUND(SUM(CASE WHEN churn_status = 'Churned' THEN total_revenue ELSE 0 END), 2) AS churned_revenue_brl
FROM cohort_churn
GROUP BY cohort_month
ORDER BY cohort_month ASC;


-- ==============================================================================
-- SECTION 8: CHURN RATE BY RFM SEGMENT (JOIN WITH rfm_results)
-- Evaluates churn distribution across RFM customer segments
-- ==============================================================================

WITH analysis_date AS (
    SELECT DATE(MAX(order_purchase_timestamp)) AS ref_date FROM orders
),
customer_last_activity AS (
    SELECT 
        c.customer_unique_id,
        MAX(DATE(o.order_purchase_timestamp)) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(op.payment_value) AS total_revenue,
        a.ref_date,
        DATEDIFF(a.ref_date, MAX(DATE(o.order_purchase_timestamp))) AS days_since_last_purchase
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    CROSS JOIN analysis_date a
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, a.ref_date
),
churn_classification AS (
    SELECT 
        customer_unique_id,
        total_orders,
        total_revenue,
        days_since_last_purchase,
        CASE 
            WHEN days_since_last_purchase > 180 THEN 'Churned'
            WHEN days_since_last_purchase BETWEEN 90 AND 180 THEN 'At Risk'
            WHEN days_since_last_purchase < 90 THEN 'Active'
        END AS churn_status
    FROM customer_last_activity
)
SELECT 
    COALESCE(rfm.rfm_segment, 'Unsegmented / Other') AS rfm_segment,
    COUNT(cc.customer_unique_id) AS total_customers,
    SUM(CASE WHEN cc.churn_status = 'Active' THEN 1 ELSE 0 END) AS active_customers,
    SUM(CASE WHEN cc.churn_status = 'At Risk' THEN 1 ELSE 0 END) AS at_risk_customers,
    SUM(CASE WHEN cc.churn_status = 'Churned' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN cc.churn_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(cc.customer_unique_id), 2) AS churn_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN cc.churn_status = 'At Risk' THEN 1 ELSE 0 END) / COUNT(cc.customer_unique_id), 2) AS at_risk_rate_pct,
    ROUND(SUM(cc.total_revenue), 2) AS segment_total_revenue,
    ROUND(AVG(cc.total_revenue), 2) AS avg_monetary_value,
    ROUND(AVG(cc.days_since_last_purchase), 1) AS avg_recency_days
FROM churn_classification cc
LEFT JOIN rfm_results rfm ON cc.customer_unique_id = rfm.customer_unique_id
GROUP BY COALESCE(rfm.rfm_segment, 'Unsegmented / Other')
ORDER BY total_customers DESC;


-- ==============================================================================
-- SECTION 9: MONTHLY CHURN RATE CALCULATION (ATTRITION COHORT EVENT TIME)
-- Identifies the specific calendar month when customers crossed the 180-day
-- inactivity boundary into 'Churned' status.
-- ==============================================================================

WITH analysis_date AS (
    SELECT DATE(MAX(order_purchase_timestamp)) AS ref_date FROM orders
),
customer_churn_events AS (
    SELECT 
        c.customer_unique_id,
        MAX(DATE(o.order_purchase_timestamp)) AS last_purchase_date,
        SUM(op.payment_value) AS customer_revenue,
        a.ref_date,
        -- The customer officially churns on day 181 after their last purchase
        DATE_ADD(MAX(DATE(o.order_purchase_timestamp)), INTERVAL 181 DAY) AS churn_event_date,
        DATE_FORMAT(DATE_ADD(MAX(DATE(o.order_purchase_timestamp)), INTERVAL 181 DAY), '%Y-%m') AS churn_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    CROSS JOIN analysis_date a
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, a.ref_date
    HAVING DATEDIFF(a.ref_date, MAX(DATE(o.order_purchase_timestamp))) > 180
)
SELECT 
    churn_month,
    COUNT(customer_unique_id) AS newly_churned_customers,
    ROUND(SUM(customer_revenue), 2) AS newly_churned_revenue_brl,
    ROUND(AVG(customer_revenue), 2) AS avg_revenue_per_churned_customer,
    -- Running cumulative sum of churned customers over calendar months
    SUM(COUNT(customer_unique_id)) OVER (ORDER BY churn_month ASC) AS cumulative_churned_customers,
    ROUND(SUM(SUM(customer_revenue)) OVER (ORDER BY churn_month ASC), 2) AS cumulative_churned_revenue_brl
FROM customer_churn_events
WHERE churn_event_date <= (SELECT ref_date FROM analysis_date)
GROUP BY churn_month
ORDER BY churn_month ASC;


-- ==============================================================================
-- SECTION 10: AVERAGE REVENUE & BEHAVIORAL COMPARISON: CHURNED VS ACTIVE CUSTOMERS
-- Direct side-by-side behavioral metrics between customer retention tiers
-- ==============================================================================

WITH analysis_date AS (
    SELECT DATE(MAX(order_purchase_timestamp)) AS ref_date FROM orders
),
customer_last_activity AS (
    SELECT 
        c.customer_unique_id,
        MIN(DATE(o.order_purchase_timestamp)) AS first_purchase_date,
        MAX(DATE(o.order_purchase_timestamp)) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(op.payment_value) AS total_revenue,
        a.ref_date,
        DATEDIFF(a.ref_date, MAX(DATE(o.order_purchase_timestamp))) AS days_since_last_purchase,
        DATEDIFF(MAX(DATE(o.order_purchase_timestamp)), MIN(DATE(o.order_purchase_timestamp))) AS customer_lifespan_days
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    CROSS JOIN analysis_date a
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, a.ref_date
),
churn_classification AS (
    SELECT *,
        CASE 
            WHEN days_since_last_purchase > 180 THEN 'Churned'
            WHEN days_since_last_purchase BETWEEN 90 AND 180 THEN 'At Risk'
            WHEN days_since_last_purchase < 90 THEN 'Active'
        END AS churn_status
    FROM customer_last_activity
)
SELECT 
    churn_status,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customer_base,
    ROUND(SUM(total_revenue), 2) AS total_segment_revenue_brl,
    ROUND(AVG(total_revenue), 2) AS avg_clv_revenue,
    ROUND(AVG(total_orders), 3) AS avg_orders_per_customer,
    ROUND(SUM(total_revenue) / SUM(total_orders), 2) AS avg_order_value_aov,
    ROUND(AVG(days_since_last_purchase), 1) AS avg_recency_days,
    ROUND(AVG(customer_lifespan_days), 1) AS avg_lifespan_days
FROM churn_classification
GROUP BY churn_status
ORDER BY 
    CASE churn_status
        WHEN 'Active' THEN 1
        WHEN 'At Risk' THEN 2
        WHEN 'Churned' THEN 3
    END;


-- ==============================================================================
-- SECTION 11: PERMANENT TABLE CREATION: churn_results
-- Creates and indexes the permanent table storing churn classifications
-- ==============================================================================

DROP TABLE IF EXISTS churn_results;

CREATE TABLE churn_results AS
WITH analysis_date AS (
    SELECT DATE(MAX(order_purchase_timestamp)) AS ref_date FROM orders
),
customer_last_activity AS (
    SELECT 
        c.customer_unique_id,
        MAX(c.customer_state) AS customer_state,
        MAX(c.customer_city) AS customer_city,
        MIN(DATE(o.order_purchase_timestamp)) AS first_purchase_date,
        MAX(DATE(o.order_purchase_timestamp)) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(op.payment_value), 2) AS total_revenue,
        a.ref_date,
        DATEDIFF(a.ref_date, MAX(DATE(o.order_purchase_timestamp))) AS days_since_last_purchase
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    CROSS JOIN analysis_date a
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, a.ref_date
)
SELECT 
    customer_unique_id,
    customer_state,
    customer_city,
    first_purchase_date,
    last_purchase_date,
    ref_date,
    days_since_last_purchase,
    total_orders,
    total_revenue,
    CASE 
        WHEN days_since_last_purchase > 180 THEN 'Churned'
        WHEN days_since_last_purchase BETWEEN 90 AND 180 THEN 'At Risk'
        WHEN days_since_last_purchase < 90 THEN 'Active'
    END AS churn_status,
    CASE
        WHEN total_orders = 1 THEN 'One-Time Buyer'
        WHEN total_orders BETWEEN 2 AND 3 THEN 'Occasional Buyer'
        ELSE 'Frequent Buyer'
    END AS buyer_type
FROM customer_last_activity;

-- Add Primary Key & Performance Indexes for downstream analytics & joins
ALTER TABLE churn_results ADD PRIMARY KEY (customer_unique_id);
CREATE INDEX idx_churn_results_status ON churn_results (churn_status);
CREATE INDEX idx_churn_results_buyer_type ON churn_results (buyer_type);
CREATE INDEX idx_churn_results_days_since ON churn_results (days_since_last_purchase);
CREATE INDEX idx_churn_results_state ON churn_results (customer_state);
CREATE INDEX idx_churn_results_revenue ON churn_results (total_revenue);


-- ==============================================================================
-- SECTION 12: HIGH-VALUE CHURNED CUSTOMERS FOR WIN-BACK CAMPAIGNS (REVENUE > 500 BRL)
-- Actionable campaign segmentation for targeted CRM re-engagement initiatives
-- ==============================================================================

-- 12A. High-Value Churned Customer Target List
SELECT 
    customer_unique_id,
    customer_state,
    customer_city,
    total_orders,
    total_revenue,
    last_purchase_date,
    days_since_last_purchase,
    buyer_type,
    CASE 
        WHEN total_revenue >= 1500 THEN 'VIP Win-Back (Tier 1)'
        WHEN total_revenue BETWEEN 1000 AND 1499.99 THEN 'High Priority Win-Back (Tier 2)'
        ELSE 'Standard Win-Back (Tier 3)'
    END AS win_back_tier,
    CASE
        WHEN total_revenue >= 1500 THEN 'Concierge VIP outreach + 25% exclusive voucher + free express shipping'
        WHEN total_revenue BETWEEN 1000 AND 1499.99 THEN 'Personalized email campaign + 20% discount coupon + category recommendations'
        ELSE 'Automated re-engagement email + 15% discount coupon + free shipping'
    END AS recommended_action
FROM churn_results
WHERE churn_status = 'Churned' 
  AND total_revenue > 500.00
ORDER BY total_revenue DESC;

-- 12B. Win-Back Campaign Strategic Summary
-- Summary of opportunity size and addressable recovery revenue
SELECT 
    CASE 
        WHEN total_revenue >= 1500 THEN 'VIP Win-Back (Tier 1: > 1,500 BRL)'
        WHEN total_revenue BETWEEN 1000 AND 1499.99 THEN 'High Priority Win-Back (Tier 2: 1,000 - 1,500 BRL)'
        ELSE 'Standard Win-Back (Tier 3: 500 - 1,000 BRL)'
    END AS win_back_tier,
    COUNT(*) AS target_customer_count,
    ROUND(SUM(total_revenue), 2) AS addressable_lost_revenue_brl,
    ROUND(AVG(total_revenue), 2) AS avg_revenue_per_target,
    ROUND(AVG(days_since_last_purchase), 1) AS avg_days_since_purchase,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM churn_results WHERE churn_status = 'Churned' AND total_revenue > 500), 2) AS pct_of_winback_pool
FROM churn_results
WHERE churn_status = 'Churned' 
  AND total_revenue > 500.00
GROUP BY 
    CASE 
        WHEN total_revenue >= 1500 THEN 'VIP Win-Back (Tier 1: > 1,500 BRL)'
        WHEN total_revenue BETWEEN 1000 AND 1499.99 THEN 'High Priority Win-Back (Tier 2: 1,000 - 1,500 BRL)'
        ELSE 'Standard Win-Back (Tier 3: 500 - 1,000 BRL)'
    END
ORDER BY addressable_lost_revenue_brl DESC;
