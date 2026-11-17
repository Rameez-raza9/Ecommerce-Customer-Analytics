-- ==============================================================================
-- E-COMMERCE CUSTOMER ANALYTICS & RETENTION INTELLIGENCE
-- SCRIPT 2: RFM Customer Segmentation & Cohort Profiling (MySQL 8.0)
-- ==============================================================================
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- Target Engine: MySQL 8.0+
-- Purpose:
--   Recency, Frequency, Monetary (RFM) Segmentation and Lifecycle Profiling.
--   Classifies customers into actionable behavioral cohorts to drive personalized
--   marketing, retention optimization, and customer lifetime value (CLV) growth.
--
-- Methodology:
--   - Recency (R): Days since customer's most recent delivered order relative
--                  to dataset analysis reference date (MAX purchase date).
--   - Frequency (F): Total distinct delivered orders placed by customer.
--   - Monetary (M): Total lifetime payment value from delivered orders.
--   - Scoring: Quintile division (1 to 5) using NTILE(5) window functions.
--              R Score: 5 = Most recent (lowest recency_days), 1 = Oldest.
--              F Score: 5 = Most frequent, 1 = Least frequent.
--              M Score: 5 = Highest spend, 1 = Lowest spend.
--   - Segments: Champions, Loyal Customers, Potential Loyalists, New Customers,
--               Promising, At Risk, Cannot Lose Them, Lost Customers, Hibernating.
-- ==============================================================================


-- ==============================================================================
-- CORE PIPELINE: RFM SEGMENTATION CTE
-- ==============================================================================
-- This standalone multi-step CTE performs the complete end-to-end transformation
-- from raw transactional logs to scored and labeled customer segments.
-- ==============================================================================

-- Step 1: Set reference date (Dynamically determined from latest order timestamp)
WITH reference_date AS (
    SELECT DATE(MAX(order_purchase_timestamp)) AS ref_date 
    FROM orders
),

-- Step 2: Calculate raw RFM metrics per unique customer
rfm_raw AS (
    SELECT 
        c.customer_unique_id,
        DATEDIFF(rd.ref_date, DATE(MAX(o.order_purchase_timestamp))) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(op.payment_value), 2) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    CROSS JOIN reference_date rd
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, rd.ref_date
),

-- Step 3: Score each dimension 1-5 (5 = Best performance tier)
-- Note: Recency is ordered DESC so that lowest recency_days receives score 5.
rfm_scores AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score, -- Lowest days -> Top quintile (5)
        NTILE(5) OVER (ORDER BY frequency ASC)    AS f_score, -- Highest orders -> Top quintile (5)
        NTILE(5) OVER (ORDER BY monetary ASC)     AS m_score  -- Highest spend  -> Top quintile (5)
    FROM rfm_raw
),

-- Step 4: Combine dimensional scores into composite string & total numeric score
rfm_combined AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CONCAT(r_score, f_score, m_score) AS rfm_string,
        (r_score + f_score + m_score)      AS rfm_total_score
    FROM rfm_scores
),

-- Step 5: Assign business segment labels based on behavioral rules
rfm_segmented AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        rfm_string,
        rfm_total_score,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 3 AND f_score <= 2 THEN 'Potential Loyalists'
            WHEN r_score >= 4 AND f_score <= 1 THEN 'New Customers'
            WHEN r_score >= 3 AND f_score >= 2 AND m_score >= 2 THEN 'Promising'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 2 THEN 'Cannot Lose Them'
            WHEN r_score <= 1 AND f_score <= 1 THEN 'Lost Customers'
            ELSE 'Hibernating'
        END AS customer_segment
    FROM rfm_combined
)

-- Final Output: Scored customer records ordered by total RFM score
SELECT 
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_string,
    rfm_total_score,
    customer_segment
FROM rfm_segmented 
ORDER BY rfm_total_score DESC, monetary DESC;



-- ==============================================================================
-- STEP 6: MATERIALIZING RFM SEGMENTS INTO A PERMANENT TABLE
-- ==============================================================================
-- Creating a physical table avoids re-computing the multi-window CTE on large
-- datasets, unlocking blazing-fast interactive reporting in Power BI, Tableau,
-- or Python notebooks.
-- ==============================================================================

