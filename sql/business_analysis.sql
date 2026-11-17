-- ==============================================================================
-- E-COMMERCE CUSTOMER ANALYTICS & RETENTION INTELLIGENCE
-- SCRIPT 1: Comprehensive Business Analysis (MySQL 8.0)
-- ==============================================================================
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- Target Engine: MySQL 8.0+
-- Description:
--   Comprehensive business intelligence and performance diagnostics covering:
--     1. Revenue Analysis (Lifetime, Monthly Trends, Quarter, MoM Growth)
--     2. Order & Customer KPIs (Fulfillment, Uniques, AOV, Order Frequency)
--     3. Customer Purchase Behavior (Pareto 80/20, Repeat Intervals, Top Spenders)
--     4. Product & Category Analysis (Category Revenue, AOV, Monthly Trends, Top Volume)
--     5. Geographic Analysis (State GMV, Order Density, Regional AOV, Penetration)
--     6. Delivery & Satisfaction (Transit Lead Times, On-Time SLAs, Review Distribution)
--
-- Features Used:
--   Common Table Expressions (CTEs), Window Functions (SUM() OVER, LAG, NTILE,
--   ROW_NUMBER, DENSE_RANK), CASE Statements, DATE_FORMAT, DATEDIFF, COALESCE.
-- ==============================================================================


-- ==============================================================================
-- PREREQUISITES / SCHEMA CONTEXT: VIEWS SPECIFICATION
-- ==============================================================================
-- The following analytical views are assumed to exist or can be created here.
-- They provide reusable, pre-cleaned foundational representations of orders
-- and customer lifetime summaries.
-- ==============================================================================

-- VIEW 1: v_clean_orders
-- Combines orders, customers, aggregated payment totals, and fulfillment timestamps.
CREATE OR REPLACE VIEW v_clean_orders AS
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    COALESCE(p.total_payment_value, 0.00) AS total_order_value,
    COALESCE(i.item_count, 0) AS total_items,
    COALESCE(i.total_freight_value, 0.00) AS total_freight_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN (
    SELECT order_id, SUM(payment_value) AS total_payment_value
    FROM order_payments
    GROUP BY order_id
) p ON o.order_id = p.order_id
LEFT JOIN (
    SELECT 
        order_id, 
        COUNT(order_item_id) AS item_count,
        SUM(freight_value) AS total_freight_value
    FROM order_items
    GROUP BY order_id
) i ON o.order_id = i.order_id;


-- VIEW 2: v_customer_summary
-- Aggregates customer purchase history to customer_unique_id level.
CREATE OR REPLACE VIEW v_customer_summary AS
SELECT 
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' THEN o.order_id END) AS delivered_orders,
    MIN(o.order_purchase_timestamp) AS first_order_date,
    MAX(o.order_purchase_timestamp) AS last_order_date,
    COALESCE(SUM(CASE WHEN o.order_status = 'delivered' THEN op.payment_value ELSE 0 END), 0.00) AS total_lifetime_spend
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_payments op ON o.order_id = op.order_id
GROUP BY c.customer_unique_id, c.customer_state, c.customer_city;



-- ==============================================================================
-- SECTION 1: REVENUE ANALYSIS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- QUERY 1: Total Revenue from Delivered Orders
-- ------------------------------------------------------------------------------
-- Answers: What is the total recognized revenue and transaction volume
--          from all successfully delivered orders across the platform?
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(DISTINCT o.order_id) AS total_delivered_orders,
    ROUND(SUM(op.payment_value), 2) AS total_revenue,
    ROUND(AVG(op_sum.order_total), 2) AS avg_order_revenue
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
JOIN (
    SELECT order_id, SUM(payment_value) AS order_total
    FROM order_payments
    GROUP BY order_id
) op_sum ON o.order_id = op_sum.order_id
WHERE o.order_status = 'delivered';

-- Interpretation Notes:
-- Delivered orders represent realized Gross Merchandise Value (GMV).
-- Filtering for 'delivered' strictly excludes in-transit, canceled, or
-- unavailable orders to adhere to revenue recognition standards.
-- In Olist, an order may have multiple payment rows (vouchers + credit cards),
-- so SUM(op.payment_value) accurately tallies every settlement split.


