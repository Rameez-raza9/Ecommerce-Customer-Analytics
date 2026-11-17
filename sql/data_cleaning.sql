-- ==============================================================================
-- PROJECT: E-Commerce Customer Analytics & Retention Intelligence
-- DATABASE: MySQL 8.0+
-- SCRIPT: data_cleaning.sql
-- DESCRIPTION: Comprehensive data quality assessment, anomaly detection,
--              referential integrity auditing, financial reconciliation, and
--              production-grade analytical view creation for the Olist dataset.
-- ==============================================================================

USE ecommerce_analytics;

-- ==============================================================================
-- SECTION 1: TOTAL RECORD COUNTS ACROSS ALL 9 TABLES
-- Purpose: Verify ingestion completeness against Kaggle Olist benchmarks.
-- ==============================================================================
SELECT 'customers' AS table_name, COUNT(*) AS total_rows, '99,441' AS benchmark_rows FROM customers
UNION ALL
SELECT 'orders', COUNT(*), '99,441' FROM orders
UNION ALL
SELECT 'order_items', COUNT(*), '112,650' FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*), '103,886' FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*), '99,224' FROM order_reviews
UNION ALL
SELECT 'products', COUNT(*), '32,951' FROM products
UNION ALL
SELECT 'sellers', COUNT(*), '3,095' FROM sellers
UNION ALL
SELECT 'geolocation', COUNT(*), '1,000,163' FROM geolocation
UNION ALL
SELECT 'product_category_translation', COUNT(*), '71' FROM product_category_translation;

-- ==============================================================================
-- SECTION 2: COMPREHENSIVE NULL & MISSING VALUE AUDIT
-- Purpose: Identify missing values across all critical columns in all tables.
-- ==============================================================================

-- 2.1 Customers Table NULL Audit
SELECT 
    'customers' AS table_name,
    COUNT(*) AS total_records,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS null_customer_unique_id,
    SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_zip_code,
    SUM(CASE WHEN customer_city IS NULL OR TRIM(customer_city) = '' THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN customer_state IS NULL OR TRIM(customer_state) = '' THEN 1 ELSE 0 END) AS null_state
FROM customers;

-- 2.2 Orders Table NULL Audit
-- Note: NULLs in delivery/approval timestamps are normal for non-delivered orders,
-- but unexpected for orders marked as 'delivered'.
SELECT 
    'orders' AS table_name,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS null_order_status,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS null_purchase_time,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS null_approved_at,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS null_carrier_date,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_customer_delivered_date,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS null_estimated_delivery
FROM orders;

-- 2.3 Order Items Table NULL Audit
SELECT 
    'order_items' AS table_name,
    COUNT(*) AS total_items,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) AS null_order_item_id,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS null_seller_id,
    SUM(CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END) AS null_shipping_limit_date,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS null_freight_value
FROM order_items;

-- 2.4 Order Payments Table NULL Audit
SELECT 
    'order_payments' AS table_name,
    COUNT(*) AS total_payments,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN payment_sequential IS NULL THEN 1 ELSE 0 END) AS null_payment_sequential,
    SUM(CASE WHEN payment_type IS NULL OR TRIM(payment_type) = '' THEN 1 ELSE 0 END) AS null_payment_type,
    SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END) AS null_installments,
    SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) AS null_payment_value
FROM order_payments;

-- 2.5 Order Reviews Table NULL Audit
-- Note: Review comment title and message are optional customer feedback fields.
SELECT 
    'order_reviews' AS table_name,
    COUNT(*) AS total_reviews,
    SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END) AS null_review_id,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS null_review_score,
    SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END) AS null_comment_title,
    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS null_comment_message,
    SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END) AS null_creation_date,
    SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END) AS null_answer_timestamp
FROM order_reviews;

