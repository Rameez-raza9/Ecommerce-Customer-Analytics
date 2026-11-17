#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
E-Commerce Customer Analytics - Chart Generation Script
=======================================================
Generates all professional charts for the EDA report.
Uses actual exported data from run_analysis.py
"""

import os
import warnings
warnings.filterwarnings('ignore')

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend for script execution
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import matplotlib.patches as mpatches
import seaborn as sns

# ─── Paths ───────────────────────────────────────────────────────────────────
BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
EXPORTS_DIR = os.path.join(BASE_DIR, 'exports')
CHARTS_DIR  = os.path.join(EXPORTS_DIR, 'charts')
os.makedirs(CHARTS_DIR, exist_ok=True)

# ─── Style Config ─────────────────────────────────────────────────────────────
plt.rcParams.update({
    'figure.facecolor':  'white',
    'axes.facecolor':    '#f8f9fa',
    'axes.grid':         True,
    'grid.color':        '#e0e0e0',
    'grid.linewidth':    0.6,
    'axes.spines.top':   False,
    'axes.spines.right': False,
    'font.size':         11,
})

C_MAIN    = '#2E86AB'
C_RED     = '#E84855'
C_ORANGE  = '#F4A261'
C_GREEN   = '#2A9D8F'
C_PURPLE  = '#7B2D8B'
PALETTE   = [C_MAIN, C_RED, C_ORANGE, C_GREEN, C_PURPLE,
             '#264653', '#E9C46A', '#A8DADC', '#457B9D', '#1D3557']

def save(fig, name):
    path = os.path.join(CHARTS_DIR, name)
    fig.savefig(path, dpi=150, bbox_inches='tight')
    plt.close(fig)
    print(f"  Saved: {name}")

def fmt_brl(x, pos=None):
    if x >= 1_000_000:
        return f"R${x/1_000_000:.1f}M"
    elif x >= 1_000:
        return f"R${x/1_000:.0f}K"
    return f"R${x:.0f}"

print("Loading exported data...")

# Load data
df         = pd.read_csv(os.path.join(EXPORTS_DIR, 'master_dataset.csv'),
                          parse_dates=['order_purchase_timestamp',
                                       'order_delivered_customer_date',
                                       'order_estimated_delivery_date'])
rfm        = pd.read_csv(os.path.join(EXPORTS_DIR, 'rfm_segments.csv'))
seg_sum    = pd.read_csv(os.path.join(EXPORTS_DIR, 'rfm_segment_summary.csv'))
churn_df   = pd.read_csv(os.path.join(EXPORTS_DIR, 'churn_analysis.csv'))
churn_sum  = pd.read_csv(os.path.join(EXPORTS_DIR, 'churn_summary.csv'))
monthly    = pd.read_csv(os.path.join(EXPORTS_DIR, 'monthly_revenue.csv'))
cat_rev    = pd.read_csv(os.path.join(EXPORTS_DIR, 'category_revenue.csv'))
state_rev  = pd.read_csv(os.path.join(EXPORTS_DIR, 'state_revenue.csv'))
cohort_m   = pd.read_csv(os.path.join(EXPORTS_DIR, 'cohort_retention_matrix.csv'))
cust_sum   = pd.read_csv(os.path.join(EXPORTS_DIR, 'customer_summary.csv'))

print(f"  master_dataset: {len(df):,} rows")
print(f"  rfm_segments: {len(rfm):,} rows")

# ─── CHART 1: Monthly Revenue Trend ──────────────────────────────────────────
print("\nGenerating charts...")
fig, ax = plt.subplots(figsize=(13, 6))
monthly_sorted = monthly.sort_values('year_month')
x = range(len(monthly_sorted))
rev = monthly_sorted['revenue'].values

ax.fill_between(x, rev, alpha=0.18, color=C_MAIN)
ax.plot(x, rev, marker='o', color=C_MAIN, linewidth=2.2, markersize=5, label='Monthly Revenue')

# Rolling 3-month average
roll3 = pd.Series(rev).rolling(3).mean()
ax.plot(x, roll3, linestyle='--', color=C_RED, linewidth=1.8, alpha=0.85, label='3-Month Rolling Avg')

# Peak annotation
peak_idx = int(np.argmax(rev))
ax.annotate(f"Peak: R${rev[peak_idx]/1e6:.2f}M\n{monthly_sorted['year_month'].values[peak_idx]}",
            xy=(peak_idx, rev[peak_idx]),
            xytext=(peak_idx - 3, rev[peak_idx] * 0.95),
            fontsize=9, color=C_RED, fontweight='bold',
            arrowprops=dict(arrowstyle='->', color=C_RED, lw=1.5))

ax.set_xticks(x)
ax.set_xticklabels(monthly_sorted['year_month'].values, rotation=45, ha='right', fontsize=8)
ax.yaxis.set_major_formatter(mticker.FuncFormatter(fmt_brl))
ax.set_title('Monthly Gross Revenue Trend (Sep 2016 – Aug 2018)', fontsize=14, fontweight='bold', pad=12)
ax.set_xlabel('Month', fontsize=11)
ax.set_ylabel('Revenue (R$)', fontsize=11)
ax.legend(fontsize=10)
fig.tight_layout()
save(fig, 'chart01_monthly_revenue_trend.png')

# ─── CHART 2: Revenue by Product Category (Top 15) ───────────────────────────
fig, ax = plt.subplots(figsize=(12, 8))
top15 = cat_rev.head(15).sort_values('revenue')
colors = [C_MAIN if i < 10 else C_ORANGE for i in range(len(top15))]
bars = ax.barh(top15['product_category_english'], top15['revenue'], color=colors[::-1], edgecolor='white')
for bar, val in zip(bars, top15['revenue']):
    ax.text(bar.get_width() + 5000, bar.get_y() + bar.get_height()/2,
            fmt_brl(val), va='center', fontsize=9, color='#333333')
ax.xaxis.set_major_formatter(mticker.FuncFormatter(fmt_brl))
ax.set_title('Top 15 Product Categories by Revenue', fontsize=14, fontweight='bold', pad=12)
ax.set_xlabel('Total Revenue (R$)', fontsize=11)
ax.set_ylabel('')
fig.tight_layout()
save(fig, 'chart02_category_revenue.png')

# ─── CHART 3: Revenue by State (Top 15) ──────────────────────────────────────
fig, ax = plt.subplots(figsize=(12, 7))
top_states = state_rev.head(15).sort_values('revenue')
bar_colors = [C_RED if i >= 12 else C_MAIN for i in range(len(top_states))]
bars = ax.barh(top_states['customer_state'], top_states['revenue'], color=bar_colors[::-1], edgecolor='white')
for bar, val in zip(bars, top_states['revenue']):
    ax.text(bar.get_width() + 10000, bar.get_y() + bar.get_height()/2,
            fmt_brl(val), va='center', fontsize=9)
ax.xaxis.set_major_formatter(mticker.FuncFormatter(fmt_brl))
ax.set_title('Revenue by Customer State (Top 15)', fontsize=14, fontweight='bold', pad=12)
ax.set_xlabel('Total Revenue (R$)', fontsize=11)
fig.tight_layout()
save(fig, 'chart03_revenue_by_state.png')

# ─── CHART 4: Repeat vs One-Time Customers Donut ─────────────────────────────
repeat    = cust_sum['is_repeat_customer'].sum()
one_time  = len(cust_sum) - repeat
fig, ax = plt.subplots(figsize=(8, 7))
wedges, texts, autotexts = ax.pie(
    [repeat, one_time],
    labels=['Repeat\nCustomers', 'One-Time\nCustomers'],
    autopct='%1.1f%%',
    colors=[C_MAIN, C_ORANGE],
    startangle=90,
    wedgeprops=dict(width=0.52, edgecolor='white', linewidth=2.5),
    textprops={'fontsize': 12}
)
for at in autotexts:
    at.set_fontsize(13)
    at.set_fontweight('bold')
ax.set_title(f'Repeat vs One-Time Customers\n({len(cust_sum):,} total customers)',
             fontsize=13, fontweight='bold', pad=15)
centre = plt.Circle((0,0), 0.35, fc='white')
ax.add_artist(centre)
ax.text(0, 0, f'{one_time/len(cust_sum)*100:.1f}%\nOne-Time', ha='center', va='center',
        fontsize=11, fontweight='bold', color=C_ORANGE)
fig.tight_layout()
save(fig, 'chart04_repeat_vs_onetime_donut.png')

# ─── CHART 5: RFM Segment Customer Count ─────────────────────────────────────
fig, ax = plt.subplots(figsize=(12, 7))
seg_sorted = seg_sum.sort_values('customer_count', ascending=True)
seg_colors = {
    'Champions': '#2A9D8F',         'Loyal Customers': '#2E86AB',
    'Promising': '#457B9D',          'New Customers': '#1D3557',
    'Potential Loyalists': '#E9C46A','At Risk': '#F4A261',
    'Cannot Lose Them': '#E84855',   'Hibernating': '#9E9E9E',
    'Lost Customers': '#616161'
}
colors_list = [seg_colors.get(s, C_MAIN) for s in seg_sorted['segment']]
bars = ax.barh(seg_sorted['segment'], seg_sorted['customer_count'],
               color=colors_list, edgecolor='white', linewidth=1)
for bar, (_, row) in zip(bars, seg_sorted.iterrows()):
    ax.text(bar.get_width() + 100, bar.get_y() + bar.get_height()/2,
            f"{int(row['customer_count']):,}  ({row['pct_customers']:.1f}%)",
            va='center', fontsize=9)
ax.set_title('Customer Count by RFM Segment', fontsize=14, fontweight='bold', pad=12)
ax.set_xlabel('Number of Customers', fontsize=11)
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, p: f'{int(x):,}'))
fig.tight_layout()
save(fig, 'chart05_rfm_segment_customers.png')

# ─── CHART 6: Revenue by RFM Segment ─────────────────────────────────────────
fig, ax = plt.subplots(figsize=(12, 7))
seg_rev = seg_sum.sort_values('total_revenue', ascending=True)
colors_rev = [seg_colors.get(s, C_MAIN) for s in seg_rev['segment']]
bars = ax.barh(seg_rev['segment'], seg_rev['total_revenue'],
               color=colors_rev, edgecolor='white')
for bar, (_, row) in zip(bars, seg_rev.iterrows()):
    ax.text(bar.get_width() + 10000, bar.get_y() + bar.get_height()/2,
            f"{fmt_brl(row['total_revenue'])}  ({row['pct_revenue']:.1f}%)",
            va='center', fontsize=9)
ax.xaxis.set_major_formatter(mticker.FuncFormatter(fmt_brl))
ax.set_title('Total Revenue by RFM Segment', fontsize=14, fontweight='bold', pad=12)
ax.set_xlabel('Total Revenue (R$)', fontsize=11)
fig.tight_layout()
save(fig, 'chart06_rfm_segment_revenue.png')

# ─── CHART 7: Churn Status Distribution ──────────────────────────────────────
fig, ax = plt.subplots(figsize=(8, 7))
churn_colors = {'Active': C_GREEN, 'At Risk': C_ORANGE, 'Churned': C_RED}
churn_sorted = churn_sum.sort_values('customer_count', ascending=False)
wedge_colors = [churn_colors[s] for s in churn_sorted['churn_status']]
wedges, texts, autotexts = ax.pie(
    churn_sorted['customer_count'],
    labels=churn_sorted['churn_status'],
    autopct='%1.1f%%',
    colors=wedge_colors,
    startangle=140,
    wedgeprops=dict(width=0.52, edgecolor='white', linewidth=3),
    textprops={'fontsize': 12}
)
for at in autotexts:
    at.set_fontsize(13); at.set_fontweight('bold')
ax.set_title('Customer Churn Status Distribution\n(as of Aug 2018)',
             fontsize=13, fontweight='bold', pad=15)
centre = plt.Circle((0,0), 0.35, fc='white')
ax.add_artist(centre)
ax.text(0, 0, '93,358\nCustomers', ha='center', va='center',
        fontsize=10, fontweight='bold', color='#333')
fig.tight_layout()
save(fig, 'chart07_churn_status_donut.png')

# ─── CHART 8: Cohort Retention Heatmap ───────────────────────────────────────
# Filter to reasonable cohorts with enough data
cohort_m_indexed = cohort_m.set_index('cohort_month')
# Select month 0-12 columns
month_cols = [c for c in cohort_m_indexed.columns if str(c).lstrip('-').isdigit()
              and 0 <= int(c) <= 12]
month_cols = sorted(month_cols, key=lambda x: int(x))
cohort_m_filtered = cohort_m_indexed[month_cols].fillna(0)
# Filter to cohorts 2017-01 to 2018-06
valid_cohorts = [c for c in cohort_m_filtered.index
                 if '2017' in str(c) or '2018-01' in str(c) or
                 '2018-02' in str(c) or '2018-03' in str(c) or
                 '2018-04' in str(c) or '2018-05' in str(c) or '2018-06' in str(c)]
cohort_plot = cohort_m_filtered.loc[[c for c in valid_cohorts if c in cohort_m_filtered.index]]

if len(cohort_plot) > 0:
    fig, ax = plt.subplots(figsize=(14, max(6, len(cohort_plot) * 0.5)))
    mask = cohort_plot == 0
    sns.heatmap(cohort_plot, annot=True, fmt='.1f', mask=mask,
                cmap='Blues', linewidths=0.3, linecolor='#f0f0f0',
                cbar_kws={'label': 'Retention Rate (%)'},
                ax=ax, annot_kws={'size': 7})
    ax.set_title('Monthly Cohort Retention Matrix (%)\n(Month 0 = First Purchase Month)',
                 fontsize=13, fontweight='bold', pad=12)
    ax.set_xlabel('Months Since First Purchase', fontsize=11)
    ax.set_ylabel('Cohort (Acquisition Month)', fontsize=11)
    ax.tick_params(axis='x', rotation=0)
    ax.tick_params(axis='y', rotation=0)
    fig.tight_layout()
    save(fig, 'chart08_cohort_retention_heatmap.png')

# ─── CHART 9: Delivery Days Distribution ─────────────────────────────────────
fig, ax = plt.subplots(figsize=(12, 6))
delivery = df['delivery_days'].dropna()
delivery = delivery[(delivery > 0) & (delivery < 100)]
ax.hist(delivery, bins=50, color=C_MAIN, alpha=0.8, edgecolor='white')
ax.axvline(delivery.mean(), color=C_RED, linestyle='--', linewidth=2,
           label=f'Mean: {delivery.mean():.1f} days')
ax.axvline(delivery.median(), color=C_ORANGE, linestyle='--', linewidth=2,
           label=f'Median: {delivery.median():.1f} days')
ax.set_title('Delivery Time Distribution (Order Purchase → Customer Delivery)',
             fontsize=13, fontweight='bold', pad=12)
ax.set_xlabel('Delivery Days', fontsize=11)
ax.set_ylabel('Number of Orders', fontsize=11)
ax.legend(fontsize=10)
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, p: f'{int(x):,}'))
fig.tight_layout()
save(fig, 'chart09_delivery_days_distribution.png')

# ─── CHART 10: Payment Type Distribution ─────────────────────────────────────
pay_data  = {'credit_card': 73.9, 'boleto': 19.0, 'voucher': 5.6, 'debit_card': 1.5}
fig, ax = plt.subplots(figsize=(8, 7))
wedges, texts, autotexts = ax.pie(
    list(pay_data.values()),
    labels=[k.replace('_', ' ').title() for k in pay_data.keys()],
    autopct='%1.1f%%',
    colors=[C_MAIN, C_ORANGE, C_GREEN, C_PURPLE],
    startangle=90,
    wedgeprops=dict(width=0.55, edgecolor='white', linewidth=2.5),
    textprops={'fontsize': 11}
)
for at in autotexts:
    at.set_fontsize(12); at.set_fontweight('bold')
ax.set_title('Payment Method Distribution', fontsize=13, fontweight='bold', pad=15)
fig.tight_layout()
save(fig, 'chart10_payment_types.png')

# ─── CHART 11: RFM Avg Metrics by Segment Heatmap ────────────────────────────
metrics_df = seg_sum[['segment','avg_recency','avg_frequency','avg_monetary']].copy()
metrics_df = metrics_df.set_index('segment')
metrics_norm = (metrics_df - metrics_df.min()) / (metrics_df.max() - metrics_df.min())
metrics_norm.columns = ['Avg Recency\n(days)', 'Avg Frequency\n(orders)', 'Avg Monetary\n(R$)']

fig, ax = plt.subplots(figsize=(9, 7))
sns.heatmap(metrics_norm, annot=metrics_df.round(1), fmt='g',
            cmap='YlOrRd', linewidths=0.5, linecolor='white',
            ax=ax, cbar_kws={'label': 'Normalized Score'},
            annot_kws={'size': 9})
ax.set_title('RFM Metrics by Customer Segment\n(values shown; color = normalized intensity)',
             fontsize=12, fontweight='bold', pad=12)
ax.tick_params(axis='x', rotation=0)
ax.tick_params(axis='y', rotation=0)
fig.tight_layout()
save(fig, 'chart11_rfm_metrics_heatmap.png')

# ─── CHART 12: Customer Frequency Distribution ───────────────────────────────
fig, ax = plt.subplots(figsize=(11, 6))
freq_counts = rfm['frequency'].value_counts().sort_index()
freq_filtered = freq_counts[freq_counts.index <= 10]
bars = ax.bar(freq_filtered.index, freq_filtered.values, color=C_MAIN,
              edgecolor='white', linewidth=1)
for bar, (idx, val) in zip(bars, freq_filtered.items()):
    pct = val / len(rfm) * 100
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 300,
            f'{pct:.1f}%', ha='center', va='bottom', fontsize=8.5, fontweight='bold')
ax.set_title('Customer Purchase Frequency Distribution', fontsize=13, fontweight='bold', pad=12)
ax.set_xlabel('Number of Orders', fontsize=11)
ax.set_ylabel('Number of Customers', fontsize=11)
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, p: f'{int(x):,}'))
ax.set_xticks(range(1, 11))
onetime_pct = freq_counts.get(1, 0) / len(rfm) * 100
ax.text(0.98, 0.95, f'{onetime_pct:.1f}% of customers\npurchased only once',
        transform=ax.transAxes, ha='right', va='top', fontsize=10,
        bbox=dict(boxstyle='round,pad=0.4', facecolor=C_ORANGE, alpha=0.3))
fig.tight_layout()
save(fig, 'chart12_purchase_frequency.png')

# ─── CHART 13: Churn by Segment ──────────────────────────────────────────────
churn_segment = churn_df.groupby(['segment','churn_status']).size().unstack(fill_value=0)
churn_segment = churn_segment.reindex(columns=['Active','At Risk','Churned'], fill_value=0)
churn_pct = churn_segment.div(churn_segment.sum(axis=1), axis=0) * 100

fig, ax = plt.subplots(figsize=(12, 7))
churn_pct_sorted = churn_pct.sort_values('Churned', ascending=False)
x = np.arange(len(churn_pct_sorted))
w = 0.65
p1 = ax.bar(x, churn_pct_sorted['Active'],  w, label='Active',  color=C_GREEN)
p2 = ax.bar(x, churn_pct_sorted['At Risk'], w, label='At Risk', color=C_ORANGE,
            bottom=churn_pct_sorted['Active'])
p3 = ax.bar(x, churn_pct_sorted['Churned'], w, label='Churned', color=C_RED,
            bottom=churn_pct_sorted['Active'] + churn_pct_sorted['At Risk'])
ax.set_xticks(x)
ax.set_xticklabels(churn_pct_sorted.index, rotation=30, ha='right', fontsize=9)
ax.set_title('Churn Status by Customer Segment (%)', fontsize=13, fontweight='bold', pad=12)
ax.set_ylabel('Percentage of Customers (%)', fontsize=11)
ax.legend(fontsize=10, loc='upper right')
ax.set_ylim(0, 115)
fig.tight_layout()
save(fig, 'chart13_churn_by_segment.png')

# ─── CHART 14: Monthly New Customers ─────────────────────────────────────────
from pandas import read_csv as _rc
df_cust_m = df.groupby('order_year_month')['customer_unique_id'].nunique().reset_index()
df_cust_m.columns = ['year_month', 'new_customers']
df_cust_m = df_cust_m.sort_values('year_month')

fig, ax = plt.subplots(figsize=(13, 6))
x = range(len(df_cust_m))
ax.bar(x, df_cust_m['new_customers'], color=C_MAIN, alpha=0.85, edgecolor='white')
ax.set_xticks(x)
ax.set_xticklabels(df_cust_m['year_month'], rotation=45, ha='right', fontsize=8)
ax.set_title('Monthly New Customer Acquisition', fontsize=13, fontweight='bold', pad=12)
ax.set_ylabel('Unique Customers', fontsize=11)
ax.set_xlabel('Month', fontsize=11)
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, p: f'{int(x):,}'))
fig.tight_layout()
save(fig, 'chart14_monthly_new_customers.png')

# ─── CHART 15: Avg Monetary by Segment Scatter ───────────────────────────────
fig, ax = plt.subplots(figsize=(11, 7))
for i, (_, row) in enumerate(seg_sum.iterrows()):
    color = seg_colors.get(row['segment'], C_MAIN)
    ax.scatter(row['avg_recency'], row['avg_monetary'],
               s=row['customer_count']/8, alpha=0.75,
               color=color, edgecolors='white', linewidth=1.5, zorder=3)
    ax.annotate(row['segment'],
                xy=(row['avg_recency'], row['avg_monetary']),
                xytext=(6, 4), textcoords='offset points',
                fontsize=9, fontweight='bold', color=color)
ax.set_title('RFM Segments: Recency vs Monetary\n(bubble size = customer count)',
             fontsize=13, fontweight='bold', pad=12)
ax.set_xlabel('Avg Recency (days since last purchase)', fontsize=11)
ax.set_ylabel('Avg Monetary Value (R$)', fontsize=11)
ax.invert_xaxis()
ax.text(0.98, 0.98, '← More Recent', transform=ax.transAxes,
        ha='right', va='top', fontsize=9, color='#666')
fig.tight_layout()
save(fig, 'chart15_rfm_scatter.png')

print("\n✅ All 15 charts generated successfully!")
print(f"   Location: {CHARTS_DIR}")
