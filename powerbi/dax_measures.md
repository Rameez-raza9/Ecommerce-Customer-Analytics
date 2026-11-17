# DAX Measures Reference Guide — E-Commerce Customer Analytics

This document serves as the definitive reference manual for all Data Analysis Expressions (DAX) measures implemented in the **E-Commerce Customer Analytics & Retention Intelligence** Power BI solution. It provides the exact DAX formula, architectural description, performance considerations, and the specific report visuals powered by each measure.

---

## Table of Contents
1. [DAX Modeling Architecture & Conventions](#1-dax-modeling-architecture--conventions)
2. [Executive KPI Measures](#2-executive-kpi-measures)
   - [Total Revenue](#total-revenue)
   - [Total Orders](#total-orders)
   - [Total Customers](#total-customers)
   - [Average Order Value (AOV)](#average-order-value-aov)
   - [Repeat Customers](#repeat-customers)
   - [Repeat Purchase Rate](#repeat-purchase-rate)
   - [Average Customer Revenue](#average-customer-revenue)
   - [Customer Lifetime Value (Simplified CLV)](#customer-lifetime-value-simplified-clv)
   - [Average Purchase Frequency](#average-purchase-frequency)
3. [Time Intelligence Measures](#3-time-intelligence-measures)
   - [Revenue Previous Month](#revenue-previous-month)
   - [MoM Revenue Growth %](#mom-revenue-growth-)
   - [YTD Revenue](#ytd-revenue)
   - [Rolling 3-Month Revenue](#rolling-3-month-revenue)
   - [Orders Previous Month](#orders-previous-month)
   - [MoM Order Growth %](#mom-order-growth-)
   - [YoY Revenue Growth %](#yoy-revenue-growth-)
4. [Customer Acquisition & Retention Dynamics](#4-customer-acquisition--retention-dynamics)
   - [New Customers This Month](#new-customers-this-month)
   - [New Customers Previous Month](#new-customers-previous-month)
   - [MoM New Customer Growth %](#mom-new-customer-growth-)
   - [Repeat Customers This Month](#repeat-customers-this-month)
   - [New vs Repeat Customer Classification](#new-vs-repeat-customer-classification)
5. [Churn & At-Risk Analytics Measures](#5-churn--at-risk-analytics-measures)
   - [Churned Customers Count](#churned-customers-count)
   - [At Risk Customers Count](#at-risk-customers-count)
   - [Active Customers Count](#active-customers-count)
   - [Churn Rate %](#churn-rate-)
   - [Revenue At Risk](#revenue-at-risk)
   - [Revenue Lost to Churn](#revenue-lost-to-churn)
   - [% Revenue at Risk](#-revenue-at-risk)
6. [Cohort Retention Measures](#6-cohort-retention-measures)
   - [Cohort Size](#cohort-size)
   - [Cohort Active Customers](#cohort-active-customers)
   - [Cohort Retention Rate](#cohort-retention-rate)
   - [Cohort Drop-Off Rate](#cohort-drop-off-rate)
7. [RFM Customer Segmentation Measures](#7-rfm-customer-segmentation-measures)
   - [Champions Segment Measures](#champions-segment-measures)
   - [Loyal Customers Segment Measures](#loyal-customers-segment-measures)
   - [Potential Loyalists Segment Measures](#potential-loyalists-segment-measures)
   - [Recent Customers Segment Measures](#recent-customers-segment-measures)
   - [Promising Segment Measures](#promising-segment-measures)
   - [Customers Needing Attention Segment Measures](#customers-needing-attention-segment-measures)
   - [About to Sleep Segment Measures](#about-to-sleep-segment-measures)
   - [At Risk Segment Measures](#at-risk-segment-measures)
   - [Can't Lose Them Segment Measures](#cant-lose-them-segment-measures)
   - [Hibernating Segment Measures](#hibernating-segment-measures)
   - [Lost Segment Measures](#lost-segment-measures)
8. [Product & Category Performance Measures](#8-product--category-performance-measures)
   - [Category Revenue](#category-revenue)
   - [Category AOV](#category-aov)
   - [Category % of Total Revenue](#category--of-total-revenue)
9. [Formatting & Dynamic UI Measures](#9-formatting--dynamic-ui-measures)
   - [Revenue Formatted](#revenue-formatted)
   - [AOV Formatted](#aov-formatted)
   - [Dynamic Slicer Title](#dynamic-slicer-title)
   - [KPI Conditional Formatting Color (Hex)](#kpi-conditional-formatting-color-hex)
10. [Master DAX Measures Catalog](#10-master-dax-measures-catalog)

---

## 1. DAX Modeling Architecture & Conventions

### Dedicated Measures Table (`_Measures`)
All measures are consolidated in a dedicated disconnected table named `_Measures` rather than scattered across data tables. This simplifies model management, improves developer navigation, and ensures clean field list categorization.

```dax
-- Create empty measures table via DAX Table constructor
_Measures = ROW("Description", "Container table for all DAX measures")
```

### Display Folders
Measures are organized into the following Display Folders inside Power BI:
- `01 - Executive KPIs`
- `02 - Time Intelligence`
- `03 - Acquisition & Retention`
- `04 - Churn Analysis`
- `05 - Cohort Retention`
- `06 - RFM Segmentation`
- `07 - Product & Category`
- `08 - UI & Formatting`

### Formatting & Error Handling Rules
1. **Division**: Never use `/` directly. Always use `DIVIDE(Numerator, Denominator, AlternateResult)` to guard against division-by-zero errors.
2. **Filtering**: Use `KEEPFILTERS()` where preserving outer context is critical, and `CALCULATE()` with explicit filter conditions.
3. **Format Strings**: Explicitly define format strings (Currency `$#,##0.00`, Percentage `0.0%`, Integer `#,##0`) in the model properties.

---

## 2. Executive KPI Measures

### Total Revenue
Calculates the aggregate financial value of all transactions whose orders have reached the `delivered` status, ensuring canceled, invoiced, or unavailable orders do not distort recognized revenue.

```dax
Total Revenue = 
SUMX(
    FILTER(
        order_payments, 
        RELATED(orders[order_status]) = "delivered"
    ), 
    order_payments[payment_value]
)
```
- **Explanation**: Iterates through the `order_payments` table, utilizing `RELATED()` across the `order_payments[order_id] -> orders[order_id]` relationship to verify that the corresponding order status is `"delivered"`. It sums the payment value of valid rows.
- **Format**: Currency (`$#,##0.00` or `$#,##0`)
- **Visuals Powered**:
  - Executive Overview: KPI Card 1 (Top Left)
  - Executive Overview: Monthly Revenue Trend (Line Chart Y-Axis)
  - Product & Revenue: Category Revenue Bar Chart
  - All report header cards

---

### Total Orders
Counts the unique number of orders placed across the selected filter context.

```dax
Total Orders = 
DISTINCTCOUNT(orders[order_id])
```
- **Explanation**: Applies a distinct count over `orders[order_id]`. Distinct count is used rather than simple row count to avoid double-counting in views where multiple line items or split payment methods join to a single order.
- **Format**: Whole Number (`#,##0`)
- **Visuals Powered**:
  - Executive Overview: KPI Card 2
  - Executive Overview: Monthly Orders Bar Chart
  - Executive Overview: Orders by State Map

---

### Total Customers
Measures the unique count of underlying individual customers across the dataset.

```dax
Total Customers = 
DISTINCTCOUNT(customers[customer_unique_id])
```
- **Explanation**: In e-commerce datasets (e.g., Olist), a single customer receives a new `customer_id` for every order, but shares a persistent `customer_unique_id`. Performing `DISTINCTCOUNT` on `customer_unique_id` gives the true unique buyer population.
- **Format**: Whole Number (`#,##0`)
- **Visuals Powered**:
  - Executive Overview: KPI Card 3
  - Customer Segmentation: Segment Distribution Donut Chart
  - Retention & Cohort: Customer Base summary

---

### Average Order Value (AOV)
Measures the mean monetary value generated per placed order.

```dax
AOV = 
DIVIDE([Total Revenue], [Total Orders], 0)
```
- **Explanation**: Divides `[Total Revenue]` by `[Total Orders]`. If `[Total Orders]` equals zero (such as in an empty slicer selection), the alternate value `0` is returned to prevent `NaN` or infinity errors.
- **Format**: Currency (`$#,##0.00`)
- **Visuals Powered**:
  - Executive Overview: KPI Card 4
  - Product & Revenue: AOV by Category Bar Chart
  - Customer Segmentation: Segment Metric Comparison Clustered Bar

---

### Repeat Customers
Counts individual unique buyers who have placed more than one purchase in the historical database.

```dax
Repeat Customers = 
CALCULATE(
    DISTINCTCOUNT(customers[customer_unique_id]), 
    FILTER(rfm_results, rfm_results[frequency] > 1)
)
```
- **Explanation**: Context transitions through `CALCULATE()` to filter the `rfm_results` table for customers where lifetime purchase frequency strictly exceeds `1`. It then computes the distinct count of `customer_unique_id`.
- **Format**: Whole Number (`#,##0`)
- **Visuals Powered**:
  - Executive Overview: New vs Repeat Customers Donut Chart
  - Retention & Cohort: Repeat Buyer count card

---

### Repeat Purchase Rate
Calculates the proportion of the unique customer base who are repeat purchasers.

```dax
Repeat Purchase Rate = 
DIVIDE([Repeat Customers], [Total Customers], 0)
```
- **Explanation**: Computes the ratio of `[Repeat Customers]` to `[Total Customers]`. A fundamental benchmark metric in retention intelligence indicating brand loyalty and repurchase stickiness.
- **Format**: Percentage (`0.0%`)
- **Visuals Powered**:
  - Executive Overview: KPI Card 5
  - Retention & Cohort: Page Banner KPI Card

---

### Average Customer Revenue
Measures the lifetime monetary contribution generated by an average unique customer.

```dax
Avg Customer Revenue = 
DIVIDE([Total Revenue], [Total Customers], 0)
```
- **Explanation**: Evaluates total revenue generated divided by unique buyers in the filtered time/category context. Shows how much gross revenue each customer delivers on average.
- **Format**: Currency (`$#,##0.00`)
- **Visuals Powered**:
  - Executive Overview: KPI Card 6
  - Customer Segmentation: Summary Table

---

### Customer Lifetime Value (Simplified CLV)
Calculates an intuitive baseline Customer Lifetime Value using historical AOV and purchase frequency.

```dax
Customer Lifetime Value = 
VAR AvgFrequency = DIVIDE([Total Orders], [Total Customers], 0)
VAR AvgValue = [AOV]
RETURN
    AvgValue * AvgFrequency
```
- **Explanation**: Uses DAX variables (`VAR`) to calculate the average order frequency per customer and multiply it by the Average Order Value (`[AOV]`). This provides a quick, explainable lifetime value benchmark across segments.
- **Format**: Currency (`$#,##0.00`)
- **Visuals Powered**:
  - Customer Segmentation: Segment Value Comparison Clustered Bar
  - Customer Segmentation: Summary Matrix

---

### Average Purchase Frequency
Calculates the mean number of orders placed per customer.

```dax
Avg Purchase Frequency = 
DIVIDE([Total Orders], [Total Customers], 0)
```
- **Explanation**: Normalizes order volume across the unique customer base.
- **Format**: Decimal (`0.00`)
- **Visuals Powered**:
  - Retention & Cohort: Customer Frequency Analysis
  - Segmentation: Value Clustered Bar

---

## 3. Time Intelligence Measures

### Revenue Previous Month
Retrieves the total revenue achieved in the calendar month immediately preceding the currently selected period.

```dax
Revenue Previous Month = 
CALCULATE(
    [Total Revenue], 
    DATEADD(Calendar[Date], -1, MONTH)
)
```
- **Explanation**: Utilizes `DATEADD` over the contiguous `Calendar[Date]` dimension shifted back by one month. Respects all other dimension slicers (e.g. State, Category).
- **Format**: Currency (`$#,##0.00`)
- **Visuals Powered**:
  - Executive Overview: Monthly Revenue Line Chart Tooltips
  - Executive Overview: MoM Variance Indicators

---

### MoM Revenue Growth %
Calculates month-over-month percentage change in delivered revenue.

```dax
MoM Revenue Growth % = 
VAR CurrentRev = [Total Revenue]
VAR PrevRev = [Revenue Previous Month]
RETURN
    DIVIDE(CurrentRev - PrevRev, PrevRev, 0)
```
- **Explanation**: Compares the difference between current month revenue and previous month revenue against previous month revenue. Uses variables to prevent redundant recalculation.
- **Format**: Percentage (`+0.0%;-0.0%;0.0%`)
- **Visuals Powered**:
  - Executive Overview: Monthly Revenue Trend Card Subtitle
  - Executive Overview: KPI Card Callout Value / Indicator

---

### YTD Revenue
Accumulates total delivered revenue from the first day of the active calendar year through the current date context.

```dax
YTD Revenue = 
TOTALYTD(
    [Total Revenue], 
    Calendar[Date]
)
```
- **Explanation**: Uses `TOTALYTD` over `Calendar[Date]`. Calculates cumulative fiscal/calendar year performance up to the maximum date in the current filter context.
- **Format**: Currency (`$#,##0`)
- **Visuals Powered**:
  - Executive Overview: YTD Cumulative Progress Chart
  - Product & Revenue: Annual Budget vs Actual Gauge

---

### Rolling 3-Month Revenue
Calculates total delivered revenue over a trailing 90-day (3 calendar month) window.

```dax
Rolling 3M Revenue = 
CALCULATE(
    [Total Revenue], 
    DATESINPERIOD(
        Calendar[Date], 
        LASTDATE(Calendar[Date]), 
        -3, 
        MONTH
    )
)
```
- **Explanation**: Evaluates `[Total Revenue]` over a continuous date window anchored on the last visible date in the filter context and spanning backwards 3 calendar months. Smooths monthly seasonality fluctuations.
- **Format**: Currency (`$#,##0`)
- **Visuals Powered**:
  - Executive Overview: Smoothed 3-Month Trailing Revenue Trend Line
  - Product & Revenue: Medium-term Momentum Chart

---

### Orders Previous Month
Calculates total orders placed during the preceding calendar month.

```dax
Orders Previous Month = 
CALCULATE(
    [Total Orders], 
    DATEADD(Calendar[Date], -1, MONTH)
)
```
- **Explanation**: Applies `DATEADD` with a `-1, MONTH` shift on `[Total Orders]`.
- **Format**: Whole Number (`#,##0`)
- **Visuals Powered**:
  - Executive Overview: Monthly Orders Bar Chart Tooltips

---

### MoM Order Growth %
Evaluates the month-over-month rate of order volume acceleration or deceleration.

```dax
MoM Order Growth % = 
VAR CurrentOrders = [Total Orders]
VAR PrevOrders = [Orders Previous Month]
RETURN
    DIVIDE(CurrentOrders - PrevOrders, PrevOrders, 0)
```
- **Explanation**: Evaluates percentage growth in order counts compared to the prior calendar month.
- **Format**: Percentage (`+0.0%;-0.0%;0.0%`)
- **Visuals Powered**:
  - Executive Overview: Monthly Orders Bar Chart Subtitle

---

### YoY Revenue Growth %
Measures year-over-year revenue expansion comparing the selected date period against the exact same period one year prior.

```dax
Revenue Same Period Last Year = 
CALCULATE(
    [Total Revenue], 
    SAMEPERIODLASTYEAR(Calendar[Date])
)

YoY Revenue Growth % = 
VAR CurrentRev = [Total Revenue]
VAR PriorYearRev = [Revenue Same Period Last Year]
RETURN
    DIVIDE(CurrentRev - PriorYearRev, PriorYearRev, 0)
```
- **Explanation**: Utilizes `SAMEPERIODLASTYEAR` to compute baseline revenue 12 months prior and assesses the percentage variance.
- **Format**: Percentage (`+0.0%;-0.0%;0.0%`)
- **Visuals Powered**:
  - Executive Overview: Annual Growth Indicator

---

## 4. Customer Acquisition & Retention Dynamics

### New Customers This Month
Identifies customers whose very first purchase in the business occurred within the currently filtered calendar month.

```dax
New Customers This Month = 
CALCULATE(
    [Total Customers],
    FILTER(
        customers,
        VAR CustomerFirstOrderDate = 
            CALCULATE(
                MIN(orders[order_purchase_date]), 
                ALLEXCEPT(orders, orders[customer_id])
            )
        RETURN
            CustomerFirstOrderDate >= MIN(Calendar[Date]) &&
            CustomerFirstOrderDate <= MAX(Calendar[Date])
    )
)
```
- **Explanation**: Finds each customer's global first order purchase date by removing temporal filters with `ALLEXCEPT`. It checks whether that initial purchase falls within the currently filtered calendar interval.
- **Format**: Whole Number (`#,##0`)
- **Visuals Powered**:
  - Executive Overview: New vs Repeat Customers Donut Chart
  - Retention & Cohort: Monthly Acquisition Bar Chart

---

### New Customers Previous Month
Computes the count of newly acquired customers in the prior calendar month.

```dax
New Customers Previous Month = 
CALCULATE(
    [New Customers This Month], 
    DATEADD(Calendar[Date], -1, MONTH)
)
```
- **Explanation**: Re-evaluates `[New Customers This Month]` over the shifted previous month calendar interval.
- **Format**: Whole Number (`#,##0`)
- **Visuals Powered**:
  - Retention & Cohort: MoM Acquisition Performance Card

---

### MoM New Customer Growth %
Measures percentage change in new customer acquisition month over month.

```dax
MoM New Customer Growth % = 
VAR CurrentNew = [New Customers This Month]
VAR PrevNew = [New Customers Previous Month]
RETURN
    DIVIDE(CurrentNew - PrevNew, PrevNew, 0)
```
- **Explanation**: Assesses growth momentum of customer acquisition funnel.
- **Format**: Percentage (`+0.0%;-0.0%;0.0%`)
- **Visuals Powered**:
  - Retention & Cohort: Acquisition Header Indicator

---

### Repeat Customers This Month
Computes the count of active buyers in the current month who had previously placed an order in any prior month.

```dax
Repeat Customers This Month = 
[Total Customers] - [New Customers This Month]
```
- **Explanation**: Subtracts newly acquired customers from total distinct customers active in the current month.
- **Format**: Whole Number (`#,##0`)
- **Visuals Powered**:
  - Executive Overview: New vs Repeat Customers Donut Chart

---

### New vs Repeat Customer Classification
Provides a categorical flag for dynamic visual grouping.

```dax
New vs Repeat Breakdown = 
IF(
    SELECTEDVALUE(rfm_results[frequency], 1) > 1, 
    "Repeat Customer", 
    "New Customer"
)
```
- **Explanation**: Evaluates customer purchase frequency to categorize buyers into `"Repeat Customer"` vs `"New Customer"`.
- **Format**: Text
- **Visuals Powered**:
  - Executive Overview: Donut Chart Legend & Slicer

---

## 5. Churn & At-Risk Analytics Measures

### Churned Customers Count
Counts customers classified as `"Churned"` based on dormancy threshold (e.g., > 180 or 270 days since last purchase).

```dax
Churned Customers = 
CALCULATE(
    COUNTROWS(churn_results), 
    churn_results[churn_status] = "Churned"
)
```
- **Explanation**: Evaluates row count in `churn_results` where the `churn_status` attribute equals `"Churned"`.
- **Format**: Whole Number (`#,##0`)
- **Visuals Powered**:
  - Churn Analysis: Churn Status Donut Chart
  - Churn Analysis: Page KPI Card

---

### At Risk Customers Count
Counts customers whose inactivity window indicates high probability of impending attrition.

```dax
At Risk Customers = 
CALCULATE(
    COUNTROWS(churn_results), 
    churn_results[churn_status] = "At Risk"
)
```
- **Explanation**: Filters `churn_results` for rows where `churn_status` equals `"At Risk"`.
- **Format**: Whole Number (`#,##0`)
- **Visuals Powered**:
  - Churn Analysis: At-Risk Customer Count Card
  - Churn Analysis: Churn Status Donut Chart

---

### Active Customers Count
Counts healthy, engaged customers who have purchased recently and display low churn probability.

```dax
Active Customers = 
CALCULATE(
    COUNTROWS(churn_results), 
    churn_results[churn_status] = "Active"
)
```
- **Explanation**: Filters `churn_results` for rows where `churn_status` equals `"Active"`.
- **Format**: Whole Number (`#,##0`)
- **Visuals Powered**:
  - Churn Analysis: Churn Status Donut Chart

---

### Churn Rate %
Evaluates the percentage of the customer base that has transitioned into churned status.

```dax
Churn Rate = 
DIVIDE([Churned Customers], [Total Customers], 0)
```
- **Explanation**: Divides `[Churned Customers]` by `[Total Customers]`.
- **Format**: Percentage (`0.0%`)
- **Visuals Powered**:
  - Churn Analysis: Churn Rate KPI Gauge / Card
  - Churn Analysis: State-Level Churn Bar Chart

---

### Revenue At Risk
Aggregates historical revenue contributed by customers categorized as `"At Risk"`.

```dax
Revenue At Risk = 
CALCULATE(
    SUM(churn_results[total_revenue]), 
    churn_results[churn_status] = "At Risk"
)
```
- **Explanation**: Sums the `total_revenue` column of `churn_results` for all customers marked as `"At Risk"`. Represents the immediate financial exposure if retention interventions are not executed.
- **Format**: Currency (`$#,##0`)
- **Visuals Powered**:
  - Churn Analysis: Primary KPI Callout Card (Highlighted in Orange `#F39C12`)
  - Executive Overview: At-Risk Exposure Subtitle

---

### Revenue Lost to Churn
Aggregates historical revenue contributed by customers who are fully churned.

```dax
Revenue Lost to Churn = 
CALCULATE(
    SUM(churn_results[total_revenue]), 
    churn_results[churn_status] = "Churned"
)
```
- **Explanation**: Sums `churn_results[total_revenue]` for churned records.
- **Format**: Currency (`$#,##0`)
- **Visuals Powered**:
  - Churn Analysis: Lost Revenue Exposure Card (Highlighted in Red `#E94560`)

---

### % Revenue at Risk
Calculates what percentage of total historical customer revenue is currently sitting in the At-Risk bucket.

```dax
% Revenue at Risk = 
VAR TotalHistoricalRevenue = CALCULATE(SUM(churn_results[total_revenue]), ALL(churn_results))
RETURN
    DIVIDE([Revenue At Risk], TotalHistoricalRevenue, 0)
```
- **Explanation**: Divides `[Revenue At Risk]` by total historical revenue across all churn categories using `ALL()`.
- **Format**: Percentage (`0.0%`)
- **Visuals Powered**:
  - Churn Analysis: At-Risk Revenue Subtitle Indicator

---

## 6. Cohort Retention Measures

### Cohort Size
Determines the baseline volume of unique customers acquired in Month 0 of each acquisition cohort.

```dax
Cohort Size = 
CALCULATE(
    [Total Customers], 
    cohort_retention[month_number] = 0
)
```
- **Explanation**: Evaluates `[Total Customers]` where `cohort_retention[month_number] = 0`. In a cohort matrix, Month 0 represents 100% of the newly acquired cohort base.
- **Format**: Whole Number (`#,##0`)
- **Visuals Powered**:
  - Retention & Cohort: Cohort Matrix Table (Column 0 / Baseline)
  - Retention & Cohort: Cohort Size Card

---

### Cohort Active Customers
Counts unique customers who returned and placed a purchase during month index `N` following initial acquisition.

```dax
Cohort Active Customers = 
CALCULATE(
    SUM(cohort_retention[active_customers])
)
```
- **Explanation**: Sums `cohort_retention[active_customers]` across the active row/column intersection of cohort month and lifecycle month offset.
- **Format**: Whole Number (`#,##0`)
- **Visuals Powered**:
  - Retention & Cohort: Cohort Matrix Table (Absolute Customer View)

---

### Cohort Retention Rate
Measures the percentage of the original cohort retained during month index `N`.

```dax
Cohort Retention Rate = 
DIVIDE(
    [Cohort Active Customers], 
    [Cohort Size], 
    0
)
```
- **Explanation**: Divides active returning customers in month `N` by baseline `[Cohort Size]`.
- **Format**: Percentage (`0.0%`)
- **Visuals Powered**:
  - Retention & Cohort: Cohort Matrix Table (Heatmap with conditional background formatting)
  - Retention & Cohort: Retention Decay Curves (Line Chart across Month 0 to Month 12)

---

### Cohort Drop-Off Rate
Calculates customer attrition from Month 0 to Month `N`.

```dax
Cohort Drop-Off Rate = 
1 - [Cohort Retention Rate]
```
- **Explanation**: Subtracts the retention rate from 1.0 (100%).
- **Format**: Percentage (`0.0%`)
- **Visuals Powered**:
  - Retention & Cohort: Drop-Off Area Chart

---

## 7. RFM Customer Segmentation Measures

The RFM model categorizes customers into 11 distinct operational segments based on Recency, Frequency, and Monetary scores. Below are the complete, production-ready DAX measures for every single segment.

### Champions Segment Measures
*Definition: Highest recency, highest frequency, highest monetary value. The most valuable customer cohort.*

```dax
-- Champions Revenue
Champions Revenue = 
CALCULATE(
    [Total Revenue], 
    rfm_results[segment] = "Champions"
)

-- Champions % of Revenue
Champions % of Revenue = 
DIVIDE([Champions Revenue], [Total Revenue], 0)

-- Champions Customer Count
Champions Customers = 
CALCULATE(
    [Total Customers], 
    rfm_results[segment] = "Champions"
)

-- Champions % of Customers
Champions % of Customers = 
DIVIDE([Champions Customers], [Total Customers], 0)
```
- **Visuals Powered**: Customer Segmentation Page (Summary Table, Segment Donut, Clustered Bar).

---

### Loyal Customers Segment Measures
*Definition: High frequency, solid recency, strong spenders. Consistent brand advocates.*

```dax
-- Loyal Customers Revenue
Loyal Customers Revenue = 
CALCULATE(
    [Total Revenue], 
    rfm_results[segment] = "Loyal Customers"
)

-- Loyal Customers % of Revenue
Loyal Customers % of Revenue = 
DIVIDE([Loyal Customers Revenue], [Total Revenue], 0)

-- Loyal Customers Customer Count
Loyal Customers Count = 
CALCULATE(
    [Total Customers], 
    rfm_results[segment] = "Loyal Customers"
)

-- Loyal Customers % of Customers
Loyal Customers % of Customers = 
DIVIDE([Loyal Customers Count], [Total Customers], 0)
```
- **Visuals Powered**: Customer Segmentation Page (Segment Table, Donut Chart).

---

### Potential Loyalists Segment Measures
*Definition: Recent buyers with above-average spend and 1-2 orders. High upside for upselling.*

```dax
-- Potential Loyalists Revenue
Potential Loyalists Revenue = 
CALCULATE(
    [Total Revenue], 
    rfm_results[segment] = "Potential Loyalists"
)

-- Potential Loyalists % of Revenue
Potential Loyalists % of Revenue = 
DIVIDE([Potential Loyalists Revenue], [Total Revenue], 0)

-- Potential Loyalists Customer Count
Potential Loyalists Customers = 
CALCULATE(
    [Total Customers], 
    rfm_results[segment] = "Potential Loyalists"
)

-- Potential Loyalists % of Customers
Potential Loyalists % of Customers = 
DIVIDE([Potential Loyalists Customers], [Total Customers], 0)
```
- **Visuals Powered**: Customer Segmentation Page.

---

### Recent Customers Segment Measures
*Definition: First-time buyers who made an order very recently. High potential for cross-sell onboarding.*

```dax
-- Recent Customers Revenue
Recent Customers Revenue = 
CALCULATE(
    [Total Revenue], 
    rfm_results[segment] = "Recent Customers"
)

-- Recent Customers % of Revenue
Recent Customers % of Revenue = 
DIVIDE([Recent Customers Revenue], [Total Revenue], 0)

-- Recent Customers Customer Count
Recent Customers Count = 
CALCULATE(
    [Total Customers], 
    rfm_results[segment] = "Recent Customers"
)

-- Recent Customers % of Customers
Recent Customers % of Customers = 
DIVIDE([Recent Customers Count], [Total Customers], 0)
```
- **Visuals Powered**: Customer Segmentation Page.

---

### Promising Segment Measures
*Definition: Bought recently with moderate spend, but low purchase frequency.*

```dax
-- Promising Revenue
Promising Revenue = 
CALCULATE(
    [Total Revenue], 
    rfm_results[segment] = "Promising"
)

-- Promising % of Revenue
Promising % of Revenue = 
DIVIDE([Promising Revenue], [Total Revenue], 0)

-- Promising Customer Count
Promising Customers = 
CALCULATE(
    [Total Customers], 
    rfm_results[segment] = "Promising"
)

-- Promising % of Customers
Promising % of Customers = 
DIVIDE([Promising Customers], [Total Customers], 0)
```
- **Visuals Powered**: Customer Segmentation Page.

---

### Customers Needing Attention Segment Measures
*Definition: Average recency, frequency, and monetary values. At risk of drifting into dormancy.*

```dax
-- Customers Needing Attention Revenue
Customers Needing Attention Revenue = 
CALCULATE(
    [Total Revenue], 
    rfm_results[segment] = "Customers Needing Attention"
)

-- Customers Needing Attention % of Revenue
Customers Needing Attention % of Revenue = 
DIVIDE([Customers Needing Attention Revenue], [Total Revenue], 0)

-- Customers Needing Attention Customer Count
Customers Needing Attention Count = 
CALCULATE(
    [Total Customers], 
    rfm_results[segment] = "Customers Needing Attention"
)

-- Customers Needing Attention % of Customers
Customers Needing Attention % of Customers = 
DIVIDE([Customers Needing Attention Count], [Total Customers], 0)
```
- **Visuals Powered**: Customer Segmentation Page.

---

### About to Sleep Segment Measures
*Definition: Below-average recency and frequency. Will churn permanently if not re-engaged soon.*

```dax
-- About to Sleep Revenue
About to Sleep Revenue = 
CALCULATE(
    [Total Revenue], 
    rfm_results[segment] = "About to Sleep"
)

-- About to Sleep % of Revenue
About to Sleep % of Revenue = 
DIVIDE([About to Sleep Revenue], [Total Revenue], 0)

-- About to Sleep Customer Count
About to Sleep Customers = 
CALCULATE(
    [Total Customers], 
    rfm_results[segment] = "About to Sleep"
)

-- About to Sleep % of Customers
About to Sleep % of Customers = 
DIVIDE([About to Sleep Customers], [Total Customers], 0)
```
- **Visuals Powered**: Customer Segmentation Page.

---

### At Risk Segment Measures
*Definition: Purchased frequently and spent heavily in the past, but have not ordered in a long time.*

```dax
-- At Risk Segment Revenue
At Risk Segment Revenue = 
CALCULATE(
    [Total Revenue], 
    rfm_results[segment] = "At Risk"
)

-- At Risk Segment % of Revenue
At Risk Segment % of Revenue = 
DIVIDE([At Risk Segment Revenue], [Total Revenue], 0)

-- At Risk Segment Customer Count
At Risk Segment Customers = 
CALCULATE(
    [Total Customers], 
    rfm_results[segment] = "At Risk"
)

-- At Risk Segment % of Customers
At Risk Segment % of Customers = 
DIVIDE([At Risk Segment Customers], [Total Customers], 0)
```
- **Visuals Powered**: Customer Segmentation Page & Churn Analysis Page.

---

### Can't Lose Them Segment Measures
*Definition: Former VIPs who generated major revenue and high order counts, but haven't bought in months.*

```dax
-- Can't Lose Them Revenue
Cant Lose Them Revenue = 
CALCULATE(
    [Total Revenue], 
    rfm_results[segment] = "Can't Lose Them"
)

-- Can't Lose Them % of Revenue
Cant Lose Them % of Revenue = 
DIVIDE([Cant Lose Them Revenue], [Total Revenue], 0)

-- Can't Lose Them Customer Count
Cant Lose Them Customers = 
CALCULATE(
    [Total Customers], 
    rfm_results[segment] = "Can't Lose Them"
)

-- Can't Lose Them % of Customers
Cant Lose Them % of Customers = 
DIVIDE([Cant Lose Them Customers], [Total Customers], 0)
```
- **Visuals Powered**: Customer Segmentation Page & Churn Analysis Page.

---

### Hibernating Segment Measures
*Definition: Low recency, low frequency, low monetary spend. Have been dormant for an extended period.*

```dax
-- Hibernating Revenue
Hibernating Revenue = 
CALCULATE(
    [Total Revenue], 
    rfm_results[segment] = "Hibernating"
)

-- Hibernating % of Revenue
Hibernating % of Revenue = 
DIVIDE([Hibernating Revenue], [Total Revenue], 0)

-- Hibernating Customer Count
Hibernating Customers = 
CALCULATE(
    [Total Customers], 
    rfm_results[segment] = "Hibernating"
)

-- Hibernating % of Customers
Hibernating % of Customers = 
DIVIDE([Hibernating Customers], [Total Customers], 0)
```
- **Visuals Powered**: Customer Segmentation Page.

---

### Lost Segment Measures
*Definition: Lowest recency, frequency, and monetary scores. Long-departed buyers.*

```dax
-- Lost Segment Revenue
Lost Revenue = 
CALCULATE(
    [Total Revenue], 
    rfm_results[segment] = "Lost"
)

-- Lost Segment % of Revenue
Lost % of Revenue = 
DIVIDE([Lost Revenue], [Total Revenue], 0)

-- Lost Customer Count
Lost Customers = 
CALCULATE(
    [Total Customers], 
    rfm_results[segment] = "Lost"
)

-- Lost % of Customers
Lost % of Customers = 
DIVIDE([Lost Customers], [Total Customers], 0)
```
- **Visuals Powered**: Customer Segmentation Page.

---

## 8. Product & Category Performance Measures

### Category Revenue
Calculates total delivered revenue generated within a product category.

```dax
Category Revenue = 
CALCULATE(
    [Total Revenue],
    USERELATIONSHIP(order_items[order_id], orders[order_id])
)
```
- **Explanation**: Ensures active traversal through the product/items relationship to aggregate payments attributable to specific product categories.
- **Format**: Currency (`$#,##0`)
- **Visuals Powered**:
  - Page 1 & Page 5: Top 15 Product Categories Bar Chart

---

### Category AOV
Calculates Average Order Value specific to product categories.

```dax
Category AOV = 
DIVIDE([Category Revenue], [Total Orders], 0)
```
- **Explanation**: Normalizes category revenue against order volume in that category.
- **Format**: Currency (`$#,##0.00`)
- **Visuals Powered**:
  - Page 5: AOV by Category Bar Chart

---

### Category % of Total Revenue
Computes the category's share of overall business revenue across all categories.

```dax
Category % of Total Revenue = 
DIVIDE(
    [Total Revenue], 
    CALCULATE([Total Revenue], ALL(order_items[product_category_name])), 
    0
)
```
- **Explanation**: Uses `ALL(order_items[product_category_name])` in the denominator to remove the visual filter on category, yielding true percentage of portfolio revenue.
- **Format**: Percentage (`0.0%`)
- **Visuals Powered**:
  - Page 5: Category Pareto Analysis

---

## 9. Formatting & Dynamic UI Measures

### Revenue Formatted
Produces an elegant, condensed string representation of revenue for dashboard header cards (e.g., `$1.45M`, `$320.5K`, `$850.00`).

```dax
Revenue Formatted = 
VAR Rev = [Total Revenue]
RETURN
    SWITCH(
        TRUE(),
        ISBLANK(Rev) || Rev = 0, "$0.00",
        Rev >= 1000000, "$" & FORMAT(Rev / 1000000, "#,##0.00") & "M",
        Rev >= 1000, "$" & FORMAT(Rev / 1000, "#,##0.0") & "K",
        "$" & FORMAT(Rev, "#,##0.00")
    )
```
- **Explanation**: Uses `SWITCH(TRUE(), ...)` to inspect the numeric magnitude of `[Total Revenue]` and appends `"M"` or `"K"` suffixes with controlled decimal precision.
- **Format**: Text
- **Visuals Powered**:
  - Executive Overview: Custom KPI Header Callouts
  - Mobile Optimized Views

---

### AOV Formatted
Produces a clean formatted string for Average Order Value.

```dax
AOV Formatted = 
"$" & FORMAT([AOV], "#,##0.00")
```
- **Explanation**: Applies explicit dollar formatting to the AOV measure.
- **Format**: Text
- **Visuals Powered**:
  - Executive Overview: KPI Card Subtitle

---

### Dynamic Slicer Title
Dynamically updates visual titles to reflect active slicer filters.

```dax
Dynamic Header Title = 
VAR SelectedState = SELECTEDVALUE(customers[customer_state], "All States")
VAR StartDate = FORMAT(MIN(Calendar[Date]), "MMM yyyy")
VAR EndDate = FORMAT(MAX(Calendar[Date]), "MMM yyyy")
RETURN
    "Executive Overview: " & SelectedState & " (" & StartDate & " - " & EndDate & ")"
```
- **Explanation**: Reads `SELECTEDVALUE` from the State slicer and min/max date context from the Calendar table to generate a responsive title.
- **Format**: Text
- **Visuals Powered**:
  - Executive Overview: Page Banner Title

---

### KPI Conditional Formatting Color (Hex)
Returns dynamic hex color codes for background or font conditional formatting on KPI change cards.

```dax
MoM Revenue Color = 
VAR Growth = [MoM Revenue Growth %]
RETURN
    SWITCH(
        TRUE(),
        Growth > 0, "#00B894",    -- Emerald Green (Positive)
        Growth < 0, "#E94560",    -- Coral Red (Negative)
        "#A0A0B0"                 -- Muted Grey (Neutral / Zero)
    )
```
- **Explanation**: Dynamically evaluates the sign of `[MoM Revenue Growth %]` and outputs theme-matched hexadecimal color strings.
- **Format**: Text / Hex Color
- **Visuals Powered**:
  - Executive Overview: KPI Card Subtext Color
  - Time Series Table: MoM Growth Cell Background / Font

---

## 10. Master DAX Measures Catalog

| Measure Name | Display Folder | Return Type | Format String | Primary Visual Location |
| :--- | :--- | :--- | :--- | :--- |
| **Total Revenue** | `01 - Executive KPIs` | Currency | `$#,##0.00` | Page 1 Card 1, Page 5 Category Chart |
| **Total Orders** | `01 - Executive KPIs` | Integer | `#,##0` | Page 1 Card 2, Monthly Orders Bar |
| **Total Customers** | `01 - Executive KPIs` | Integer | `#,##0` | Page 1 Card 3, Page 2 Donut |
| **AOV** | `01 - Executive KPIs` | Currency | `$#,##0.00` | Page 1 Card 4, Page 5 AOV Bar |
| **Repeat Customers** | `01 - Executive KPIs` | Integer | `#,##0` | Page 1 Donut, Page 3 KPI Card |
| **Repeat Purchase Rate** | `01 - Executive KPIs` | Percentage | `0.0%` | Page 1 Card 5, Page 3 Banner |
| **Avg Customer Revenue** | `01 - Executive KPIs` | Currency | `$#,##0.00` | Page 1 Card 6, Page 2 Table |
| **Customer Lifetime Value** | `01 - Executive KPIs` | Currency | `$#,##0.00` | Page 2 Value Clustered Bar |
| **Avg Purchase Frequency** | `01 - Executive KPIs` | Decimal | `0.00` | Page 3 Frequency Bar Chart |
| **Revenue Previous Month** | `02 - Time Intelligence` | Currency | `$#,##0.00` | Page 1 Line Chart Tooltip |
| **MoM Revenue Growth %** | `02 - Time Intelligence` | Percentage | `+0.0%;-0.0%;0.0%` | Page 1 KPI Card Subtitle |
| **YTD Revenue** | `02 - Time Intelligence` | Currency | `$#,##0` | Page 1 Cumulative Progress |
| **Rolling 3M Revenue** | `02 - Time Intelligence` | Currency | `$#,##0` | Page 1 Smoothed Trend Line |
| **Orders Previous Month** | `02 - Time Intelligence` | Integer | `#,##0` | Page 1 Bar Tooltips |
| **MoM Order Growth %** | `02 - Time Intelligence` | Percentage | `+0.0%;-0.0%;0.0%` | Page 1 Bar Subtitle |
| **YoY Revenue Growth %** | `02 - Time Intelligence` | Percentage | `+0.0%;-0.0%;0.0%` | Page 1 Header Indicator |
| **New Customers This Month** | `03 - Acquisition & Retention`| Integer | `#,##0` | Page 1 Donut, Page 3 Line Chart |
| **New Customers Previous Month**| `03 - Acquisition & Retention`| Integer | `#,##0` | Page 3 Acquisition Card |
| **MoM New Customer Growth %** | `03 - Acquisition & Retention`| Percentage | `+0.0%;-0.0%;0.0%` | Page 3 Acquisition Header |
| **Repeat Customers This Month**| `03 - Acquisition & Retention`| Integer | `#,##0` | Page 1 Donut Chart |
| **Churned Customers** | `04 - Churn Analysis` | Integer | `#,##0` | Page 4 Donut Chart, Page 4 Card |
| **At Risk Customers** | `04 - Churn Analysis` | Integer | `#,##0` | Page 4 Donut Chart, Page 4 Card |
| **Active Customers** | `04 - Churn Analysis` | Integer | `#,##0` | Page 4 Donut Chart |
| **Churn Rate** | `04 - Churn Analysis` | Percentage | `0.0%` | Page 4 Gauge / Card |
| **Revenue At Risk** | `04 - Churn Analysis` | Currency | `$#,##0` | Page 4 Card (Highlighted `#F39C12`) |
| **Revenue Lost to Churn** | `04 - Churn Analysis` | Currency | `$#,##0` | Page 4 Card (Highlighted `#E94560`) |
| **% Revenue at Risk** | `04 - Churn Analysis` | Percentage | `0.0%` | Page 4 Subtitle Indicator |
| **Cohort Size** | `05 - Cohort Retention` | Integer | `#,##0` | Page 3 Cohort Matrix Month 0 |
| **Cohort Active Customers** | `05 - Cohort Retention` | Integer | `#,##0` | Page 3 Cohort Matrix Numbers |
| **Cohort Retention Rate** | `05 - Cohort Retention` | Percentage | `0.0%` | Page 3 Cohort Matrix Heatmap |
| **Cohort Drop-Off Rate** | `05 - Cohort Retention` | Percentage | `0.0%` | Page 3 Drop-Off Area Chart |
| **Champions Revenue** | `06 - RFM Segmentation` | Currency | `$#,##0` | Page 2 Segment Bar & Matrix |
| **Champions % of Revenue** | `06 - RFM Segmentation` | Percentage | `0.0%` | Page 2 Segment Matrix |
| **Loyal Customers Revenue** | `06 - RFM Segmentation` | Currency | `$#,##0` | Page 2 Segment Bar & Matrix |
| **Loyal Customers % of Revenue**| `06 - RFM Segmentation` | Percentage | `0.0%` | Page 2 Segment Matrix |
| **Potential Loyalists Revenue**| `06 - RFM Segmentation` | Currency | `$#,##0` | Page 2 Segment Bar & Matrix |
| **Potential Loyalists % of Rev**| `06 - RFM Segmentation` | Percentage | `0.0%` | Page 2 Segment Matrix |
| **Recent Customers Revenue** | `06 - RFM Segmentation` | Currency | `$#,##0` | Page 2 Segment Bar & Matrix |
| **Promising Revenue** | `06 - RFM Segmentation` | Currency | `$#,##0` | Page 2 Segment Bar & Matrix |
| **Customers Needing Attention Rev**| `06 - RFM Segmentation` | Currency | `$#,##0` | Page 2 Segment Bar & Matrix |
| **About to Sleep Revenue** | `06 - RFM Segmentation` | Currency | `$#,##0` | Page 2 Segment Bar & Matrix |
| **At Risk Segment Revenue** | `06 - RFM Segmentation` | Currency | `$#,##0` | Page 2 & Page 4 Matrix |
| **Can't Lose Them Revenue** | `06 - RFM Segmentation` | Currency | `$#,##0` | Page 2 & Page 4 Matrix |
| **Hibernating Revenue** | `06 - RFM Segmentation` | Currency | `$#,##0` | Page 2 Segment Bar & Matrix |
| **Lost Revenue** | `06 - RFM Segmentation` | Currency | `$#,##0` | Page 2 Segment Bar & Matrix |
| **Category Revenue** | `07 - Product & Category` | Currency | `$#,##0` | Page 1 & Page 5 Category Bar |
| **Category AOV** | `07 - Product & Category` | Currency | `$#,##0.00` | Page 5 Category AOV Bar |
| **Category % of Total Revenue**| `07 - Product & Category` | Percentage | `0.0%` | Page 5 Pareto Visual |
| **Revenue Formatted** | `08 - UI & Formatting` | Text | `@` | Mobile Cards & Page Banners |
| **AOV Formatted** | `08 - UI & Formatting` | Text | `@` | Visual Cards |
| **Dynamic Header Title** | `08 - UI & Formatting` | Text | `@` | Page 1 Banner Header |
| **MoM Revenue Color** | `08 - UI & Formatting` | Text / Hex | `@` | Conditional Formatting Rules |