-- ------------------------------------------------------------------------------
-- QUERY 2: Monthly Revenue Trend & Cumulative Running Total
-- ------------------------------------------------------------------------------
-- Answers: How has monthly revenue evolved over time, and what is the platform's
--          cumulative revenue growth curve?
-- ------------------------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_year_month,
        COUNT(DISTINCT o.order_id) AS monthly_orders,
        ROUND(SUM(op.payment_value), 2) AS monthly_revenue
    FROM orders o
    JOIN order_payments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
)
SELECT 
    order_year_month,
    monthly_orders,
    monthly_revenue,
    ROUND(AVG(monthly_revenue) OVER (
        ORDER BY order_year_month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3month_avg_revenue,
    ROUND(SUM(monthly_revenue) OVER (
        ORDER BY order_year_month 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS cumulative_running_total_revenue
FROM monthly_revenue
ORDER BY order_year_month ASC;

-- Interpretation Notes:
-- Tracks GMV progression from platform inception (late 2016) through peak 2018.
-- The cumulative running total shows whether commercial growth is linear or exponential.
-- The rolling 3-month moving average smooths single-month promotional spikes
-- (such as Black Friday in November 2017) to expose underlying market trajectory.


-- ------------------------------------------------------------------------------
-- QUERY 3: Revenue by Quarter
-- ------------------------------------------------------------------------------
-- Answers: What is the quarterly revenue performance and order volume breakdown?
-- ------------------------------------------------------------------------------
SELECT 
    YEAR(o.order_purchase_timestamp) AS order_year,
    QUARTER(o.order_purchase_timestamp) AS order_quarter,
    CONCAT(YEAR(o.order_purchase_timestamp), '-Q', QUARTER(o.order_purchase_timestamp)) AS year_quarter,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(op.payment_value), 2) AS total_quarterly_revenue,
    ROUND(SUM(op.payment_value) / COUNT(DISTINCT o.order_id), 2) AS quarterly_aov
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY 
    YEAR(o.order_purchase_timestamp), 
    QUARTER(o.order_purchase_timestamp),
    CONCAT(YEAR(o.order_purchase_timestamp), '-Q', QUARTER(o.order_purchase_timestamp))
ORDER BY order_year ASC, order_quarter ASC;

-- Interpretation Notes:
-- Aggregates monthly noise into strategic fiscal quarters.
-- Shows seasonal cadence across Q1-Q4 and identifies peak sales quarters
-- to align seller recruitment and fulfillment capacity planning.


-- ------------------------------------------------------------------------------
-- QUERY 4: Month-over-Month (MoM) Revenue Growth % Using LAG()
-- ------------------------------------------------------------------------------
-- Answers: What is the rate of monthly revenue expansion or contraction?
-- ------------------------------------------------------------------------------
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_year_month,
        ROUND(SUM(op.payment_value), 2) AS current_month_revenue
    FROM orders o
    JOIN order_payments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
),
mom_calc AS (
    SELECT 
        order_year_month,
        current_month_revenue,
        LAG(current_month_revenue, 1) OVER (ORDER BY order_year_month ASC) AS prev_month_revenue
    FROM monthly_sales
)
SELECT 
    order_year_month,
    current_month_revenue,
    COALESCE(prev_month_revenue, 0.00) AS prev_month_revenue,
    ROUND(current_month_revenue - prev_month_revenue, 2) AS absolute_change,
    CASE 
        WHEN prev_month_revenue IS NULL THEN NULL
        WHEN prev_month_revenue = 0 THEN NULL
        ELSE ROUND(((current_month_revenue - prev_month_revenue) / prev_month_revenue) * 100.0, 2)
    END AS mom_growth_percentage
FROM mom_calc
ORDER BY order_year_month ASC;

-- Interpretation Notes:
-- LAG() accesses the prior row's revenue without self-joins.
-- Positive MoM % confirms sustained organic acquisition or marketing lift.
-- Sharp negative drops typically indicate post-holiday payback periods (e.g. Dec/Jan)
-- or logistics supply constraints.



-- ==============================================================================
-- SECTION 2: ORDER & CUSTOMER KPIS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- QUERY 5: Total Orders, Delivered Orders, and Cancellation Rate
-- ------------------------------------------------------------------------------
-- Answers: What is the overall order fulfillment health, cancellation rate,
--          and breakdown of orders across all lifecycle statuses?
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_orders_placed,
    COUNT(CASE WHEN order_status = 'delivered' THEN 1 END) AS delivered_orders,
    COUNT(CASE WHEN order_status = 'canceled' THEN 1 END) AS canceled_orders,
    COUNT(CASE WHEN order_status = 'unavailable' THEN 1 END) AS unavailable_orders,
    COUNT(CASE WHEN order_status = 'shipped' THEN 1 END) AS in_transit_orders,
    ROUND(100.0 * COUNT(CASE WHEN order_status = 'delivered' THEN 1 END) / COUNT(*), 2) AS delivery_rate_pct,
    ROUND(100.0 * COUNT(CASE WHEN order_status = 'canceled' THEN 1 END) / COUNT(*), 2) AS cancellation_rate_pct,
    ROUND(100.0 * COUNT(CASE WHEN order_status = 'unavailable' THEN 1 END) / COUNT(*), 2) AS unavailable_rate_pct
FROM orders;

-- Interpretation Notes:
-- Cancellation and unavailability rates quantify operational friction.
-- 'Unavailable' orders reflect inventory stockout or merchant fulfillment failure,
-- which severely damages buyer trust and reduces lifetime retention.


-- ------------------------------------------------------------------------------
-- QUERY 6: Total Unique Customers vs. Unique Purchasing Customers
-- ------------------------------------------------------------------------------
-- Answers: How many unique human customers exist in the system, how many
--          placed orders, and how many completed delivered transactions?
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(c.customer_id) AS total_customer_sessions,
    COUNT(DISTINCT c.customer_unique_id) AS total_unique_registered_customers,
    COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN c.customer_unique_id END) AS unique_ordering_customers,
    COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' THEN c.customer_unique_id END) AS unique_delivered_customers,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' THEN c.customer_unique_id END) / 
          COUNT(DISTINCT c.customer_unique_id), 2) AS delivered_conversion_pct
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;