-- 2.6 Products Table NULL Audit
SELECT 
    'products' AS table_name,
    COUNT(*) AS total_products,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_category_name,
    SUM(CASE WHEN product_name_length IS NULL THEN 1 ELSE 0 END) AS null_name_len,
    SUM(CASE WHEN product_description_length IS NULL THEN 1 ELSE 0 END) AS null_desc_len,
    SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END) AS null_photos_qty,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS null_weight,
    SUM(CASE WHEN product_length_cm IS NULL OR product_height_cm IS NULL OR product_width_cm IS NULL THEN 1 ELSE 0 END) AS null_dimensions
FROM products;

-- 2.7 Sellers Table NULL Audit
SELECT 
    'sellers' AS table_name,
    COUNT(*) AS total_sellers,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS null_seller_id,
    SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_zip_prefix,
    SUM(CASE WHEN seller_city IS NULL OR TRIM(seller_city) = '' THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN seller_state IS NULL OR TRIM(seller_state) = '' THEN 1 ELSE 0 END) AS null_state
FROM sellers;

-- 2.8 Geolocation Table NULL Audit
SELECT 
    'geolocation' AS table_name,
    COUNT(*) AS total_geo_records,
    SUM(CASE WHEN geolocation_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_zip,
    SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END) AS null_lat,
    SUM(CASE WHEN geolocation_lng IS NULL THEN 1 ELSE 0 END) AS null_lng,
    SUM(CASE WHEN geolocation_city IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN geolocation_state IS NULL THEN 1 ELSE 0 END) AS null_state
FROM geolocation;

-- ==============================================================================
-- SECTION 3: DUPLICATE PRIMARY KEY & GRANULARITY CHECKS
-- Purpose: Verify uniqueness constraints and identify duplicate records.
-- ==============================================================================

-- 3.1 Duplicate Order IDs in orders table (Must return 0 rows)
SELECT 
    order_id, 
    COUNT(*) AS occurrence_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 3.2 Duplicate Order Line Items (Composite PK check: order_id + order_item_id)
SELECT 
    order_id, 
    order_item_id, 
    COUNT(*) AS occurrence_count
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- 3.3 Duplicate Payment Sequence (Composite PK check: order_id + payment_sequential)
SELECT 
    order_id, 
    payment_sequential, 
    COUNT(*) AS occurrence_count
FROM order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

-- 3.4 Duplicate Reviews per Order
-- Check orders receiving multiple review submissions
SELECT 
    order_id, 
    COUNT(*) AS review_count,
    GROUP_CONCAT(review_score ORDER BY review_creation_date) AS review_scores
FROM order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
LIMIT 10;

-- ==============================================================================
-- SECTION 4: REFERENTIAL INTEGRITY - ORDERS WITH NO MATCHING CUSTOMER
-- Purpose: Detect orphan orders lacking customer linkage (Foreign Key Integrity).
-- ==============================================================================
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp
FROM orders o
LEFT JOIN customers c 
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- ==============================================================================
-- SECTION 5: REFERENTIAL INTEGRITY - ORDER ITEMS WITH NO MATCHING ORDER
-- Purpose: Detect orphan items linked to non-existent orders.
-- ==============================================================================
SELECT 
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id
FROM order_items oi
LEFT JOIN orders o 
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- ==============================================================================
-- SECTION 6: INCONSISTENT STATUS & DELIVERY TIMESTAMPS
-- Purpose: Identify state-machine anomalies in the delivery lifecycle.
-- ==============================================================================

-- 6.1 Status is 'delivered' but delivery timestamp to customer is NULL
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- 6.2 Status is NOT 'delivered' but delivery timestamp to customer IS NOT NULL
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM orders
WHERE order_status != 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- 6.3 Delivered to carrier without approval timestamp
SELECT 
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date
FROM orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_approved_at IS NULL;

-- ==============================================================================
-- SECTION 7: COMPREHENSIVE ORPHAN RECORD DETECTION ACROSS ALL ENTITIES
-- Purpose: Comprehensive audit of all entity relationships.
-- ==============================================================================

-- 7.1 Order items with no matching product catalog entry
SELECT 
    oi.order_id,
    oi.order_item_id,
    oi.product_id
FROM order_items oi
LEFT JOIN products p 
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 7.2 Order items with no matching seller entry
SELECT 
    oi.order_id,
    oi.order_item_id,
    oi.seller_id
