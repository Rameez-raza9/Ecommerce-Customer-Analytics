# Dataset Download Instructions

## Olist Brazilian E-Commerce Dataset

This project uses the **Brazilian E-Commerce Public Dataset by Olist**, available on Kaggle.

### Step-by-Step Download Instructions

1. Go to: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
2. Click the **Download** button (you need a free Kaggle account)
3. Extract the ZIP file
4. Place all CSV files into **this `data/` folder**

### Required Files (9 CSV Files)

After extraction, you should have these files in this directory:

| File | Description | Rows (approx.) |
|------|-------------|----------------|
| `olist_customers_dataset.csv` | Customer info + location | 99,441 |
| `olist_orders_dataset.csv` | Order details + status + timestamps | 99,441 |
| `olist_order_items_dataset.csv` | Items per order + seller + price | 112,650 |
| `olist_order_payments_dataset.csv` | Payment method + value | 103,886 |
| `olist_order_reviews_dataset.csv` | Customer review scores + text | 99,224 |
| `olist_products_dataset.csv` | Product details + dimensions | 32,951 |
| `olist_sellers_dataset.csv` | Seller info + location | 3,095 |
| `olist_geolocation_dataset.csv` | ZIP code → lat/lng mapping | 1,000,163 |
| `product_category_name_translation.csv` | Portuguese → English category names | 71 |

### Dataset Overview

- **Time Period**: September 2016 — August 2018
- **Country**: Brazil
- **Source**: Olist (largest Brazilian marketplace)
- **License**: CC BY-NC-SA 4.0

### Schema Diagram

```
customers ──────────────────────── orders ──────────────── order_items
  customer_id (PK)                   order_id (PK)              order_id (FK)
  customer_unique_id                 customer_id (FK)           product_id (FK)
  customer_zip_code_prefix           order_status               seller_id (FK)
  customer_city                      order_purchase_timestamp   price
  customer_state                     order_delivered_*          freight_value
                                     order_estimated_*
                                          |
                               ┌──────────┴──────────┐
                       order_payments             order_reviews
                           order_id (FK)              order_id (FK)
                           payment_type               review_score
                           payment_value              review_comment_*

products ──────── order_items           sellers ──────── order_items
  product_id (PK)                         seller_id (PK)
  product_category_name ────────── product_category_name_translation
  product_weight_g                    product_category_name
  product_dimensions                  product_category_name_english
```

### After Placing Files

Run the notebooks in this order:
1. `notebooks/00_data_preparation.ipynb` — loads, cleans, merges all data
2. `notebooks/ecommerce_eda.ipynb` — full exploratory analysis
3. `notebooks/customer_rfm_analysis.ipynb` — RFM segmentation
4. `notebooks/customer_retention_analysis.ipynb` — retention & churn

### Quick Verification

After placing the files, run this quick check in Python:
```python
import os
expected = [
    'olist_customers_dataset.csv',
    'olist_orders_dataset.csv',
    'olist_order_items_dataset.csv',
    'olist_order_payments_dataset.csv',
    'olist_order_reviews_dataset.csv',
    'olist_products_dataset.csv',
    'olist_sellers_dataset.csv',
    'olist_geolocation_dataset.csv',
    'product_category_name_translation.csv'
]
data_dir = './data'
for f in expected:
    status = '✅' if os.path.exists(os.path.join(data_dir, f)) else '❌ MISSING'
    print(f"{status} {f}")
```