-- Interpretation Notes:
-- In the Olist data architecture, `customer_id` is an ephemeral transaction key,
-- whereas `customer_unique_id` identifies the true physical individual.
-- This query establishes the baseline population of genuine transacting buyers.


-- ------------------------------------------------------------------------------
-- QUERY 7: Average Order Value (AOV) Overall and Monthly Trend
-- ------------------------------------------------------------------------------
-- Answers: What is the platform-wide Average Order Value (AOV) and how does
--          order purchasing power fluctuate month-by-month?
-- ------------------------------------------------------------------------------
-- Part A: Overall Platform AOV
SELECT 
    COUNT(DISTINCT o.order_id) AS total_delivered_orders,
    ROUND(SUM(op.payment_value), 2) AS total_delivered_revenue,
    ROUND(SUM(op.payment_value) / COUNT(DISTINCT o.order_id), 2) AS overall_aov
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered';

-- Part B: Monthly AOV Trend
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_year_month,
    COUNT(DISTINCT o.order_id) AS monthly_delivered_orders,
    ROUND(SUM(op.payment_value), 2) AS monthly_revenue,
    ROUND(SUM(op.payment_value) / COUNT(DISTINCT o.order_id), 2) AS monthly_aov
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY order_year_month ASC;

-- Interpretation Notes:
-- AOV measures average customer spend per transaction.
-- A fluctuating AOV highlights shifts in product category mix (e.g. electronics
-- vs cosmetics) or discount and promotional discounting intensity.


-- ------------------------------------------------------------------------------
-- QUERY 8: Orders per Customer Distribution (Using CTE + GROUP BY Frequency)
-- ------------------------------------------------------------------------------
-- Answers: What is the exact distribution of completed orders per unique customer?
-- ------------------------------------------------------------------------------
WITH customer_order_counts AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS completed_orders
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    completed_orders AS order_frequency,
    COUNT(customer_unique_id) AS customer_count,
    ROUND(100.0 * COUNT(customer_unique_id) / SUM(COUNT(customer_unique_id)) OVER (), 2) AS pct_of_customers
FROM customer_order_counts
GROUP BY completed_orders
ORDER BY completed_orders ASC;

-- Interpretation Notes:
-- Shows the granular drop-off between 1-time, 2-time, and multi-repeat buyers.
-- Reveals whether the marketplace is predominantly a single-purchase acquisition engine
-- or benefits from organic habituation.


-- ------------------------------------------------------------------------------
-- QUERY 9: Single-Purchase vs. Repeat Customer Count and Percentage
-- ------------------------------------------------------------------------------
-- Answers: What proportion of customer base are repeat buyers, and what share
--          of total orders and revenue do repeat buyers generate?
-- ------------------------------------------------------------------------------
WITH customer_aggregates AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(op.payment_value) AS lifetime_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_classification AS (
    SELECT 
        customer_unique_id,
        order_count,
        lifetime_spend,
        CASE 
            WHEN order_count = 1 THEN 'Single-Purchase Customer'
            ELSE 'Repeat Customer'
        END AS customer_retention_type
    FROM customer_aggregates
)
SELECT 
    customer_retention_type,
    COUNT(customer_unique_id) AS customer_count,
    ROUND(100.0 * COUNT(customer_unique_id) / SUM(COUNT(customer_unique_id)) OVER (), 2) AS customer_pct,
    SUM(order_count) AS total_orders_generated,
    ROUND(100.0 * SUM(order_count) / SUM(SUM(order_count)) OVER (), 2) AS orders_pct,
    ROUND(SUM(lifetime_spend), 2) AS total_revenue_generated,
    ROUND(100.0 * SUM(lifetime_spend) / SUM(SUM(lifetime_spend)) OVER (), 2) AS revenue_pct,
    ROUND(AVG(lifetime_spend), 2) AS avg_revenue_per_customer
FROM customer_classification
GROUP BY customer_retention_type;

-- Interpretation Notes:
-- In Olist, ~97% of customers purchase only once, while ~3% repeat.
-- Even a 3% repeat rate provides disproportionate revenue lift and represents
-- the highest-margin segment with zero incremental Customer Acquisition Cost (CAC).



-- ==============================================================================
-- SECTION 3: CUSTOMER PURCHASE BEHAVIOR
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- QUERY 10: Customer Purchase Frequency Distribution (Binned)
-- ------------------------------------------------------------------------------
-- Answers: How do customers segment across order tiers (1, 2, 3-5, 5+ orders),
--          and how much revenue is concentrated in each tier?
-- ------------------------------------------------------------------------------
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(op.payment_value) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
binned_customers AS (
    SELECT 
        customer_unique_id,
        total_orders,
        total_spend,
        CASE 
            WHEN total_orders = 1 THEN '1 order'
            WHEN total_orders = 2 THEN '2 orders'
            WHEN total_orders BETWEEN 3 AND 5 THEN '3-5 orders'
            ELSE '5+ orders'
        END AS frequency_tier,
        CASE 
            WHEN total_orders = 1 THEN 1
            WHEN total_orders = 2 THEN 2
            WHEN total_orders BETWEEN 3 AND 5 THEN 3
            ELSE 4
        END AS tier_sort_order
    FROM customer_orders
)
SELECT 
    frequency_tier,
    COUNT(customer_unique_id) AS customer_count,
    ROUND(100.0 * COUNT(customer_unique_id) / SUM(COUNT(customer_unique_id)) OVER (), 2) AS customer_share_pct,
    SUM(total_orders) AS total_orders_placed,
    ROUND(SUM(total_spend), 2) AS total_tier_revenue,
    ROUND(100.0 * SUM(total_spend) / SUM(SUM(total_spend)) OVER (), 2) AS revenue_share_pct,
    ROUND(AVG(total_spend), 2) AS avg_spend_per_customer