FROM order_items oi
LEFT JOIN sellers s 
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- 7.3 Order payments with no matching order
SELECT 
    op.order_id,
    op.payment_sequential,
    op.payment_value
FROM order_payments op
LEFT JOIN orders o 
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 7.4 Order reviews with no matching order
SELECT 
    r.review_id,
    r.order_id,
    r.review_score
FROM order_reviews r
LEFT JOIN orders o 
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 7.5 Registered sellers with 0 items sold (inactive sellers)
SELECT 
    COUNT(s.seller_id) AS total_inactive_sellers
FROM sellers s
LEFT JOIN order_items oi 
    ON s.seller_id = oi.seller_id
WHERE oi.seller_id IS NULL;

-- 7.6 Products listed with 0 items sold
SELECT 
    COUNT(p.product_id) AS total_unsold_products
FROM products p
LEFT JOIN order_items oi 
    ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- 7.7 Product categories with no English translation
SELECT 
    p.product_category_name,
    COUNT(p.product_id) AS product_count
FROM products p
LEFT JOIN product_category_translation pct 
    ON p.product_category_name = pct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND pct.product_category_name_english IS NULL
GROUP BY p.product_category_name;

-- ==============================================================================
-- SECTION 8: CHRONOLOGICAL & DATE LOGIC AUDITING
-- Purpose: Check temporal causality: Purchase -> Approval -> Carrier -> Customer Delivery.
-- ==============================================================================

-- 8.1 Orders where approval occurred BEFORE purchase
SELECT 
    order_id,
    order_purchase_timestamp,
    order_approved_at,
    TIMESTAMPDIFF(MINUTE, order_purchase_timestamp, order_approved_at) AS diff_minutes
FROM orders
WHERE order_approved_at < order_purchase_timestamp;

-- 8.2 Orders where carrier dispatch occurred BEFORE order purchase
SELECT 
    order_id,
    order_purchase_timestamp,
    order_delivered_carrier_date
FROM orders
WHERE order_delivered_carrier_date < order_purchase_timestamp;

-- 8.3 Orders where customer delivery occurred BEFORE order purchase
SELECT 
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- 8.4 Orders where customer delivery occurred BEFORE carrier dispatch
SELECT 
    order_id,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM orders
WHERE order_delivered_customer_date < order_delivered_carrier_date;

-- 8.5 On-Time vs. Late Delivery Analysis (Delivered Customer Date vs Estimated Date)
SELECT 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On-Time / Early'
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Late Delivery'
        ELSE 'Pending Delivery / Unknown'
    END AS delivery_performance,
    COUNT(*) AS total_orders,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL), 2) AS percentage_of_delivered,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_delivery_days,
    ROUND(AVG(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date 
                   THEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) 
                   ELSE 0 END), 1) AS avg_delay_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
GROUP BY delivery_performance;

-- ==============================================================================
-- SECTION 9: FINANCIAL SANITY & RECONCILIATION AUDIT
-- Purpose: Detect invalid payment amounts, non-standard installments, and discrepancies.
-- ==============================================================================

-- 9.1 Payments with zero or negative value
SELECT 
    order_id,
    payment_sequential,
    payment_type,
    payment_value
FROM order_payments
WHERE payment_value <= 0;

-- 9.2 Payments with zero or invalid installments
SELECT 
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM order_payments
WHERE payment_installments <= 0;

-- 9.3 Payments with payment_type marked as 'not_defined'
SELECT 
    order_id,
    payment_sequential,
    payment_type,
    payment_value
FROM order_payments
WHERE payment_type = 'not_defined';

