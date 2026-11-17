#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
E-Commerce Customer Analytics - Master Execution Script
=======================================================
Runs all analysis steps and generates exports for Power BI.
Compatible with Python 3.6+, pandas 1.1.5, numpy 1.19.5

Steps:
  1. Verify dataset files
  2. Load & validate all 9 CSVs
  3. Data cleaning
  4. Master dataset merge
  5. EDA statistics
  6. RFM segmentation
  7. Cohort retention analysis
  8. Churn analysis
  9. Export all CSVs for Power BI
  10. Print business insights summary
"""

import os
import sys
import warnings
import json
from datetime import datetime

warnings.filterwarnings('ignore')

import pandas as pd
import numpy as np

# ─────────────────────────────────────────────────────────────────────────────
# PATHS
# ─────────────────────────────────────────────────────────────────────────────
BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
DATA_DIR    = os.path.join(BASE_DIR, 'data')
EXPORTS_DIR = os.path.join(BASE_DIR, 'exports')
CHARTS_DIR  = os.path.join(EXPORTS_DIR, 'charts')

for d in [EXPORTS_DIR, CHARTS_DIR]:
    os.makedirs(d, exist_ok=True)

RESULTS = {}   # accumulate numeric results for final insights report

def log(msg):
    ts = datetime.now().strftime('%H:%M:%S')
    print(f"[{ts}] {msg}")

def section(title):
    print("\n" + "="*70)
    print(f"  {title}")
    print("="*70)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — VERIFY DATASET FILES
# ─────────────────────────────────────────────────────────────────────────────
section("STEP 1: Verifying Dataset Files")

EXPECTED_FILES = {
    'olist_customers_dataset.csv':              None,
    'olist_orders_dataset.csv':                 None,
    'olist_order_items_dataset.csv':            None,
    'olist_order_payments_dataset.csv':         None,
    'olist_order_reviews_dataset.csv':          None,
    'olist_products_dataset.csv':               None,
    'olist_sellers_dataset.csv':                None,
    'olist_geolocation_dataset.csv':            None,
    'product_category_name_translation.csv':    None,
}

all_found = True
for fname in EXPECTED_FILES:
    fpath = os.path.join(DATA_DIR, fname)
    if os.path.exists(fpath):
        size_mb = os.path.getsize(fpath) / 1_048_576
        log(f"  FOUND  {fname:55s} {size_mb:.2f} MB")
    else:
        log(f"  MISSING {fname}")
        all_found = False

if not all_found:
    sys.exit("ERROR: Some CSV files are missing. Please place them in the data/ folder.")

log("All 9 dataset files verified.")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — LOAD ALL DATASETS
# ─────────────────────────────────────────────────────────────────────────────
section("STEP 2: Loading Datasets")

customers    = pd.read_csv(os.path.join(DATA_DIR, 'olist_customers_dataset.csv'))
orders       = pd.read_csv(os.path.join(DATA_DIR, 'olist_orders_dataset.csv'))
order_items  = pd.read_csv(os.path.join(DATA_DIR, 'olist_order_items_dataset.csv'))
payments     = pd.read_csv(os.path.join(DATA_DIR, 'olist_order_payments_dataset.csv'))
reviews      = pd.read_csv(os.path.join(DATA_DIR, 'olist_order_reviews_dataset.csv'))
products     = pd.read_csv(os.path.join(DATA_DIR, 'olist_products_dataset.csv'))
sellers      = pd.read_csv(os.path.join(DATA_DIR, 'olist_sellers_dataset.csv'))
geolocation  = pd.read_csv(os.path.join(DATA_DIR, 'olist_geolocation_dataset.csv'))
cat_trans    = pd.read_csv(os.path.join(DATA_DIR, 'product_category_name_translation.csv'))

datasets = {
    'customers':    customers,
    'orders':       orders,
    'order_items':  order_items,
    'payments':     payments,
    'reviews':      reviews,
    'products':     products,
    'sellers':      sellers,
    'geolocation':  geolocation,
    'cat_trans':    cat_trans,
}

for name, df in datasets.items():
    nulls = df.isnull().sum().sum()
    log(f"  {name:15s}  rows={len(df):>8,}  cols={df.shape[1]:>3}  nulls={nulls:>6,}")

RESULTS['total_raw_orders'] = len(orders)
RESULTS['total_customers_registered'] = customers['customer_unique_id'].nunique()

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — DATA CLEANING
# ─────────────────────────────────────────────────────────────────────────────
section("STEP 3: Data Cleaning")

# --- Orders: parse timestamps ---
ts_cols = ['order_purchase_timestamp','order_approved_at',
           'order_delivered_carrier_date','order_delivered_customer_date',
           'order_estimated_delivery_date']
for c in ts_cols:
    orders[c] = pd.to_datetime(orders[c], errors='coerce')

log(f"Parsed {len(ts_cols)} timestamp columns in orders.")

# --- Orders: status distribution ---
status_counts = orders['order_status'].value_counts()
log("Order status distribution:")
for status, cnt in status_counts.items():
    log(f"  {status:25s}: {cnt:>6,}")

RESULTS['total_delivered_orders'] = int(status_counts.get('delivered', 0))
RESULTS['cancelled_orders'] = int(status_counts.get('canceled', 0))

# --- Products: fill missing category ---
missing_cat = products['product_category_name'].isnull().sum()
products['product_category_name'] = products['product_category_name'].fillna('unknown')
log(f"Products: filled {missing_cat} missing category names with 'unknown'.")

# --- Products: fill missing numerics with median ---
num_cols = ['product_name_lenght','product_description_lenght','product_photos_qty',
            'product_weight_g','product_length_cm','product_height_cm','product_width_cm']
for c in num_cols:
    if c in products.columns:
        n_null = products[c].isnull().sum()
        if n_null > 0:
            products[c] = products[c].fillna(products[c].median())
            log(f"  products[{c}]: filled {n_null} nulls with median.")

# --- Reviews: drop sparse text cols ---
text_cols = ['review_comment_title','review_comment_message']
existing_text = [c for c in text_cols if c in reviews.columns]
reviews = reviews.drop(columns=existing_text)
log(f"Reviews: dropped {len(existing_text)} sparse text columns.")

# --- Payments: validate ---
bad_payments = payments[payments['payment_value'] <= 0]
log(f"Payments: found {len(bad_payments)} rows with payment_value <= 0 (excluding).")
payments = payments[payments['payment_value'] > 0]

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 — BUILD MASTER ANALYTICAL DATASET
# ─────────────────────────────────────────────────────────────────────────────
section("STEP 4: Building Master Dataset")

# 4a: Filter to delivered orders only
delivered = orders[orders['order_status'] == 'delivered'].copy()
log(f"Delivered orders: {len(delivered):,}")

# 4b: Aggregate order_items per order
items_agg = order_items.groupby('order_id').agg(
    item_count=('order_item_id', 'count'),
    items_price=('price', 'sum'),
    items_freight=('freight_value', 'sum'),
    primary_product_id=('product_id', 'first'),
    seller_id=('seller_id', 'first')
).reset_index()

# 4c: Aggregate payments per order
pay_agg = payments.groupby('order_id').agg(
    payment_value=('payment_value', 'sum'),
    payment_installments=('payment_installments', 'max'),
    payment_type=('payment_type', 'first')
).reset_index()

# 4d: Merge orders + customers
df = delivered.merge(customers, on='customer_id', how='left')
log(f"After orders+customers: {len(df):,} rows")

# 4e: Add order items
df = df.merge(items_agg, on='order_id', how='left')
log(f"After order items: {len(df):,} rows")

# 4f: Add payments
df = df.merge(pay_agg, on='order_id', how='left')
log(f"After payments: {len(df):,} rows")

# 4g: Add products
df = df.merge(products[['product_id','product_category_name']],
              left_on='primary_product_id', right_on='product_id', how='left')

# 4h: Add English translations
df = df.merge(cat_trans, on='product_category_name', how='left')

# 4i: Add sellers
df = df.merge(sellers[['seller_id','seller_state']], on='seller_id', how='left')

# 4j: Feature engineering
df['order_revenue'] = df['items_price'] + df['items_freight']
df['delivery_days'] = (df['order_delivered_customer_date'] -
                        df['order_purchase_timestamp']).dt.days
df['estimated_days'] = (df['order_estimated_delivery_date'] -
                         df['order_purchase_timestamp']).dt.days
df['is_on_time'] = (df['order_delivered_customer_date'] <=
                     df['order_estimated_delivery_date']).astype(int)
df['order_year_month'] = df['order_purchase_timestamp'].dt.to_period('M').astype(str)
df['order_year'] = df['order_purchase_timestamp'].dt.year
df['order_month'] = df['order_purchase_timestamp'].dt.month
df['order_quarter'] = df['order_purchase_timestamp'].dt.quarter
df['product_category_english'] = df['product_category_name_english'].fillna(
    df['product_category_name'].fillna('unknown'))

log(f"Master dataset shape: {df.shape}")
log(f"Columns: {list(df.columns)}")

# Record key metrics
RESULTS['master_rows']      = len(df)
RESULTS['total_revenue']    = round(df['payment_value'].sum(), 2)
RESULTS['avg_order_value']  = round(df['payment_value'].mean(), 2)
RESULTS['avg_delivery_days']= round(df['delivery_days'].dropna().mean(), 1)
RESULTS['on_time_rate']     = round(df['is_on_time'].mean() * 100, 1)

log(f"\n  KEY METRICS:")
log(f"  Total Revenue (GMV):    R$ {RESULTS['total_revenue']:>12,.2f}")
log(f"  Avg Order Value (AOV):  R$ {RESULTS['avg_order_value']:>12,.2f}")
log(f"  Avg Delivery Days:       {RESULTS['avg_delivery_days']:>12.1f}")
log(f"  On-Time Delivery Rate:   {RESULTS['on_time_rate']:>11.1f}%")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5 — CUSTOMER-LEVEL AGGREGATION
# ─────────────────────────────────────────────────────────────────────────────
section("STEP 5: Customer-Level Aggregation")

df_cust = df.groupby('customer_unique_id').agg(
    total_orders=('order_id', 'nunique'),
    total_revenue=('payment_value', 'sum'),
    first_order_date=('order_purchase_timestamp', 'min'),
    last_order_date=('order_purchase_timestamp', 'max'),
    avg_order_value=('payment_value', 'mean'),
    avg_delivery_days=('delivery_days', 'mean'),
    customer_state=('customer_state', 'first'),
    customer_city=('customer_city', 'first'),
    primary_category=('product_category_english', 'first')
).reset_index()

df_cust['is_repeat_customer'] = (df_cust['total_orders'] > 1).astype(int)
df_cust['customer_lifetime_days'] = (
    df_cust['last_order_date'] - df_cust['first_order_date']
).dt.days.fillna(0).astype(int)

repeat_rate = df_cust['is_repeat_customer'].mean() * 100
one_time_pct = 100 - repeat_rate
RESULTS['total_unique_customers']  = len(df_cust)
RESULTS['repeat_customers']        = int(df_cust['is_repeat_customer'].sum())
RESULTS['repeat_customer_rate']    = round(repeat_rate, 2)
RESULTS['one_time_customer_pct']   = round(one_time_pct, 2)

log(f"Unique purchasing customers: {RESULTS['total_unique_customers']:,}")
log(f"Repeat customers:            {RESULTS['repeat_customers']:,}  ({repeat_rate:.2f}%)")
log(f"One-time customers:          {len(df_cust) - RESULTS['repeat_customers']:,}  ({one_time_pct:.2f}%)")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 6 — RFM SEGMENTATION
# ─────────────────────────────────────────────────────────────────────────────
section("STEP 6: RFM Segmentation")

ref_date = df['order_purchase_timestamp'].max() + pd.Timedelta(days=1)
log(f"Reference date: {ref_date.date()}")

rfm = df.groupby('customer_unique_id').agg(
    recency_days=('order_purchase_timestamp', lambda x: (ref_date - x.max()).days),
    frequency=('order_id', 'nunique'),
    monetary=('payment_value', 'sum')
).reset_index()

# Score 1-5 using quantile bins
# Recency: lower = better -> score 5
rfm['r_score'] = pd.qcut(rfm['recency_days'], q=5, labels=[5,4,3,2,1]).astype(int)

# Frequency & Monetary: use rank to handle ties
rfm['f_score'] = pd.qcut(rfm['frequency'].rank(method='first'), q=5,
                          labels=[1,2,3,4,5]).astype(int)
rfm['m_score'] = pd.qcut(rfm['monetary'].rank(method='first'), q=5,
                          labels=[1,2,3,4,5]).astype(int)
rfm['rfm_score'] = rfm['r_score'] + rfm['f_score'] + rfm['m_score']
rfm['rfm_string'] = (rfm['r_score'].astype(str) + rfm['f_score'].astype(str)
                     + rfm['m_score'].astype(str))

def assign_segment(row):
    r, f, m = row['r_score'], row['f_score'], row['m_score']
    if r >= 4 and f >= 4 and m >= 4:
        return 'Champions'
    elif r >= 3 and f >= 3 and m >= 3:
        return 'Loyal Customers'
    elif r >= 4 and f == 1:
        return 'New Customers'
    elif r >= 3 and f >= 2 and m >= 2:
        return 'Promising'
    elif r >= 3 and f <= 2:
        return 'Potential Loyalists'
    elif r <= 2 and f >= 3:
        return 'At Risk'
    elif r <= 2 and f <= 2 and m >= 2:
        return 'Cannot Lose Them'
    elif r <= 1 and f <= 1:
        return 'Lost Customers'
    else:
        return 'Hibernating'

rfm['segment'] = rfm.apply(assign_segment, axis=1)

# Segment summary
seg_summary = rfm.groupby('segment').agg(
    customer_count=('customer_unique_id', 'count'),
    avg_recency=('recency_days', 'mean'),
    avg_frequency=('frequency', 'mean'),
    avg_monetary=('monetary', 'mean'),
    total_revenue=('monetary', 'sum')
).reset_index()
seg_summary['pct_customers'] = (seg_summary['customer_count'] /
                                 seg_summary['customer_count'].sum() * 100).round(2)
seg_summary['pct_revenue'] = (seg_summary['total_revenue'] /
                               seg_summary['total_revenue'].sum() * 100).round(2)
seg_summary = seg_summary.sort_values('total_revenue', ascending=False)

log("\nRFM Segment Summary:")
log(f"  {'Segment':25s} {'Customers':>10} {'% Cust':>8} {'Avg R':>8} "
    f"{'Avg F':>7} {'Avg M (R$)':>12} {'% Rev':>8}")
log("  " + "-"*82)
for _, row in seg_summary.iterrows():
    log(f"  {row['segment']:25s} {int(row['customer_count']):>10,} "
        f"{row['pct_customers']:>7.1f}% {row['avg_recency']:>8.0f} "
        f"{row['avg_frequency']:>7.1f} {row['avg_monetary']:>12.2f} "
        f"{row['pct_revenue']:>7.1f}%")

RESULTS['rfm_segment_summary'] = seg_summary.set_index('segment').to_dict()
champions = seg_summary[seg_summary['segment'] == 'Champions']
if len(champions):
    RESULTS['champions_pct_customers'] = round(champions['pct_customers'].values[0], 2)
    RESULTS['champions_pct_revenue']   = round(champions['pct_revenue'].values[0], 2)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 7 — COHORT RETENTION ANALYSIS
# ─────────────────────────────────────────────────────────────────────────────
section("STEP 7: Cohort Retention Analysis")

# Assign first purchase month as cohort
cohort_df = df.groupby('customer_unique_id')['order_purchase_timestamp'].min().reset_index()
cohort_df.columns = ['customer_unique_id', 'first_purchase_date']
cohort_df['cohort_month'] = cohort_df['first_purchase_date'].dt.to_period('M')

# Merge cohort back
df_cohort = df.merge(cohort_df[['customer_unique_id','cohort_month']],
                     on='customer_unique_id', how='left')
df_cohort['order_period'] = df_cohort['order_purchase_timestamp'].dt.to_period('M')
df_cohort['months_since_first'] = ((df_cohort['order_period'].astype(int)) -
                                    (df_cohort['cohort_month'].astype(int)))

# Cohort pivot: count distinct customers
cohort_pivot = df_cohort.groupby(
    ['cohort_month','months_since_first'])['customer_unique_id'].nunique().unstack(fill_value=0)

cohort_sizes = cohort_pivot.get(0, pd.Series(dtype=int))
retention_matrix = cohort_pivot.divide(cohort_sizes, axis=0).multiply(100).round(2)

# Average retention by month offset
avg_retention = retention_matrix.mean(axis=0)
log("Average retention by months since first purchase:")
for month_offset in sorted(avg_retention.index[:13]):
    pct = avg_retention.get(month_offset, 0)
    log(f"  Month {month_offset:>2d}: {pct:.2f}%")

RESULTS['avg_month1_retention'] = round(float(avg_retention.get(1, 0)), 2)
RESULTS['cohort_count'] = len(cohort_sizes)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 8 — CHURN ANALYSIS
# ─────────────────────────────────────────────────────────────────────────────
section("STEP 8: Churn Analysis")

ref_date_churn = df['order_purchase_timestamp'].max() + pd.Timedelta(days=1)

churn_df = rfm.copy()
churn_df['churn_status'] = 'Active'
churn_df.loc[churn_df['recency_days'].between(90, 180), 'churn_status'] = 'At Risk'
churn_df.loc[churn_df['recency_days'] > 180, 'churn_status'] = 'Churned'

churn_df['buyer_type'] = 'One-Time Buyer'
churn_df.loc[churn_df['frequency'].between(2,3), 'buyer_type'] = 'Occasional Buyer'
churn_df.loc[churn_df['frequency'] > 3, 'buyer_type'] = 'Frequent Buyer'

churn_summary = churn_df.groupby('churn_status').agg(
    customer_count=('customer_unique_id','count'),
    total_revenue=('monetary','sum'),
    avg_monetary=('monetary','mean')
).reset_index()
churn_summary['pct_customers'] = (churn_summary['customer_count'] /
                                   churn_summary['customer_count'].sum() * 100).round(2)
churn_summary['pct_revenue'] = (churn_summary['total_revenue'] /
                                 churn_summary['total_revenue'].sum() * 100).round(2)

log("\nChurn Status Summary:")
log(f"  {'Status':15s} {'Customers':>10} {'% Cust':>8} {'Revenue (R$)':>14} {'% Rev':>8}")
log("  " + "-"*60)
for _, row in churn_summary.iterrows():
    log(f"  {row['churn_status']:15s} {int(row['customer_count']):>10,} "
        f"{row['pct_customers']:>7.1f}% {row['total_revenue']:>14,.2f} "
        f"{row['pct_revenue']:>7.1f}%")

at_risk = churn_summary[churn_summary['churn_status'] == 'At Risk']
churned  = churn_summary[churn_summary['churn_status'] == 'Churned']
if len(at_risk):
    RESULTS['at_risk_customers'] = int(at_risk['customer_count'].values[0])
    RESULTS['at_risk_revenue']   = round(float(at_risk['total_revenue'].values[0]), 2)
    RESULTS['at_risk_pct']       = round(float(at_risk['pct_customers'].values[0]), 2)
if len(churned):
    RESULTS['churned_customers'] = int(churned['customer_count'].values[0])
    RESULTS['churned_revenue']   = round(float(churned['total_revenue'].values[0]), 2)
    RESULTS['churn_rate']        = round(float(churned['pct_customers'].values[0]), 2)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 9 — EDA STATISTICS
# ─────────────────────────────────────────────────────────────────────────────
section("STEP 9: EDA Statistics")

# Monthly revenue
monthly_rev = df.groupby('order_year_month')['payment_value'].sum().reset_index()
monthly_rev.columns = ['year_month','revenue']
monthly_rev = monthly_rev.sort_values('year_month')
peak_month = monthly_rev.loc[monthly_rev['revenue'].idxmax()]
RESULTS['peak_revenue_month'] = peak_month['year_month']
RESULTS['peak_revenue']       = round(float(peak_month['revenue']), 2)
log(f"Peak revenue month: {peak_month['year_month']} -> R$ {peak_month['revenue']:,.2f}")

# Top categories
cat_rev = df.groupby('product_category_english')['payment_value'].sum().sort_values(ascending=False)
top5_cats = cat_rev.head(5)
RESULTS['top_categories'] = {k: round(float(v),2) for k, v in top5_cats.items()}
log("Top 5 categories by revenue:")
for cat, rev in top5_cats.items():
    log(f"  {cat:40s}: R$ {rev:>12,.2f}")

# Top states
state_rev = df.groupby('customer_state')['payment_value'].sum().sort_values(ascending=False)
top5_states = state_rev.head(5)
RESULTS['top_states'] = {k: round(float(v),2) for k, v in top5_states.items()}
log("Top 5 states by revenue:")
for state, rev in top5_states.items():
    log(f"  {state}: R$ {rev:>12,.2f}")

# Payment types
pay_types = payments.groupby('payment_type')['payment_value'].agg(['count','sum'])
pay_types['pct_count'] = (pay_types['count'] / pay_types['count'].sum() * 100).round(1)
RESULTS['payment_type_distribution'] = pay_types['pct_count'].to_dict()
log("Payment type distribution:")
for ptype, pct in pay_types['pct_count'].sort_values(ascending=False).items():
    log(f"  {ptype:20s}: {pct:.1f}%")

# Review scores
if 'review_score' in reviews.columns:
    avg_review = reviews['review_score'].mean()
    RESULTS['avg_review_score'] = round(avg_review, 2)
    log(f"Average review score: {avg_review:.2f} / 5.0")

# Delivery stats
valid_delivery = df['delivery_days'].dropna()
valid_delivery = valid_delivery[valid_delivery > 0]
RESULTS['median_delivery_days'] = round(float(valid_delivery.median()), 1)
log(f"Median delivery days: {RESULTS['median_delivery_days']}")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 10 — EXPORT ALL CSVS
# ─────────────────────────────────────────────────────────────────────────────
section("STEP 10: Exporting CSVs for Power BI")

exports = {
    'master_dataset.csv':          df,
    'customer_summary.csv':        df_cust,
    'rfm_segments.csv':            rfm,
    'rfm_segment_summary.csv':     seg_summary,
    'churn_analysis.csv':          churn_df,
    'churn_summary.csv':           churn_summary,
    'monthly_revenue.csv':         monthly_rev,
    'category_revenue.csv':        cat_rev.reset_index().rename(columns={'payment_value':'revenue'}),
    'state_revenue.csv':           state_rev.reset_index().rename(columns={'payment_value':'revenue'}),
}

# Cohort matrix exports
retention_matrix_export = retention_matrix.reset_index()
retention_matrix_export['cohort_month'] = retention_matrix_export['cohort_month'].astype(str)
exports['cohort_retention_matrix.csv'] = retention_matrix_export

for fname, data_df in exports.items():
    out_path = os.path.join(EXPORTS_DIR, fname)
    data_df.to_csv(out_path, index=False)
    size_kb = os.path.getsize(out_path) / 1024
    log(f"  Exported: {fname:40s} ({size_kb:.1f} KB,  {len(data_df):,} rows)")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 11 — SAVE RESULTS JSON
# ─────────────────────────────────────────────────────────────────────────────
section("STEP 11: Saving Results for Reporting")

# Clean results for JSON serialization
def clean_for_json(obj):
    if isinstance(obj, dict):
        return {k: clean_for_json(v) for k, v in obj.items()}
    elif isinstance(obj, (np.integer,)):
        return int(obj)
    elif isinstance(obj, (np.floating,)):
        return float(obj)
    elif isinstance(obj, pd.Period):
        return str(obj)
    else:
        return obj

results_path = os.path.join(EXPORTS_DIR, 'analysis_results.json')
with open(results_path, 'w') as f:
    json.dump(clean_for_json(RESULTS), f, indent=2, default=str)
log(f"Results saved to: {results_path}")

# ─────────────────────────────────────────────────────────────────────────────
# FINAL SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
section("FINAL SUMMARY — Key Business Metrics")

print(f"""
  DATASET
  -------
  Total Raw Orders:            {RESULTS.get('total_raw_orders',0):>10,}
  Delivered Orders (analyzed): {RESULTS.get('master_rows',0):>10,}
  Registered Customers:        {RESULTS.get('total_customers_registered',0):>10,}
  Unique Purchasing Customers: {RESULTS.get('total_unique_customers',0):>10,}

  REVENUE
  -------
  Gross Merchandise Value:     R$ {RESULTS.get('total_revenue',0):>12,.2f}
  Average Order Value (AOV):   R$ {RESULTS.get('avg_order_value',0):>12,.2f}
  Peak Revenue Month:          {RESULTS.get('peak_revenue_month','N/A'):>13s}

  CUSTOMERS
  ---------
  Repeat Customer Rate:        {RESULTS.get('repeat_customer_rate',0):>10.2f}%
  One-Time Buyer Rate:         {RESULTS.get('one_time_customer_pct',0):>10.2f}%
  Average Delivery Days:       {RESULTS.get('avg_delivery_days',0):>10.1f}
  On-Time Delivery Rate:       {RESULTS.get('on_time_rate',0):>10.1f}%
  Average Review Score:        {RESULTS.get('avg_review_score',0):>10.2f} / 5.0

  RFM SEGMENTS
  ------------
  Champions - % of Customers:  {RESULTS.get('champions_pct_customers',0):>9.2f}%
  Champions - % of Revenue:    {RESULTS.get('champions_pct_revenue',0):>9.2f}%
  At Risk Customers:           {RESULTS.get('at_risk_customers',0):>10,}
  At Risk Revenue:             R$ {RESULTS.get('at_risk_revenue',0):>12,.2f}

  CHURN
  -----
  Churned Customers:           {RESULTS.get('churned_customers',0):>10,}
  Churn Rate:                  {RESULTS.get('churn_rate',0):>10.2f}%
  Churned Revenue:             R$ {RESULTS.get('churned_revenue',0):>12,.2f}

  COHORT RETENTION
  ----------------
  Total Cohorts:               {RESULTS.get('cohort_count',0):>10,}
  Avg Month-1 Retention Rate:  {RESULTS.get('avg_month1_retention',0):>10.2f}%
""")

print("=" * 70)
print("  ALL ANALYSIS COMPLETE — Exports ready in the exports/ folder")
print("=" * 70)