FROM binned_customers
GROUP BY frequency_tier, tier_sort_order
ORDER BY tier_sort_order ASC;

-- Interpretation Notes:
-- Stratifying frequency into discrete commercial tiers guides loyalty tiering.
-- Customers with 3+ orders represent super-users who deserve high-touch VIP support
-- and early access to product launches.


-- ------------------------------------------------------------------------------
-- QUERY 11: Top 10 Customers by Total Revenue (Anonymized)
-- ------------------------------------------------------------------------------
-- Answers: Who are the top 10 most valuable individual customers across the
--          entire platform's transaction history?
-- ------------------------------------------------------------------------------
WITH customer_lifetime_stats AS (
    SELECT 
        c.customer_unique_id,
        c.customer_state,
        c.customer_city,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(op.payment_value), 2) AS total_lifetime_spend,
        MIN(DATE(o.order_purchase_timestamp)) AS first_order_date,
        MAX(DATE(o.order_purchase_timestamp)) AS latest_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, c.customer_state, c.customer_city
),
ranked_customers AS (
    SELECT 
        DENSE_RANK() OVER (ORDER BY total_lifetime_spend DESC) AS spend_rank,
        customer_unique_id,
        customer_state,
        customer_city,
        total_orders,
        total_lifetime_spend,
        ROUND(total_lifetime_spend / total_orders, 2) AS avg_order_value,
        first_order_date,
        latest_order_date
    FROM customer_lifetime_stats
)
SELECT 
    spend_rank,
    customer_unique_id,
    customer_state,
    customer_city,
    total_orders,
    total_lifetime_spend,
    avg_order_value,
    first_order_date,
    latest_order_date
FROM ranked_customers
WHERE spend_rank <= 10
ORDER BY spend_rank ASC;

-- Interpretation Notes:
-- customer_unique_id protects privacy while isolating top spenders.
-- High total lifetime spend in Olist can stem from multiple frequent orders or
-- high-ticket purchases (e.g. computer equipment or commercial office supplies).