-- 9.4 Financial Reconciliation: Order Item Total vs. Payment Value Total
-- Compare (SUM(price) + SUM(freight_value)) against SUM(payment_value) per order
-- Allows a $0.05 rounding threshold.
WITH order_item_totals AS (
    SELECT 
        order_id,
        ROUND(SUM(price + freight_value), 2) AS total_item_cost
    FROM order_items
    GROUP BY order_id
),
order_payment_totals AS (
    SELECT 
        order_id,
        ROUND(SUM(payment_value), 2) AS total_paid
    FROM order_payments
    GROUP BY order_id
)
SELECT 
    oit.order_id,
    oit.total_item_cost,
    opt.total_paid,
    ROUND(opt.total_paid - oit.total_item_cost, 2) AS discrepancy,
    CASE 
        WHEN opt.total_paid > oit.total_item_cost THEN 'Overpaid'
        WHEN opt.total_paid < oit.total_item_cost THEN 'Underpaid'
        ELSE 'Exact Match'
    END AS status
FROM order_item_totals oit
JOIN order_payment_totals opt 
    ON oit.order_id = opt.order_id
WHERE ABS(opt.total_paid - oit.total_item_cost) > 0.05
ORDER BY ABS(opt.total_paid - oit.total_item_cost) DESC
LIMIT 20;

-- ==============================================================================
-- SECTION 10: REVIEW SCORE RANGE & SENTIMENT DISTRIBUTION
-- Purpose: Check for review scores outside 1-5 and assess rating distribution.
-- ==============================================================================

-- 10.1 Out of range review scores (Must return 0 rows)
SELECT 
    review_id,
    order_id,
    review_score
FROM order_reviews
WHERE review_score < 1 OR review_score > 5;

-- 10.2 Review Score Distribution & Response Turnaround Analysis
SELECT 
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM order_reviews), 2) AS percentage_of_total,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, review_creation_date, review_answer_timestamp)), 1) AS avg_response_turnaround_hours,
    SUM(CASE WHEN review_comment_message IS NOT NULL THEN 1 ELSE 0 END) AS reviews_with_text_comment
FROM order_reviews
GROUP BY review_score
ORDER BY review_score DESC;

-- ==============================================================================
-- SECTION 11: PRICING & FREIGHT VALUE SANITY AUDIT
-- Purpose: Detect non-positive prices, negative freight, and summary statistics.
-- ==============================================================================

-- 11.1 Items with zero or negative price
SELECT 
    order_id,
    order_item_id,
    product_id,
    price
FROM order_items
WHERE price <= 0;

-- 11.2 Items with negative freight value
SELECT 
    order_id,
    order_item_id,
    product_id,
    freight_value
FROM order_items
WHERE freight_value < 0;

-- 11.3 Summary Statistics: Price and Freight Distribution
SELECT 
    'price' AS metric,
    MIN(price) AS min_val,
    ROUND(AVG(price), 2) AS avg_val,
    ROUND(STDDEV(price), 2) AS std_val,
    MAX(price) AS max_val
FROM order_items
UNION ALL
SELECT 
    'freight_value',
    MIN(freight_value),
    ROUND(AVG(freight_value), 2),
    ROUND(STDDEV(freight_value), 2),
    MAX(freight_value)
FROM order_items;

-- ==============================================================================
-- SECTION 12: ORDER STATUS DISTRIBUTION & FULFILLMENT FUNNEL
-- Purpose: Quantify operational fulfillment pipeline health.
-- ==============================================================================
SELECT 
    order_status,
    COUNT(*) AS total_orders,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 2) AS pct_of_total_orders,
    ROUND(AVG(CASE 
        WHEN order_delivered_customer_date IS NOT NULL 
        THEN DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) 
        ELSE NULL 
    END), 1) AS avg_delivery_days,
    ROUND(AVG(CASE 
        WHEN order_delivered_customer_date IS NOT NULL 
        THEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) 
        ELSE NULL 
    END), 1) AS avg_delay_days_vs_estimate
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- ==============================================================================
-- SECTION 13: MISSING PRODUCT CATEGORY & TRANSLATION GAP ANALYSIS
-- Purpose: Quantify catalog gaps and revenue impact of untranslated products.
-- ==============================================================================