-- Drop existing table if refreshing dataset
DROP TABLE IF EXISTS rfm_results;

-- Create permanent results table directly from the CTE pipeline
CREATE TABLE rfm_results AS
WITH reference_date AS (
    SELECT DATE(MAX(order_purchase_timestamp)) AS ref_date 
    FROM orders
),
rfm_raw AS (
    SELECT 
        c.customer_unique_id,
        DATEDIFF(rd.ref_date, DATE(MAX(o.order_purchase_timestamp))) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(op.payment_value), 2) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    CROSS JOIN reference_date rd
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, rd.ref_date
),
rfm_scores AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)    AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)     AS m_score
    FROM rfm_raw
),
rfm_combined AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CONCAT(r_score, f_score, m_score) AS rfm_string,
        (r_score + f_score + m_score)      AS rfm_total_score
    FROM rfm_scores
),
rfm_segmented AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        rfm_string,
        rfm_total_score,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 3 AND f_score <= 2 THEN 'Potential Loyalists'
            WHEN r_score >= 4 AND f_score <= 1 THEN 'New Customers'
            WHEN r_score >= 3 AND f_score >= 2 AND m_score >= 2 THEN 'Promising'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 2 THEN 'Cannot Lose Them'
            WHEN r_score <= 1 AND f_score <= 1 THEN 'Lost Customers'
            ELSE 'Hibernating'
        END AS customer_segment
    FROM rfm_combined
)
SELECT * FROM rfm_segmented;

-- Add performance indexes for downstream filtering and aggregations
ALTER TABLE rfm_results MODIFY customer_unique_id VARCHAR(64) NOT NULL;
ALTER TABLE rfm_results ADD PRIMARY KEY (customer_unique_id);
ALTER TABLE rfm_results ADD INDEX idx_rfm_segment (customer_segment);
ALTER TABLE rfm_results ADD INDEX idx_rfm_scores (r_score, f_score, m_score);
ALTER TABLE rfm_results ADD INDEX idx_rfm_total_score (rfm_total_score);



-- ==============================================================================
-- POST-SEGMENTATION ANALYTICAL QUERIES
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- QUERY 1: Segment Summary KPI Dashboard
-- ------------------------------------------------------------------------------
-- Answers: What are the key performance metrics (Customer Count, Avg Recency,
--          Avg Frequency, Avg Monetary Spend, Total Revenue) across each segment?
-- ------------------------------------------------------------------------------
SELECT 
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(recency_days), 1) AS avg_recency_days,
    ROUND(MIN(recency_days), 0) AS min_recency_days,
    ROUND(MAX(recency_days), 0) AS max_recency_days,
    ROUND(AVG(frequency), 2)    AS avg_frequency_orders,
    ROUND(AVG(monetary), 2)     AS avg_monetary_spend,
    ROUND(SUM(monetary), 2)     AS total_segment_revenue,
    ROUND(AVG(rfm_total_score), 2) AS avg_rfm_score
FROM rfm_results
GROUP BY customer_segment
ORDER BY total_segment_revenue DESC;

-- Interpretation Notes:
-- Provides executive benchmark metrics for each customer cohort.
-- Note how 'Champions' combine low recency with elevated average monetary spend,
-- while 'Lost Customers' and 'Hibernating' represent high-recency lapsed accounts.


-- ------------------------------------------------------------------------------
-- QUERY 2: Revenue Contribution % by Segment
-- ------------------------------------------------------------------------------
-- Answers: What percentage of total platform Gross Merchandise Value (GMV)
--          is generated by each customer segment?
-- ------------------------------------------------------------------------------
WITH segment_revenue AS (
    SELECT 
        customer_segment,
        COUNT(*) AS customer_count,
        SUM(monetary) AS segment_revenue
    FROM rfm_results
    GROUP BY customer_segment
)
SELECT 
    customer_segment,
    customer_count,
    ROUND(segment_revenue, 2) AS total_segment_revenue,
    ROUND(100.0 * segment_revenue / SUM(segment_revenue) OVER (), 2) AS revenue_share_pct,
    ROUND(SUM(segment_revenue) OVER (ORDER BY segment_revenue DESC), 2) AS cumulative_revenue,
    ROUND(100.0 * SUM(segment_revenue) OVER (ORDER BY segment_revenue DESC) / 
          SUM(segment_revenue) OVER (), 2) AS cumulative_revenue_share_pct,
    ROUND(segment_revenue / customer_count, 2) AS revenue_per_customer
