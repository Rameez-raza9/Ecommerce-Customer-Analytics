-- ==============================================================================
-- PROJECT: E-Commerce Customer Analytics & Retention Intelligence
-- DATABASE: MySQL 8.0+
-- SCRIPT: database_setup.sql
-- DESCRIPTION: Complete schema definition, indexing strategy, foreign key
--              constraints, and high-performance LOAD DATA INFILE ingestion
--              pipeline for the Brazilian Olist E-Commerce dataset.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- CONFIGURATION & PREREQUISITES
-- ------------------------------------------------------------------------------
-- In MySQL 8.0, loading local data requires `local_infile` to be enabled on both
-- server and client. Run this command once with administrative privileges:
--     SET GLOBAL local_infile = 1;
--
-- When connecting from MySQL CLI or Workbench, ensure local file loading is allowed:
--     mysql --local-infile=1 -u <username> -p
--
-- Windows File Path Note:
-- MySQL requires forward slashes (/) or escaped double backslashes (\\) in file paths.
-- Example: 'C:/Users/ramee/Downloads/e commerce/Ecommerce-Customer-Analytics/data/olist_customers_dataset.csv'
-- Adjust the base path below if your files are located in a different directory.
-- ------------------------------------------------------------------------------

-- ==============================================================================
-- STEP 1: DATABASE INITIALIZATION
-- ==============================================================================
CREATE DATABASE IF NOT EXISTS ecommerce_analytics
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE ecommerce_analytics;

-- ==============================================================================
-- STEP 2: SAFE TEARDOWN (Drop existing tables respecting dependency order)
-- ==============================================================================
-- Disable foreign key checks during teardown to avoid dependency constraint violations
SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS v_customer_summary;
DROP VIEW IF EXISTS v_clean_orders;

DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS geolocation;
DROP TABLE IF EXISTS product_category_translation;

SET FOREIGN_KEY_CHECKS = 1;

-- ==============================================================================
-- STEP 3: DDL - TABLE DEFINITIONS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. CUSTOMERS TABLE
-- Maps order-level customer identifier to the customer's permanent unique identity.
-- customer_id: Unique per transaction / order session.
-- customer_unique_id: Persistent identity used for customer retention and RFM.
-- ------------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id                 VARCHAR(50)     NOT NULL,
    customer_unique_id          VARCHAR(50)     NOT NULL,
    customer_zip_code_prefix    VARCHAR(10)     NOT NULL,
    customer_city               VARCHAR(100)    NOT NULL,
    customer_state              VARCHAR(10)     NOT NULL,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 2. PRODUCT CATEGORY TRANSLATION TABLE