-- ------------------------------------------------------------------------------
-- QUERY 12: Revenue Concentration - Pareto Analysis (Top 20% vs. Revenue %)
-- ------------------------------------------------------------------------------
-- Answers: Does the Pareto Principle (80/20 rule) hold? What percentage of total
--          revenue is generated by the top 20% of customers?
-- ------------------------------------------------------------------------------
WITH customer_spend AS (
    SELECT 
        c.customer_unique_id,
        SUM(op.payment_value) AS lifetime_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_quintiles AS (
    SELECT 
        customer_unique_id,
        lifetime_spend,
        NTILE(5) OVER (ORDER BY lifetime_spend DESC) AS spend_quintile -- 1 = Top 20%
    FROM customer_spend
),
quintile_summary AS (
    SELECT 
        spend_quintile,
        CASE spend_quintile
            WHEN 1 THEN 'Top 20% (VIP Spenders)'
            WHEN 2 THEN '2nd Quintile (60% - 80%)'
            WHEN 3 THEN '3rd Quintile (40% - 60%)'
            WHEN 4 THEN '4th Quintile (20% - 40%)'
            WHEN 5 THEN 'Bottom 20% (Lowest Spenders)'
        END AS quintile_segment,
        COUNT(customer_unique_id) AS customer_count,
        SUM(lifetime_spend) AS quintile_revenue
    FROM customer_quintiles
    GROUP BY spend_quintile
)
SELECT 
    spend_quintile,
    quintile_segment,
    customer_count,
    ROUND(100.0 * customer_count / SUM(customer_count) OVER (), 2) AS customer_pct,
    ROUND(quintile_revenue, 2) AS quintile_revenue,
    ROUND(100.0 * quintile_revenue / SUM(quintile_revenue) OVER (), 2) AS revenue_share_pct,
    ROUND(SUM(quintile_revenue) OVER (ORDER BY spend_quintile ASC), 2) AS cumulative_revenue,
    ROUND(100.0 * SUM(quintile_revenue) OVER (ORDER BY spend_quintile ASC) / 
          SUM(quintile_revenue) OVER (), 2) AS cumulative_revenue_pct
FROM quintile_summary
ORDER BY spend_quintile ASC;

-- Interpretation Notes:
-- NTILE(5) partitions the buyer population into 5 equal 20% quintiles.
-- If the top 20% of buyers generate ~55-60% of revenue (typical in retail with low repeat),
-- it confirms significant concentration, though less extreme than SaaS or B2B 80/20 models.


-- ------------------------------------------------------------------------------
-- QUERY 13: Average Days Between Orders for Repeat Customers
-- ------------------------------------------------------------------------------
-- Answers: How many days elapse between consecutive orders for customers
--          who make multiple purchases?
-- ------------------------------------------------------------------------------
WITH customer_order_history AS (
    SELECT 
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        LAG(o.order_purchase_timestamp, 1) OVER (
            PARTITION BY c.customer_unique_id 
            ORDER BY o.order_purchase_timestamp ASC
        ) AS previous_order_timestamp
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
repeat_intervals AS (
    SELECT 
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        previous_order_timestamp,
        DATEDIFF(order_purchase_timestamp, previous_order_timestamp) AS days_since_last_order
    FROM customer_order_history
    WHERE previous_order_timestamp IS NOT NULL
)
SELECT 
    COUNT(DISTINCT customer_unique_id) AS repeat_customers_analyzed,
    COUNT(*) AS total_repeat_transitions,
    ROUND(AVG(days_since_last_order), 1) AS avg_days_between_orders,
    MIN(days_since_last_order) AS min_days_between_orders,
    MAX(days_since_last_order) AS max_days_between_orders
FROM repeat_intervals;

-- Supplementary: Interval Distribution (Days Between Orders)
WITH customer_order_history AS (
    SELECT 
        c.customer_unique_id,
        o.order_purchase_timestamp,
        LAG(o.order_purchase_timestamp, 1) OVER (
            PARTITION BY c.customer_unique_id 
            ORDER BY o.order_purchase_timestamp ASC
        ) AS previous_order_timestamp
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
repeat_intervals AS (
    SELECT 
        DATEDIFF(order_purchase_timestamp, previous_order_timestamp) AS days_since_last_order
    FROM customer_order_history
    WHERE previous_order_timestamp IS NOT NULL
),
binned_intervals AS (
    SELECT 
        CASE 
            WHEN days_since_last_order <= 7 THEN '0-7 days (Immediate reorder)'
            WHEN days_since_last_order <= 30 THEN '8-30 days (1 month)'
            WHEN days_since_last_order <= 90 THEN '31-90 days (Quarterly)'
            WHEN days_since_last_order <= 180 THEN '91-180 days (Half-year)'
            ELSE '180+ days (Long-term)'
        END AS repurchase_window,
        CASE 
            WHEN days_since_last_order <= 7 THEN 1
            WHEN days_since_last_order <= 30 THEN 2
            WHEN days_since_last_order <= 90 THEN 3
            WHEN days_since_last_order <= 180 THEN 4
            ELSE 5
        END AS sort_order
    FROM repeat_intervals
)
SELECT 
    repurchase_window,
    COUNT(*) AS repurchase_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS repurchase_share_pct
FROM binned_intervals
GROUP BY repurchase_window, sort_order
ORDER BY sort_order ASC;

-- Interpretation Notes:
-- Establishing the average repurchase window (e.g. 50-90 days) defines the
-- optimal timing for re-engagement email campaigns and triggers automated
-- "we miss you" churn-prevention incentives before customer intent decays.



-- ==============================================================================
-- SECTION 4: PRODUCT & CATEGORY ANALYSIS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- QUERY 14: Revenue by Product Category (English Names, TOP 15, with % Share)
-- ------------------------------------------------------------------------------
-- Answers: Which product categories produce the most revenue in English translation,
--          and what is their percentage share of platform GMV?
-- ------------------------------------------------------------------------------
WITH category_revenue AS (
    SELECT 
        COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized') AS category_name,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        COUNT(oi.order_item_id) AS items_sold,
        ROUND(SUM(oi.price), 2) AS category_revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized')
),
ranked_categories AS (
    SELECT 
        category_name,
        total_orders,
        items_sold,
        category_revenue,
        ROUND(100.0 * category_revenue / SUM(category_revenue) OVER (), 2) AS revenue_share_pct,
        DENSE_RANK() OVER (ORDER BY category_revenue DESC) AS revenue_rank
    FROM category_revenue
)
SELECT 
    revenue_rank,
    category_name,
    total_orders,
    items_sold,
    category_revenue,
    revenue_share_pct,
    ROUND(SUM(revenue_share_pct) OVER (ORDER BY revenue_rank ASC), 2) AS cumulative_revenue_share_pct
FROM ranked_categories
WHERE revenue_rank <= 15
ORDER BY revenue_rank ASC;

-- Interpretation Notes:
-- Top categories like 'bed_bath_table', 'health_beauty', 'watches_gifts', and
-- 'computers_accessories' represent the core catalog pillars.
-- Monitoring cumulative revenue share of the Top 15 highlights catalog diversification.


-- ------------------------------------------------------------------------------
-- QUERY 15: Average Order Value by Product Category
-- ------------------------------------------------------------------------------
-- Answers: What is the average basket value and average item price for each
--          product category?
-- ------------------------------------------------------------------------------
SELECT 
    COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized') AS category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS total_category_revenue,
    ROUND(AVG(oi.price), 2) AS avg_item_price,
    ROUND(SUM(oi.price) / COUNT(DISTINCT oi.order_id), 2) AS category_aov
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized')
HAVING COUNT(DISTINCT oi.order_id) >= 100 -- Minimum threshold to filter statistical outliers
ORDER BY category_aov DESC
LIMIT 20;

-- Interpretation Notes:
-- Distinguishes high-ticket categories (e.g. 'computers', 'small_appliances')
-- from high-frequency, lower-ticket everyday essentials (e.g. 'telephony').
-- High-AOV categories warrant tailored financing and installment payment options.


-- ------------------------------------------------------------------------------
-- QUERY 16: Number of Orders by Product Category Monthly Trend (Using CTE)
-- ------------------------------------------------------------------------------
-- Answers: How do monthly order volumes fluctuate over time for top categories,
--          and what are their month-over-month growth trajectories?
-- ------------------------------------------------------------------------------
WITH category_monthly AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_year_month,
        COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized') AS category_name,
        COUNT(DISTINCT o.order_id) AS monthly_orders,
        ROUND(SUM(oi.price), 2) AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m'),
        COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized')
),
ranked_category_monthly AS (
    SELECT 
        order_year_month,
        category_name,
        monthly_orders,
        monthly_revenue,
        DENSE_RANK() OVER (
            PARTITION BY order_year_month 
            ORDER BY monthly_orders DESC
        ) AS monthly_rank_by_orders,
        LAG(monthly_orders, 1) OVER (
            PARTITION BY category_name 
            ORDER BY order_year_month ASC
        ) AS prev_month_orders
    FROM category_monthly
)
SELECT 
    order_year_month,
    category_name,
    monthly_orders,
    monthly_rank_by_orders,
    COALESCE(prev_month_orders, 0) AS prev_month_orders,
    CASE 
        WHEN prev_month_orders IS NULL THEN NULL
        WHEN prev_month_orders = 0 THEN NULL
        ELSE ROUND(100.0 * (monthly_orders - prev_month_orders) / prev_month_orders, 2)
    END AS mom_order_growth_pct,
    monthly_revenue
FROM ranked_category_monthly
WHERE monthly_rank_by_orders <= 5
ORDER BY order_year_month DESC, monthly_rank_by_orders ASC;

-- Interpretation Notes:
-- Ranks the top 5 product categories for each calendar month.
-- Reveals seasonal inflection points (e.g. 'toys' surging during Children's Day/Holiday seasons
-- and 'health_beauty' exhibiting steady secular expansion throughout the year).


-- ------------------------------------------------------------------------------
-- QUERY 17: Top 5 Categories by Total Order Count
-- ------------------------------------------------------------------------------
-- Answers: Which 5 product categories generate the highest absolute order volume?
-- ------------------------------------------------------------------------------
WITH category_order_totals AS (
    SELECT 
        COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized') AS category_name,
        COUNT(DISTINCT oi.order_id) AS order_count,
        COUNT(oi.order_item_id) AS items_sold,
        ROUND(SUM(oi.price), 2) AS total_revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized')
),
ranked_totals AS (
    SELECT 
        category_name,
        order_count,
        items_sold,
        total_revenue,
        ROUND(100.0 * order_count / SUM(order_count) OVER (), 2) AS order_share_pct,
        DENSE_RANK() OVER (ORDER BY order_count DESC) AS order_rank
    FROM category_order_totals
)
SELECT 
    order_rank,
    category_name,
    order_count,
    items_sold,
    total_revenue,
    order_share_pct
FROM ranked_totals
WHERE order_rank <= 5
ORDER BY order_rank ASC;

-- Interpretation Notes:
-- The top 5 categories by order volume are the primary customer acquisition gateways.
-- New platform users predominantly make their first purchase in these 5 categories.



-- ==============================================================================
-- SECTION 5: GEOGRAPHIC ANALYSIS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- QUERY 18: Revenue by Customer State (TOP 10)
-- ------------------------------------------------------------------------------
-- Answers: Which Brazilian states produce the highest delivered revenue,
--          and how concentrated is revenue geographically?
-- ------------------------------------------------------------------------------
WITH state_revenue AS (
    SELECT 
        c.customer_state,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(op.payment_value), 2) AS state_revenue
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
),
ranked_states AS (
    SELECT 
        customer_state,
        total_orders,
        state_revenue,
        ROUND(100.0 * state_revenue / SUM(state_revenue) OVER (), 2) AS revenue_share_pct,
        DENSE_RANK() OVER (ORDER BY state_revenue DESC) AS state_revenue_rank
    FROM state_revenue
)
SELECT 
    state_revenue_rank,
    customer_state,
    total_orders,
    state_revenue,
    revenue_share_pct,
    ROUND(SUM(revenue_share_pct) OVER (ORDER BY state_revenue_rank ASC), 2) AS cumulative_revenue_share_pct
FROM ranked_states
WHERE state_revenue_rank <= 10
ORDER BY state_revenue_rank ASC;

-- Interpretation Notes:
-- State SP (São Paulo) typically captures >37% of national GMV alone,
-- with Rio de Janeiro (RJ) and Minas Gerais (MG) bringing Southeast Brazil to over 65%.
-- Marketing and logistics hubs should be prioritized based on cumulative state share.


-- ------------------------------------------------------------------------------
-- QUERY 19: Order Count by Customer State
-- ------------------------------------------------------------------------------
-- Answers: What is the total order volume by customer state and its share of all orders?
-- ------------------------------------------------------------------------------
SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' THEN o.order_id END) AS delivered_orders,
    COUNT(DISTINCT CASE WHEN o.order_status = 'canceled' THEN o.order_id END) AS canceled_orders,
    ROUND(100.0 * COUNT(DISTINCT o.order_id) / SUM(COUNT(DISTINCT o.order_id)) OVER (), 2) AS national_order_share_pct
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC;

-- Interpretation Notes:
-- Demonstrates order density across all 27 Brazilian federative units.
-- Compares relative cancellation volumes by state to detect regions with
-- delivery address validation or courier delivery failure issues.


-- ------------------------------------------------------------------------------
-- QUERY 20: Average Order Value by State
-- ------------------------------------------------------------------------------
-- Answers: Which states exhibit the highest Average Order Value (AOV)?
-- ------------------------------------------------------------------------------
WITH state_aov_calc AS (
    SELECT 
        c.customer_state,
        COUNT(DISTINCT o.order_id) AS total_delivered_orders,
        ROUND(SUM(op.payment_value), 2) AS total_revenue,
        ROUND(SUM(op.payment_value) / COUNT(DISTINCT o.order_id), 2) AS state_aov
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
)
SELECT 
    RANK() OVER (ORDER BY state_aov DESC) AS aov_rank,
    customer_state,
    total_delivered_orders,
    total_revenue,
    state_aov
FROM state_aov_calc
ORDER BY aov_rank ASC;

-- Interpretation Notes:
-- Interestingly, Northern and Northeastern states (such as PB, AC, AP, RO)
-- frequently exhibit higher AOV than São Paulo (SP).
-- This occurs because remote buyers consolidate larger multi-item orders
-- to rationalize higher freight costs and longer transit lead times.


-- ------------------------------------------------------------------------------
-- QUERY 21: Customer Count by State
-- ------------------------------------------------------------------------------
-- Answers: How are unique customers distributed geographically, and what is the
--          average orders placed per customer in each state?
-- ------------------------------------------------------------------------------
SELECT 
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customer_count,
    ROUND(100.0 * COUNT(DISTINCT c.customer_unique_id) / 
          SUM(COUNT(DISTINCT c.customer_unique_id)) OVER (), 2) AS customer_share_pct,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(COUNT(DISTINCT o.order_id) / COUNT(DISTINCT c.customer_unique_id), 3) AS orders_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY unique_customer_count DESC;

-- Interpretation Notes:
-- High customer counts with low orders-per-customer confirm national brand reach
-- but indicate widespread single-order churn across all geographic territories.



-- ==============================================================================
-- SECTION 6: DELIVERY & SATISFACTION
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- QUERY 22: Average Delivery Days (order_purchase to order_delivered)
-- ------------------------------------------------------------------------------
-- Answers: What is the end-to-end delivery lead time across the platform, and how
--          does transit performance vary across customer states?
-- ------------------------------------------------------------------------------
-- Part A: National Delivery Speed Summary
SELECT 
    COUNT(*) AS total_delivered_orders_measured,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_delivery_days,
    ROUND(AVG(DATEDIFF(order_delivered_carrier_date, order_purchase_timestamp)), 1) AS avg_dispatch_days,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_delivered_carrier_date)), 1) AS avg_transit_days,
    ROUND(AVG(DATEDIFF(order_estimated_delivery_date, order_purchase_timestamp)), 1) AS avg_estimated_days,
    MIN(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) AS min_delivery_days,
    MAX(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) AS max_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date >= order_purchase_timestamp;