FROM segment_revenue
ORDER BY total_segment_revenue DESC;

-- Interpretation Notes:
-- Quantifies the financial concentration across segments.
-- Segments contributing the highest percentage of revenue warrant disproportionate
-- retention budget allocation, while lower-revenue segments should be targeted with
-- automated low-cost programmatic campaigns.


-- ------------------------------------------------------------------------------
-- QUERY 3: Permanent Table Status Verification
-- ------------------------------------------------------------------------------
-- Answers: Confirms the materialized table row count, schema integrity, and
--          storage characteristics.
-- ------------------------------------------------------------------------------
SELECT 
    'rfm_results' AS table_name,
    COUNT(*) AS total_segmented_customers,
    COUNT(DISTINCT customer_unique_id) AS distinct_unique_customers,
    COUNT(DISTINCT customer_segment) AS unique_segments_assigned,
    MIN(recency_days) AS min_recency_observed,
    MAX(recency_days) AS max_recency_observed,
    ROUND(SUM(monetary), 2) AS total_materialized_revenue
FROM rfm_results;

-- Interpretation Notes:
-- Validates that every unique customer in the delivered orders dataset was successfully
-- assigned a valid segment without NULL values or duplicate keys.


-- ------------------------------------------------------------------------------
-- QUERY 4: Segment Distribution with Percentage & Visual Bar Chart
-- ------------------------------------------------------------------------------
-- Answers: What is the distribution and headcount share of each customer segment
--          across the active customer base?
-- ------------------------------------------------------------------------------
WITH segment_headcount AS (
    SELECT 
        customer_segment,
        COUNT(*) AS customer_count,
        ROUND(AVG(rfm_total_score), 2) AS avg_rfm_score
    FROM rfm_results
    GROUP BY customer_segment
)
SELECT 
    customer_segment,
    customer_count,
    ROUND(100.0 * customer_count / SUM(customer_count) OVER (), 2) AS customer_share_pct,
    avg_rfm_score,
    REPEAT('█', ROUND(100.0 * customer_count / SUM(customer_count) OVER () / 2)) AS distribution_visual_bar
FROM segment_headcount
ORDER BY customer_count DESC;

-- Interpretation Notes:
-- Identifies the size of each lifecycle pool.
-- A high proportion of 'Potential Loyalists' or 'Promising' buyers represents an enormous
-- commercial opportunity to nurture buyers into repeat 'Loyal Customers' or 'Champions'
-- through systematic post-purchase email onboarding flows.


-- ------------------------------------------------------------------------------
-- QUERY 5: Top 20 Customers in the "Champions" Segment
-- ------------------------------------------------------------------------------
-- Answers: Who are the top 20 most valuable, high-affinity customers in the
--          Champions segment to target for executive VIP concierge outreach?
-- ------------------------------------------------------------------------------
SELECT 
    ROW_NUMBER() OVER (ORDER BY monetary DESC, frequency DESC, recency_days ASC) AS vip_rank,
    customer_unique_id,
    recency_days,
    frequency,
    monetary AS total_lifetime_spend,
    rfm_string,
    rfm_total_score,
    customer_segment
FROM rfm_results
WHERE customer_segment = 'Champions'
ORDER BY monetary DESC, frequency DESC, recency_days ASC
LIMIT 20;

-- Interpretation Notes:
-- The Champions cohort represents the company's highest-value asset.
-- These 20 individuals have purchased recently, placed multiple orders, and spent
-- substantial capital. They should be protected from negative support experiences,
-- enrolled in priority shipping programs, and sent personalized thank-you gifts.



-- ==============================================================================
-- SECTION 7: STRATEGIC ACTION MATRIX & ACTIVATION PLAYBOOK
-- ==============================================================================
-- Maps each segment to concrete marketing objectives, channels, and activation offers.
-- ==============================================================================
SELECT 
    customer_segment,
    customer_count,
    pct_share,
    strategic_objective,
    recommended_activation_offer,
    marketing_channel