-- 13.1 Missing category summary in products table
SELECT 
    COUNT(*) AS total_products,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS missing_category_count,
    ROUND(100.0 * SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS missing_category_pct
FROM products;

-- 13.2 Order items and revenue impacted by missing or untranslated categories
SELECT 
    CASE 
        WHEN p.product_category_name IS NULL THEN 'Missing Category (NULL)'
        WHEN pct.product_category_name_english IS NULL THEN 'Category Present but Untranslated'
        ELSE 'Fully Translated Category'
    END AS category_classification,
    COUNT(oi.order_item_id) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS total_gross_merchandise_value,
    ROUND(100.0 * SUM(oi.price) / (SELECT SUM(price) FROM order_items), 2) AS pct_of_total_revenue
FROM order_items oi
LEFT JOIN products p 
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct 
    ON p.product_category_name = pct.product_category_name
GROUP BY category_classification;

-- ==============================================================================
-- SECTION 14: PRODUCTION CLEANED ANALYTICAL VIEW (`v_clean_orders`)
-- Purpose: Unified, production-ready order-item analytical dataset.
-- Granularity: One row per order line item (order_id + order_item_id).
-- Design Note: Payments are aggregated per order_id before joining to prevent
--              Cartesian multiplication of order item revenues.
-- ==============================================================================
CREATE OR REPLACE VIEW v_clean_orders AS
SELECT 
    -- 1. Order Core Identifiers & Status
    o.order_id,
    o.order_status,
    
    -- 2. Temporal Timestamps & Date Dimensions
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    YEAR(o.order_purchase_timestamp) AS purchase_year,
    MONTH(o.order_purchase_timestamp) AS purchase_month,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_year_month,
    QUARTER(o.order_purchase_timestamp) AS purchase_quarter,
    DAYNAME(o.order_purchase_timestamp) AS purchase_day_of_week,
    HOUR(o.order_purchase_timestamp) AS purchase_hour,

    -- 3. Operational & Delivery KPIs
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS delivery_days,
    DATEDIFF(o.order_estimated_delivery_date, o.order_purchase_timestamp) AS estimated_delivery_days,
    DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delivery_delay_days,
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 
        ELSE 0 
    END AS is_late_delivery,
    TIMESTAMPDIFF(HOUR, o.order_purchase_timestamp, o.order_approved_at) AS approval_delay_hours,
    DATEDIFF(o.order_delivered_customer_date, o.order_delivered_carrier_date) AS carrier_transit_days,

    -- 4. Customer Demographics
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,

    -- 5. Order Item Details & Pricing
    oi.order_item_id,
    oi.shipping_limit_date,
    oi.price AS item_price,
    oi.freight_value AS item_freight,
    ROUND(oi.price + oi.freight_value, 2) AS total_item_value,

    -- 6. Product Attributes & Dimensions
    p.product_id,
    COALESCE(p.product_category_name, 'unspecified') AS product_category_name,
    COALESCE(pct.product_category_name_english, p.product_category_name, 'unspecified') AS product_category_name_english,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    ROUND((COALESCE(p.product_length_cm, 0) * COALESCE(p.product_height_cm, 0) * COALESCE(p.product_width_cm, 0)) / 1000.0, 2) AS product_volume_liters,

    -- 7. Seller Demographics & Logistics Classification
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,
    CASE 
        WHEN c.customer_state = s.seller_state THEN 1 
        ELSE 0 
    END AS is_intrastate_delivery,

    -- 8. Aggregated Order-Level Payment Attributes (No Row Multiplication)
    pay.order_total_payment,
    pay.max_payment_installments,
    pay.payment_methods,
    pay.payment_records_count

FROM orders o
INNER JOIN customers c 
    ON o.customer_id = c.customer_id
INNER JOIN order_items oi 
    ON o.order_id = oi.order_id
LEFT JOIN products p 
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct 
    ON p.product_category_name = pct.product_category_name
LEFT JOIN sellers s 
    ON oi.seller_id = s.seller_id
LEFT JOIN (
    SELECT 
        order_id,
        ROUND(SUM(payment_value), 2) AS order_total_payment,
        MAX(payment_installments) AS max_payment_installments,
        COUNT(payment_sequential) AS payment_records_count,
        GROUP_CONCAT(DISTINCT payment_type ORDER BY payment_type SEPARATOR ', ') AS payment_methods
    FROM order_payments
    GROUP BY order_id
) pay 
    ON o.order_id = pay.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
  AND o.order_delivered_customer_date IS NOT NULL;

-- ==============================================================================
-- SECTION 15: PRODUCTION CUSTOMER SUMMARY VIEW (`v_customer_summary`)
-- Purpose: Aggregated customer-level 360 view for RFM segmentation, lifetime
--          value analysis, and retention intelligence.
-- Granularity: One row per customer_unique_id.
-- ==============================================================================
CREATE OR REPLACE VIEW v_customer_summary AS
SELECT 
    c.customer_unique_id,
    MAX(c.customer_city) AS customer_city,
    MAX(c.customer_state) AS customer_state,
    
    -- Frequency & Count Metrics
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_items_purchased,
    
    -- Monetary Spend Metrics
    ROUND(COALESCE(SUM(oi.price), 0.00), 2) AS total_product_revenue,
    ROUND(COALESCE(SUM(oi.freight_value), 0.00), 2) AS total_freight_spend,
    ROUND(COALESCE(SUM(oi.price + oi.freight_value), 0.00), 2) AS total_customer_spend,
    ROUND(COALESCE(SUM(oi.price), 0.00) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS avg_order_value,
    ROUND(COALESCE(AVG(oi.price), 0.00), 2) AS avg_item_price,
    
    -- Temporal & RFM Metrics
    MIN(o.order_purchase_timestamp) AS first_order_date,
    MAX(o.order_purchase_timestamp) AS last_order_date,
    DATEDIFF(MAX(o.order_purchase_timestamp), MIN(o.order_purchase_timestamp)) AS customer_lifetime_days,
    DATEDIFF(
        MAX(ref.max_dataset_timestamp),
        MAX(o.order_purchase_timestamp)
    ) AS recency_days,
    
    -- Retention & Behavioral Indicators
    CASE 
        WHEN COUNT(DISTINCT o.order_id) > 1 THEN 1 
        ELSE 0 
    END AS is_repeat_buyer,
    COUNT(DISTINCT oi.product_id) AS distinct_products_bought,
    COUNT(DISTINCT p.product_category_name) AS distinct_categories_bought

FROM customers c
INNER JOIN orders o 
    ON c.customer_id = o.customer_id
INNER JOIN order_items oi 
    ON o.order_id = oi.order_id
LEFT JOIN products p 
    ON oi.product_id = p.product_id
CROSS JOIN (
    SELECT MAX(order_purchase_timestamp) AS max_dataset_timestamp 
    FROM orders 
    WHERE order_status = 'delivered'
) ref
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_unique_id;

-- ==============================================================================
-- SECTION 16: VERIFICATION & VALIDATION QUERIES FOR ANALYTICAL VIEWS
-- Purpose: Validate views produce clean, expected outputs.
-- ==============================================================================

-- 16.1 Validate row counts in `v_clean_orders` and `v_customer_summary`
SELECT 'v_clean_orders' AS view_name, COUNT(*) AS row_count FROM v_clean_orders
UNION ALL
SELECT 'v_customer_summary', COUNT(*) FROM v_customer_summary;

-- 16.2 Preview top 5 rows from `v_clean_orders`
SELECT 
    order_id,
    order_item_id,
    purchase_year_month,
    product_category_name_english,
    item_price,
    item_freight,
    delivery_days,
    is_late_delivery,
    customer_state,
    seller_state,
    payment_methods
FROM v_clean_orders
LIMIT 5;

-- 16.3 Preview top 5 highest-spending repeat customers from `v_customer_summary`
SELECT 
    customer_unique_id,
    customer_city,
    customer_state,
    total_orders,
    total_items_purchased,
    total_customer_spend,
    avg_order_value,
    recency_days,
    customer_lifetime_days,
    is_repeat_buyer
FROM v_customer_summary
WHERE is_repeat_buyer = 1
ORDER BY total_customer_spend DESC
LIMIT 5;