-- Translates Brazilian Portuguese category names to English.
-- ------------------------------------------------------------------------------
CREATE TABLE product_category_translation (
    product_category_name           VARCHAR(100)    NOT NULL,
    product_category_name_english   VARCHAR(100)    NOT NULL,
    CONSTRAINT pk_product_cat_trans PRIMARY KEY (product_category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 3. PRODUCTS TABLE
-- Dimension table containing product catalog specifications and dimensions.
-- ------------------------------------------------------------------------------
CREATE TABLE products (
    product_id                  VARCHAR(50)     NOT NULL,
    product_category_name       VARCHAR(100)    NULL,
    product_name_length         INT             NULL,
    product_description_length  INT             NULL,
    product_photos_qty          INT             NULL,
    product_weight_g            DECIMAL(10,2)   NULL,
    product_length_cm           DECIMAL(10,2)   NULL,
    product_height_cm           DECIMAL(10,2)   NULL,
    product_width_cm            DECIMAL(10,2)   NULL,
    CONSTRAINT pk_products PRIMARY KEY (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 4. SELLERS TABLE
-- Dimension table containing merchant identity and geographical location.
-- ------------------------------------------------------------------------------
CREATE TABLE sellers (
    seller_id                   VARCHAR(50)     NOT NULL,
    seller_zip_code_prefix      VARCHAR(10)     NOT NULL,
    seller_city                 VARCHAR(100)    NOT NULL,
    seller_state                VARCHAR(10)     NOT NULL,
    CONSTRAINT pk_sellers PRIMARY KEY (seller_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 5. GEOLOCATION TABLE
-- Geographic coordinates (latitude/longitude) mapped to Brazilian postal codes.
-- Contains multiple coordinate entries per postal code prefix; surrogate PK used.
-- ------------------------------------------------------------------------------
CREATE TABLE geolocation (
    geolocation_id              BIGINT AUTO_INCREMENT   NOT NULL,
    geolocation_zip_code_prefix VARCHAR(10)             NOT NULL,
    geolocation_lat             DECIMAL(10,6)           NOT NULL,
    geolocation_lng             DECIMAL(10,6)           NOT NULL,
    geolocation_city            VARCHAR(100)            NOT NULL,
    geolocation_state           VARCHAR(10)             NOT NULL,
    CONSTRAINT pk_geolocation PRIMARY KEY (geolocation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 6. ORDERS TABLE
-- Core transactional entity capturing the order lifecycle from checkout to delivery.
-- ------------------------------------------------------------------------------
CREATE TABLE orders (
    order_id                        VARCHAR(50)     NOT NULL,
    customer_id                     VARCHAR(50)     NOT NULL,
    order_status                    VARCHAR(50)     NOT NULL,
    order_purchase_timestamp        DATETIME        NOT NULL,
    order_approved_at               DATETIME        NULL,
    order_delivered_carrier_date    DATETIME        NULL,
    order_delivered_customer_date   DATETIME        NULL,
    order_estimated_delivery_date   DATETIME        NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customers FOREIGN KEY (customer_id) 
        REFERENCES customers (customer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 7. ORDER ITEMS TABLE
-- Granular line-item details for each order, linking products, sellers, and pricing.
-- Composite Primary Key: (order_id, order_item_id)
-- ------------------------------------------------------------------------------
CREATE TABLE order_items (
    order_id                VARCHAR(50)     NOT NULL,
    order_item_id           INT             NOT NULL,
    product_id              VARCHAR(50)     NOT NULL,
    seller_id               VARCHAR(50)     NOT NULL,
    shipping_limit_date     DATETIME        NOT NULL,
    price                   DECIMAL(10,2)   NOT NULL,
    freight_value           DECIMAL(10,2)   NOT NULL,
    CONSTRAINT pk_order_items PRIMARY KEY (order_id, order_item_id),
    CONSTRAINT fk_order_items_orders FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_products FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_sellers FOREIGN KEY (seller_id)
        REFERENCES sellers (seller_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 8. ORDER PAYMENTS TABLE
-- Captures financial transactions per order, supporting split tenders and installments.
-- Composite Primary Key: (order_id, payment_sequential)
-- ------------------------------------------------------------------------------
CREATE TABLE order_payments (
    order_id                VARCHAR(50)     NOT NULL,
    payment_sequential      INT             NOT NULL,
    payment_type            VARCHAR(50)     NOT NULL,
    payment_installments    INT             NOT NULL,
    payment_value           DECIMAL(10,2)   NOT NULL,
    CONSTRAINT pk_order_payments PRIMARY KEY (order_id, payment_sequential),
    CONSTRAINT fk_order_payments_orders FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 9. ORDER REVIEWS TABLE
-- Customer satisfaction ratings (1-5 stars) and qualitative feedback comments.
-- Surrogate PK ensures handling of multiple or duplicate review submissions.
-- ------------------------------------------------------------------------------
CREATE TABLE order_reviews (
    review_pk               BIGINT AUTO_INCREMENT   NOT NULL,
    review_id               VARCHAR(50)             NOT NULL,
    order_id                VARCHAR(50)             NOT NULL,
    review_score            INT                     NOT NULL,
    review_comment_title    TEXT                    NULL,
    review_comment_message  TEXT                    NULL,
    review_creation_date    DATETIME                NOT NULL,
    review_answer_timestamp DATETIME                NOT NULL,
    CONSTRAINT pk_order_reviews PRIMARY KEY (review_pk),
    CONSTRAINT fk_order_reviews_orders FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================================
-- STEP 4: INDEXING STRATEGY FOR HIGH-PERFORMANCE ANALYTICS
-- ==============================================================================

-- Customers Table Indexes
CREATE INDEX idx_customers_unique_id    ON customers (customer_unique_id);
CREATE INDEX idx_customers_zip_prefix   ON customers (customer_zip_code_prefix);
CREATE INDEX idx_customers_city_state   ON customers (customer_state, customer_city);

-- Orders Table Indexes
CREATE INDEX idx_orders_customer_id         ON orders (customer_id);
CREATE INDEX idx_orders_status              ON orders (order_status);
CREATE INDEX idx_orders_purchase_timestamp  ON orders (order_purchase_timestamp);
CREATE INDEX idx_orders_delivered_customer  ON orders (order_delivered_customer_date);
CREATE INDEX idx_orders_estimated_delivery  ON orders (order_estimated_delivery_date);

-- Order Items Table Indexes
CREATE INDEX idx_order_items_product_id     ON order_items (product_id);
CREATE INDEX idx_order_items_seller_id      ON order_items (seller_id);
CREATE INDEX idx_order_items_price          ON order_items (price);

-- Order Payments Table Indexes
CREATE INDEX idx_order_payments_order_id    ON order_payments (order_id);
CREATE INDEX idx_order_payments_type        ON order_payments (payment_type);

-- Order Reviews Table Indexes
CREATE INDEX idx_order_reviews_order_id     ON order_reviews (order_id);
CREATE INDEX idx_order_reviews_score        ON order_reviews (review_score);
CREATE INDEX idx_order_reviews_creation     ON order_reviews (review_creation_date);

-- Products Table Indexes
CREATE INDEX idx_products_category_name     ON products (product_category_name);

-- Sellers Table Indexes
CREATE INDEX idx_sellers_zip_prefix         ON sellers (seller_zip_code_prefix);
CREATE INDEX idx_sellers_state_city         ON sellers (seller_state, seller_city);

-- Geolocation Table Indexes
CREATE INDEX idx_geolocation_zip_prefix     ON geolocation (geolocation_zip_code_prefix);

-- ==============================================================================
-- STEP 5: BULK DATA INGESTION (LOAD DATA INFILE)
-- ==============================================================================
-- NOTES FOR INGESTION:
-- 1. SET FOREIGN_KEY_CHECKS = 0 temporarily disables foreign key verification,
--    dramatically accelerating bulk insertion and avoiding insert ordering locks.
-- 2. Windows paths must use forward slashes (/) as shown below.
-- 3. NULLIF(@var, '') maps empty CSV strings to SQL NULL values for optional fields.
-- 4. IGNORE 1 LINES skips the CSV header row.
-- 5. Standard line terminator is '\r\n' (Windows CRLF). If loading on Linux/Unix,
--    change to '\n'.
-- ==============================================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = '';

-- ------------------------------------------------------------------------------
-- Ingestion 1: Customers
-- ------------------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/Users/ramee/Downloads/e commerce/Ecommerce-Customer-Analytics/data/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
);

-- ------------------------------------------------------------------------------
-- Ingestion 2: Product Category Name Translation
-- ------------------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/Users/ramee/Downloads/e commerce/Ecommerce-Customer-Analytics/data/product_category_name_translation.csv'
INTO TABLE product_category_translation
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    product_category_name,
    product_category_name_english
);

-- ------------------------------------------------------------------------------
-- Ingestion 3: Products
-- CSV headers: product_id, product_category_name, product_name_lenght,
--              product_description_lenght, product_photos_qty, product_weight_g,
--              product_length_cm, product_height_cm, product_width_cm
-- ------------------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/Users/ramee/Downloads/e commerce/Ecommerce-Customer-Analytics/data/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    product_id,
    @v_category,
    @v_name_len,
    @v_desc_len,
    @v_photos_qty,
    @v_weight,
    @v_length,
    @v_height,
    @v_width
)
SET
    product_category_name      = NULLIF(TRIM(@v_category), ''),
    product_name_length        = NULLIF(TRIM(@v_name_len), ''),
    product_description_length = NULLIF(TRIM(@v_desc_len), ''),
    product_photos_qty         = NULLIF(TRIM(@v_photos_qty), ''),
    product_weight_g           = NULLIF(TRIM(@v_weight), ''),
    product_length_cm          = NULLIF(TRIM(@v_length), ''),
    product_height_cm          = NULLIF(TRIM(@v_height), ''),
    product_width_cm           = NULLIF(TRIM(@v_width), '');

-- ------------------------------------------------------------------------------
-- Ingestion 4: Sellers
-- ------------------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/Users/ramee/Downloads/e commerce/Ecommerce-Customer-Analytics/data/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
);

-- ------------------------------------------------------------------------------
-- Ingestion 5: Geolocation
-- (Over 1,000,000 coordinate records)
-- ------------------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/Users/ramee/Downloads/e commerce/Ecommerce-Customer-Analytics/data/olist_geolocation_dataset.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
);

-- ------------------------------------------------------------------------------
-- Ingestion 6: Orders
-- CSV headers: order_id, customer_id, order_status, order_purchase_timestamp,
--              order_approved_at, order_delivered_carrier_date,
--              order_delivered_customer_date, order_estimated_delivery_date
-- ------------------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/Users/ramee/Downloads/e commerce/Ecommerce-Customer-Analytics/data/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    @v_approved,
    @v_delivered_carrier,
    @v_delivered_customer,
    order_estimated_delivery_date
)
SET
    order_approved_at             = NULLIF(TRIM(@v_approved), ''),
    order_delivered_carrier_date  = NULLIF(TRIM(@v_delivered_carrier), ''),
    order_delivered_customer_date = NULLIF(TRIM(@v_delivered_customer), '');

-- ------------------------------------------------------------------------------
-- Ingestion 7: Order Items
-- CSV headers: order_id, order_item_id, product_id, seller_id,
--              shipping_limit_date, price, freight_value
-- ------------------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/Users/ramee/Downloads/e commerce/Ecommerce-Customer-Analytics/data/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
);

-- ------------------------------------------------------------------------------
-- Ingestion 8: Order Payments
-- CSV headers: order_id, payment_sequential, payment_type,
--              payment_installments, payment_value
-- ------------------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/Users/ramee/Downloads/e commerce/Ecommerce-Customer-Analytics/data/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
);

-- ------------------------------------------------------------------------------
-- Ingestion 9: Order Reviews
-- CSV headers: review_id, order_id, review_score, review_comment_title,
--              review_comment_message, review_creation_date, review_answer_timestamp
-- Note: Handles multi-line comments encapsulated within double quotes.
-- ------------------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/Users/ramee/Downloads/e commerce/Ecommerce-Customer-Analytics/data/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    review_id,
    order_id,
    review_score,
    @v_title,
    @v_message,
    review_creation_date,
    review_answer_timestamp
)
SET
    review_comment_title   = NULLIF(TRIM(@v_title), ''),
    review_comment_message = NULLIF(TRIM(@v_message), '');

-- Re-enable foreign key constraints after bulk ingestion
SET FOREIGN_KEY_CHECKS = 1;

-- ==============================================================================
-- STEP 6: POST-INGESTION VERIFICATION
-- Run this check to verify all table row counts match expected Olist metrics
-- ==============================================================================
SELECT 'customers' AS table_name, COUNT(*) AS row_count, '99,441' AS expected_approx FROM customers
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