-- Part B: Average Delivery Days by Customer State (Top 10 Fastest vs Slowest)
SELECT 
    c.customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_actual_delivery_days,
    ROUND(AVG(DATEDIFF(o.order_estimated_delivery_date, o.order_purchase_timestamp)), 1) AS avg_estimated_days,
    ROUND(AVG(DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date)), 1) AS avg_days_ahead_of_schedule
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp IS NOT NULL
  AND o.order_delivered_customer_date >= o.order_purchase_timestamp
GROUP BY c.customer_state
ORDER BY avg_actual_delivery_days ASC;

-- Interpretation Notes:
-- São Paulo enjoys ~8-9 day deliveries, whereas distant states (RR, AP, AM)
-- endure 25-30+ days due to continental transit distances and river logistics.
-- Early estimated delivery dates cushion customer expectations (avg days ahead of schedule > 0).


-- ------------------------------------------------------------------------------
-- QUERY 23: On-Time Delivery Rate (Delivered Before or on Estimated Date)
-- ------------------------------------------------------------------------------
-- Answers: What percentage of delivered orders arrive on or ahead of estimated schedule,
--          and what is the severity of late deliveries?
-- ------------------------------------------------------------------------------
WITH delivery_sla AS (
    SELECT 
        order_id,
        DATE(order_purchase_timestamp) AS purchase_date,
        DATE(order_delivered_customer_date) AS actual_delivery_date,
        DATE(order_estimated_delivery_date) AS estimated_delivery_date,
        CASE 
            WHEN DATE(order_delivered_customer_date) <= DATE(order_estimated_delivery_date) THEN 'On-Time'
            ELSE 'Delayed'
        END AS sla_status,
        DATEDIFF(DATE(order_delivered_customer_date), DATE(order_estimated_delivery_date)) AS delay_days
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)
SELECT 
    COUNT(*) AS total_delivered_orders,
    COUNT(CASE WHEN sla_status = 'On-Time' THEN 1 END) AS on_time_orders,
    COUNT(CASE WHEN sla_status = 'Delayed' THEN 1 END) AS delayed_orders,
    ROUND(100.0 * COUNT(CASE WHEN sla_status = 'On-Time' THEN 1 END) / COUNT(*), 2) AS on_time_delivery_rate_pct,
    ROUND(100.0 * COUNT(CASE WHEN sla_status = 'Delayed' THEN 1 END) / COUNT(*), 2) AS delayed_delivery_rate_pct,
    ROUND(AVG(CASE WHEN sla_status = 'Delayed' THEN delay_days END), 1) AS avg_delay_days_when_late,
    MAX(CASE WHEN sla_status = 'Delayed' THEN delay_days END) AS max_delay_days