FROM (
    SELECT 
        customer_segment,
        COUNT(*) AS customer_count,
        CONCAT(ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1), '%') AS pct_share,
        CASE customer_segment
            WHEN 'Champions' 
                THEN 'Reward & Retain: Exclusive perks, VIP status, early access to new lines.'
            WHEN 'Loyal Customers' 
                THEN 'Increase Share of Wallet: Loyalty points, cross-sell premium categories.'
            WHEN 'Potential Loyalists' 
                THEN 'Accelerate Repurchase: Free shipping on next order, bundle incentives.'
            WHEN 'New Customers' 
                THEN 'Onboarding & Trust: Welcome drip series, review request, 10% next-order coupon.'
            WHEN 'Promising' 
                THEN 'Build Affinity: Personalized category recommendations, limited-time promos.'
            WHEN 'At Risk' 
                THEN 'Reactivation & Win-Back: Personalized "We Miss You" offer, re-engagement discount.'
            WHEN 'Cannot Lose Them' 
                THEN 'Urgent Retention: Aggressive discounts, concierge outreach, churn surveys.'
            WHEN 'Hibernating' 
                THEN 'Low-Cost Reactivation: Automated seasonal clearance emails, push notifications.'
            WHEN 'Lost Customers' 
                THEN 'Sunset / Remarketing: Paid social retargeting during Black Friday; minimize direct spend.'
            ELSE 'Standard Engagement'
        END AS strategic_objective,
        CASE customer_segment
            WHEN 'Champions'          THEN 'Exclusive VIP Club invitation + 15% anniversary gift code'
            WHEN 'Loyal Customers'    THEN 'Free Priority Express Shipping on all orders for 60 days'
            WHEN 'Potential Loyalists' THEN 'Buy One, Get 20% Off complementary category cross-sell'
            WHEN 'New Customers'      THEN '10% Welcome Back voucher valid within 30 days of 1st delivery'
            WHEN 'Promising'          THEN '$15 credit towards any purchase over $100'
            WHEN 'At Risk'            THEN '20% Win-Back reactivation voucher with urgency countdown'
            WHEN 'Cannot Lose Them'   THEN '25% deep discount code + dedicated customer support hotline'
            WHEN 'Hibernating'        THEN 'Annual semi-clearance promotion newsletter'
            WHEN 'Lost Customers'     THEN 'High-discount clearance catalog (Paid Retargeting Ad only)'
            ELSE 'Standard newsletter'
        END AS recommended_activation_offer,
        CASE customer_segment
            WHEN 'Champions'          THEN 'SMS / Dedicated Email / Handwritten Note'
            WHEN 'Loyal Customers'    THEN 'Personalized Email + Mobile App Push Notification'
            WHEN 'Potential Loyalists' THEN 'Post-Purchase Email Trigger (Day 14)'
            WHEN 'New Customers'      THEN 'Automated Welcome Onboarding Email Drip'
            WHEN 'Promising'          THEN 'Category Email Recommendation'
            WHEN 'At Risk'            THEN 'Multi-step Win-Back Email Sequence (Day 45, 60, 90)'
            WHEN 'Cannot Lose Them'   THEN 'Executive Email + WhatsApp / Direct Outreach'
            WHEN 'Hibernating'        THEN 'Bi-monthly Automated Promotional Digest'
            WHEN 'Lost Customers'     THEN 'Meta / Google Remarketing Audience Sync'
            ELSE 'Email'
        END AS marketing_channel,
        CASE customer_segment
            WHEN 'Champions'          THEN 1
            WHEN 'Loyal Customers'    THEN 2
            WHEN 'Potential Loyalists' THEN 3
            WHEN 'New Customers'      THEN 4
            WHEN 'Promising'          THEN 5
            WHEN 'At Risk'            THEN 6
            WHEN 'Cannot Lose Them'   THEN 7
            WHEN 'Hibernating'        THEN 8
            WHEN 'Lost Customers'     THEN 9
            ELSE 10
        END AS priority_order
    FROM rfm_results
    GROUP BY customer_segment
) action_plan
ORDER BY priority_order ASC;