FROM delivery_sla;

-- Interpretation Notes:
-- Platform-wide on-time rate typically exceeds 90-92%.
-- The delayed segment (~8%) represents a critical driver of customer churn, refund requests,
-- and low CSAT ratings.


-- ------------------------------------------------------------------------------
-- QUERY 24: Average Review Score Overall and by Product Category
-- ------------------------------------------------------------------------------
-- Answers: What is the overall customer satisfaction rating, and which categories
--          achieve the highest vs lowest review scores?
-- ------------------------------------------------------------------------------
-- Part A: Overall Platform Review Score
SELECT 
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.review_score), 2) AS platform_avg_review_score,
    ROUND(100.0 * COUNT(CASE WHEN r.review_score >= 4 THEN 1 END) / COUNT(*), 2) AS positive_reviews_pct,
    ROUND(100.0 * COUNT(CASE WHEN r.review_score <= 2 THEN 1 END) / COUNT(*), 2) AS negative_reviews_pct
FROM order_reviews r;

-- Part B: Review Scores by Product Category (Top 10 Highest vs Lowest, Min 50 Reviews)
WITH category_reviews AS (
    SELECT 
        COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized') AS category_name,
        COUNT(r.review_score) AS review_count,
        ROUND(AVG(r.review_score), 2) AS avg_review_score,
        ROUND(100.0 * COUNT(CASE WHEN r.review_score = 5 THEN 1 END) / COUNT(r.review_score), 2) AS five_star_pct,
        ROUND(100.0 * COUNT(CASE WHEN r.review_score = 1 THEN 1 END) / COUNT(r.review_score), 2) AS one_star_pct
    FROM order_reviews r
    JOIN orders o ON r.order_id = o.order_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized')
    HAVING COUNT(r.review_score) >= 50
)
SELECT 
    category_name,
    review_count,
    avg_review_score,
    five_star_pct,
    one_star_pct,
    DENSE_RANK() OVER (ORDER BY avg_review_score DESC) AS satisfaction_rank
FROM category_reviews
ORDER BY avg_review_score DESC;

-- Interpretation Notes:
-- Books, music, and decorative arts typically lead in CSAT (>4.25 stars).
-- Complex electronics, furniture, or office supplies with transit damage risks
-- frequently score lower (~3.7-3.9 stars) due to assembly complexity or breakage.


-- ------------------------------------------------------------------------------
-- QUERY 25: Review Score Distribution
-- ------------------------------------------------------------------------------
-- Answers: What is the exact breakdown of customer ratings from 1 to 5 stars,
--          including visual percentage bars?
-- ------------------------------------------------------------------------------
WITH review_distribution AS (
    SELECT 
        review_score,
        COUNT(*) AS review_count
    FROM order_reviews
    GROUP BY review_score
)
SELECT 
    review_score,
    REPEAT('★', review_score) AS star_rating,
    review_count,
    ROUND(100.0 * review_count / SUM(review_count) OVER (), 2) AS pct_of_total_reviews,
    ROUND(SUM(100.0 * review_count / SUM(review_count) OVER ()) OVER (ORDER BY review_score ASC), 2) AS cumulative_pct,
    REPEAT('█', ROUND(100.0 * review_count / SUM(review_count) OVER () / 2)) AS distribution_bar
FROM review_distribution
ORDER BY review_score DESC;

-- Interpretation Notes:
-- E-commerce ratings exhibit a classic polarized bimodal distribution:
-- Over ~55-58% of ratings are 5-stars (delighted customers), while ~11-14% are 1-star
-- (intensely dissatisfied due to non-delivery, extreme transit delays, or broken goods).
-- Middle ratings (2, 3 stars) represent a tiny fraction of feedback.
