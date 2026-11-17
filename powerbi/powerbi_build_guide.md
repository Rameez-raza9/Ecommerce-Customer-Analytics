# Power BI Dashboard Build Guide: E-Commerce Customer Analytics & Retention Intelligence

This document is an exhaustive, production-grade implementation guide for building the complete **E-Commerce Customer Analytics & Retention Intelligence** dashboard in Microsoft Power BI Desktop. Every data transformation, relationship cardinality, M query, DAX assignment, visual layout, and theme setting is documented with granular precision to enable exact replication.

---

## Table of Contents
1. [Prerequisites & Environment Setup](#1-prerequisites--environment-setup)
2. [Data Source Inventory & Import Procedure](#2-data-source-inventory--import-procedure)
3. [Power Query Data Transformations](#3-power-query-data-transformations)
4. [Data Model Architecture & Relationship Setup](#4-data-model-architecture--relationship-setup)
5. [Calendar Dimension Table (Power Query M Code)](#5-calendar-dimension-table-power-query-m-code)
6. [Page 1: Executive Overview — Visual Specifications](#6-page-1-executive-overview--visual-specifications)
7. [Page 2: Customer Segmentation — Visual Specifications](#7-page-2-customer-segmentation--visual-specifications)
8. [Page 3: Retention & Cohort Analytics — Visual Specifications](#8-page-3-retention--cohort-analytics--visual-specifications)
9. [Page 4: Churn Intelligence — Visual Specifications](#9-page-4-churn-intelligence--visual-specifications)
10. [Page 5: Product & Category Revenue — Visual Specifications](#10-page-5-product--category-revenue--visual-specifications)
11. [Design System, Dark Theme & Formatting Standards](#11-design-system-dark-theme--formatting-standards)
12. [Publishing, Scheduled Refresh & Service Configuration](#12-publishing-scheduled-refresh--service-configuration)

---

## 1. Prerequisites & Environment Setup

### Required Software & Versioning
- **Microsoft Power BI Desktop**: 64-bit edition (December 2023 release or newer).
- **Operating System**: Windows 10/11 or Windows Server 2019/2022.
- **Display Resolution**: Optimized for 1920 × 1080 (16:9 widescreen canvas standard).
- **Global Options & Data Load Settings**:
  1. Open Power BI Desktop.
  2. Navigate to **File > Options and settings > Options**.
  3. Under **Global > Data Load**:
     - Uncheck *"Type detection"* -> Set to *"Never detect column types and headers for unstructured sources"* (allows explicit control in Power Query).
     - Uncheck *"Auto date/time"* under **Current File > Data Load** (critical: disables hidden auto-calendar tables, optimizing memory and model cleanliness).
  4. Under **Current File > Regional Settings**:
     - Locale for import: `English (United States)` to properly parse standard ISO dates and decimal points (`.` vs `,`).

### Project Folder Structure
Ensure the source directory contains the exported datasets in CSV format:
```text
Ecommerce-Customer-Analytics/
├── exports/
│   ├── orders.csv
│   ├── customers.csv
│   ├── order_items.csv
│   ├── order_payments.csv
│   ├── rfm_results.csv
│   ├── churn_results.csv
│   └── cohort_retention.csv
└── powerbi/
    ├── dax_measures.md
    ├── powerbi_build_guide.md
    └── data_model.md
```

---

## 2. Data Source Inventory & Import Procedure

### Parameterized Root Directory Pattern
To prevent hardcoded local file paths from breaking across developer environments, define a Power Query Parameter named `SourceFolderPath`:
1. In Power BI Desktop, click **Home > Transform Data** to open the Power Query Editor.
2. In the Home ribbon, click **Manage Parameters > New Parameter**:
   - **Name**: `SourceFolderPath`
   - **Description**: Absolute folder path containing export CSVs.
   - **Type**: `Text`
   - **Current Value**: `c:\Users\ramee\Downloads\e commerce\Ecommerce-Customer-Analytics\exports\` (include trailing backslash).

### Importing Each CSV File
For each file listed below, click **New Source > CSV**, browse to the file, and click **Transform Data**:

1. `orders.csv`: Primary transactional header table.
2. `customers.csv`: Customer registry connecting order tokens to persistent identity tokens.
3. `order_items.csv`: Transaction line items linking orders to individual products, prices, and freight.
4. `order_payments.csv`: Financial settlement ledger detailing payment types, installments, and values.
5. `rfm_results.csv`: Analytical table containing Recency, Frequency, Monetary metrics, individual scores, and RFM segment labels.
6. `churn_results.csv`: Customer-level retention status (`Active`, `At Risk`, `Churned`) with risk scores and historical spend.
7. `cohort_retention.csv`: Cohort lifecycle matrix dataset detailing cohort months, period indices (0–12+), active customer counts, and retention percentages.

---

## 3. Power Query Transformations

Apply the following transformation steps to each query in the Power Query Editor (View Advanced Editor to confirm M code syntax):

### 3.1 Table: `orders`
```powerquery
let
    Source = Csv.Document(File.Contents(SourceFolderPath & "orders.csv"), [Delimiter=",", Columns=8, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    PromoteHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangeTypes = Table.TransformColumnTypes(PromoteHeaders, {
        {"order_id", type text},
        {"customer_id", type text},
        {"order_status", type text},
        {"order_purchase_timestamp", type datetime},
        {"order_approved_at", type datetime},
        {"order_delivered_carrier_date", type datetime},
        {"order_delivered_customer_date", type datetime},
        {"order_estimated_delivery_date", type datetime}
    }),
    AddPurchaseDate = Table.AddColumn(ChangeTypes, "order_purchase_date", each DateTime.Date([order_purchase_timestamp]), type date),
    FilterValidStatus = Table.SelectRows(AddPurchaseDate, each ([order_status] <> null and [order_status] <> ""))
in
    FilterValidStatus
```
- **Key Step**: `order_purchase_date` is extracted as a pure Date type to establish a clean `1:*` relationship with the Calendar dimension.

### 3.2 Table: `customers`
```powerquery
let
    Source = Csv.Document(File.Contents(SourceFolderPath & "customers.csv"), [Delimiter=",", Columns=5, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    PromoteHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangeTypes = Table.TransformColumnTypes(PromoteHeaders, {
        {"customer_id", type text},
        {"customer_unique_id", type text},
        {"customer_zip_code_prefix", type text},
        {"customer_city", type text},
        {"customer_state", type text}
    }),
    CleanCity = Table.TransformColumns(ChangeTypes, {{"customer_city", Text.Proper, type text}}),
    CleanState = Table.TransformColumns(CleanCity, {{"customer_state", Text.Upper, type text}})
in
    CleanState
```
- **Key Step**: Proper casing on cities and uppercase standardization on two-letter state codes (e.g., `SP`, `RJ`, `MG`).

### 3.3 Table: `order_items`
```powerquery
let
    Source = Csv.Document(File.Contents(SourceFolderPath & "order_items.csv"), [Delimiter=",", Columns=7, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    PromoteHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangeTypes = Table.TransformColumnTypes(PromoteHeaders, {
        {"order_id", type text},
        {"order_item_id", Int64.Type},
        {"product_id", type text},
        {"seller_id", type text},
        {"shipping_limit_date", type datetime},
        {"price", type number},
        {"freight_value", type number}
    }),
    AddTotalItemValue = Table.AddColumn(ChangeTypes, "item_total_value", each [price] + [freight_value], type number)
in
    AddTotalItemValue
```

### 3.4 Table: `order_payments`
```powerquery
let
    Source = Csv.Document(File.Contents(SourceFolderPath & "order_payments.csv"), [Delimiter=",", Columns=5, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    PromoteHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangeTypes = Table.TransformColumnTypes(PromoteHeaders, {
        {"order_id", type text},
        {"payment_sequential", Int64.Type},
        {"payment_type", type text},
        {"payment_installments", Int64.Type},
        {"payment_value", type number}
    }),
    StandardizePaymentType = Table.ReplaceValue(ChangeTypes, "_", " ", Replacer.ReplaceText, {"payment_type"}),
    ProperCasePayment = Table.TransformColumns(StandardizePaymentType, {{"payment_type", Text.Proper, type text}})
in
    ProperCasePayment
```

### 3.5 Table: `rfm_results`
```powerquery
let
    Source = Csv.Document(File.Contents(SourceFolderPath & "rfm_results.csv"), [Delimiter=",", Columns=9, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    PromoteHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangeTypes = Table.TransformColumnTypes(PromoteHeaders, {
        {"customer_unique_id", type text},
        {"recency", Int64.Type},
        {"frequency", Int64.Type},
        {"monetary", type number},
        {"r_score", Int64.Type},
        {"f_score", Int64.Type},
        {"m_score", Int64.Type},
        {"rfm_score", type text},
        {"segment", type text}
    }),
    CleanSegment = Table.TransformColumns(ChangeTypes, {{"segment", Text.Trim, type text}})
in
    CleanSegment
```

### 3.6 Table: `churn_results`
```powerquery
let
    Source = Csv.Document(File.Contents(SourceFolderPath & "churn_results.csv"), [Delimiter=",", Columns=6, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    PromoteHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangeTypes = Table.TransformColumnTypes(PromoteHeaders, {
        {"customer_unique_id", type text},
        {"churn_status", type text},
        {"recency_days", Int64.Type},
        {"total_revenue", type number},
        {"total_orders", Int64.Type},
        {"churn_probability", type number}
    }),
    StandardizeStatus = Table.TransformColumns(ChangeTypes, {{"churn_status", Text.Proper, type text}})
in
    StandardizeStatus
```

### 3.7 Table: `cohort_retention`
```powerquery
let
    Source = Csv.Document(File.Contents(SourceFolderPath & "cohort_retention.csv"), [Delimiter=",", Columns=5, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    PromoteHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangeTypes = Table.TransformColumnTypes(PromoteHeaders, {
        {"cohort_month", type date},
        {"month_number", Int64.Type},
        {"active_customers", Int64.Type},
        {"cohort_size", Int64.Type},
        {"retention_rate", type number}
    })
in
    ChangeTypes
```

---

## 4. Data Model Architecture & Relationship Setup

Close & Apply Power Query, then switch to the **Model View** tab in Power BI Desktop. Configure the exact relationships as detailed in the matrix below:

| From Table (Many / Fact) | From Column | To Table (One / Dim) | To Column | Cardinality | Cross Filter Direction | Security Filter | Active |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `orders` | `customer_id` | `customers` | `customer_id` | Many-to-One (`*:1`) | Single (`customers` filters `orders`) | False | Yes |
| `order_items` | `order_id` | `orders` | `order_id` | Many-to-One (`*:1`) | Single (`orders` filters `order_items`) | False | Yes |
| `order_payments` | `order_id` | `orders` | `order_id` | Many-to-One (`*:1`) | Single (`orders` filters `order_payments`) | False | Yes |
| `rfm_results` | `customer_unique_id`| `customers` | `customer_unique_id`| One-to-One (`1:1`)* | Both (Bidirectional) | False | Yes |
| `churn_results` | `customer_unique_id`| `customers` | `customer_unique_id`| One-to-One (`1:1`)* | Both (Bidirectional) | False | Yes |
| `orders` | `order_purchase_date`| `Calendar` | `Date` | Many-to-One (`*:1`) | Single (`Calendar` filters `orders`) | False | Yes |

*\*Note on One-to-One Relationships*: Setting Cross-Filter Direction to **Both** allows slicing transactional measures (`Total Revenue`, `Total Orders`) directly by analytical segmentation fields (`rfm_results[segment]` and `churn_results[churn_status]`) without requiring complex DAX bridges.

---

## 5. Calendar Table M Query

In Power Query Editor, create a new blank query (**New Source > Blank Query**), rename it to `Calendar`, open the **Advanced Editor**, and paste the full M code below:

```powerquery
let
    // Dynamically retrieve min and max purchase dates from the orders table
    StartDate = Date.StartOfYear(List.Min(orders[order_purchase_date])),
    EndDate = Date.EndOfYear(List.Max(orders[order_purchase_date])),
    
    // Generate continuous list of calendar days
    DayCount = Duration.Days(Duration.From(EndDate - StartDate)) + 1,
    Source = List.Dates(StartDate, DayCount, #duration(1, 0, 0, 0)),
    TableFromList = Table.FromList(Source, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
    ChangedType = Table.TransformColumnTypes(TableFromList, {{"Date", type date}}),
    
    // Add Calendar Attributes
    AddYear = Table.AddColumn(ChangedType, "Year", each Date.Year([Date]), Int64.Type),
    AddQuarterNumber = Table.AddColumn(AddYear, "Quarter Number", each Date.QuarterOfYear([Date]), Int64.Type),
    AddQuarter = Table.AddColumn(AddQuarterNumber, "Quarter", each "Q" & Text.From([Quarter Number]), type text),
    AddYearQuarter = Table.AddColumn(AddQuarter, "Year-Quarter", each Text.From([Year]) & "-Q" & Text.From([Quarter Number]), type text),
    AddMonthNumber = Table.AddColumn(AddYearQuarter, "Month Number", each Date.Month([Date]), Int64.Type),
    AddMonthName = Table.AddColumn(AddMonthNumber, "Month Name", each Date.MonthName([Date]), type text),
    AddMonthShort = Table.AddColumn(AddMonthName, "Month Short", each Text.Start([Month Name], 3), type text),
    AddYearMonthInt = Table.AddColumn(AddMonthShort, "YearMonthInt", each [Year] * 100 + [Month Number], Int64.Type),
    AddMonthYear = Table.AddColumn(AddYearMonthInt, "Month-Year", each [Month Short] & " " & Text.From([Year]), type text),
    AddDayOfMonth = Table.AddColumn(AddMonthYear, "Day of Month", each Date.Day([Date]), Int64.Type),
    AddDayOfWeek = Table.AddColumn(AddDayOfMonth, "Day of Week", each Date.DayOfWeek([Date], Day.Monday) + 1, Int64.Type),
    AddDayName = Table.AddColumn(AddDayOfWeek, "Day Name", each Date.DayOfWeekName([Date]), type text),
    AddIsWeekend = Table.AddColumn(AddDayName, "Is Weekend", each if [Day of Week] >= 6 then "Weekend" else "Weekday", type text),
    AddWeekOfYear = Table.AddColumn(AddIsWeekend, "Week of Year", each Date.WeekOfYear([Date]), Int64.Type)
in
    AddWeekOfYear
```

### Calendar Sorting Configuration
Once loaded into Power BI Desktop, set the following sort order dependencies in Data View:
- Select column `Month Name` -> Ribbon: **Column tools > Sort by column** -> choose `Month Number`.
- Select column `Month Short` -> Ribbon: **Column tools > Sort by column** -> choose `Month Number`.
- Select column `Month-Year` -> Ribbon: **Column tools > Sort by column** -> choose `YearMonthInt`.
- Select column `Quarter` -> Ribbon: **Column tools > Sort by column** -> choose `Quarter Number`.
- Select column `Year-Quarter` -> Ribbon: **Column tools > Sort by column** -> choose `YearMonthInt`.
- Mark table as official Date Table: Right click `Calendar` -> **Mark as date table** -> Select `Date` column.

---

## 6. Page 1: Executive Overview — Visual Specifications

- **Page Title**: `Executive Overview`
- **Canvas Size**: 1920 × 1080 px (16:9 widescreen)
- **Background Color**: `#1a1a2e` (Dark navy, 0% transparency)

```text
+-------------------------------------------------------------------------------------------------------------+
| TOP SLICERS: [ Date Range Slider ]               [ State Dropdown ]          [ Product Category Dropdown ]   |
+-------------------------------------------------------------------------------------------------------------+
| [ Total Revenue ]  [ Total Orders ]  [ Total Customers ]  [ AOV ]  [ Repeat Purchase Rate ]  [ Avg Cust Rev ]|
|   $15.42M            96,478            93,358               $159.84   3.1%                      $165.17      |
+-------------------------------------------------------+-----------------------------------------------------+
| MONTHLY REVENUE TREND (Line Chart with Markers)        | REVENUE BY TOP 15 CATEGORIES (Horizontal Bar)       |
| X: Calendar[Month-Year], Y: [Total Revenue]           | Y: Category, X: [Total Revenue]                     |
+-------------------------------------------------------+-----------------------------------------------------+
| ORDERS BY BRAZILIAN STATE (Map / Bar Chart)           | NEW VS REPEAT BUYERS       | MONTHLY ORDER VOLUME   |
| Y: customer_state, X: [Total Orders]                  | Donut Chart: Customers     | Bar: X=Month, Y=Orders |
+-------------------------------------------------------+----------------------------+------------------------+
```

### 6.1 Top Slicer Header (Y: 20px, Height: 60px)
- **Slicer 1 (Date Range)**:
  - Field: `Calendar[Date]`
  - Style: Between (Slider with input boxes)
  - Values: Start = First recorded order, End = Last recorded order
- **Slicer 2 (State)**:
  - Field: `customers[customer_state]`
  - Style: Dropdown, Multi-select with CTRL enabled, "Select all" option toggled on.
- **Slicer 3 (Product Category)**:
  - Field: `order_items[product_category_name]`
  - Style: Dropdown with search bar enabled.

### 6.2 Top KPI Ribbon (Y: 100px, Height: 110px) — 6 KPI Cards
Place 6 Card (new) visuals or standard Cards evenly spaced across the canvas width:
1. **Total Revenue Card**:
   - Field: `[Total Revenue]`
   - Callout Value: Font 32pt Bold White (`#FFFFFF`), Display units: Auto (displays e.g. `$15.42M`).
   - Subtitle: `[MoM Revenue Growth %]`, font 12pt, conditional font color using `[MoM Revenue Color]`.
2. **Total Orders Card**:
   - Field: `[Total Orders]`
   - Callout Value: Font 32pt Bold White, formatted as `#,##0`.
   - Subtitle: `[MoM Order Growth %]`.
3. **Total Customers Card**:
   - Field: `[Total Customers]`
   - Callout Value: Font 32pt Bold White.
4. **Average Order Value (AOV) Card**:
   - Field: `[AOV]`
   - Callout Value: Font 32pt Bold White (`$#,##0.00`).
5. **Repeat Purchase Rate Card**:
   - Field: `[Repeat Purchase Rate]`
   - Callout Value: Font 32pt Bold Coral/Highlight (`#E94560`), formatted as `0.0%`.
6. **Average Customer Revenue Card**:
   - Field: `[Avg Customer Revenue]`
   - Callout Value: Font 32pt Bold White (`$#,##0.00`).

### 6.3 Visuals Grid
- **Visual 1: Monthly Revenue Trend (Line Chart)**:
  - Position: X: 40, Y: 230, Width: 1080, Height: 380
  - Visual Type: Line chart
  - X-Axis: `Calendar[Month-Year]` (sorted by `YearMonthInt`)
  - Y-Axis: `_Measures[Total Revenue]`
  - Secondary / Tooltips: `[MoM Revenue Growth %]`, `[Revenue Previous Month]`
  - Styling: Line stroke width 3px, Color `#00B894` (Emerald), Data Markers enabled (circle, 6px), Data labels off.
- **Visual 2: Revenue by Category (Horizontal Clustered Bar Chart)**:
  - Position: X: 1140, Y: 230, Width: 740, Height: 380
  - Y-Axis: `order_items[product_category_name]`
  - X-Axis: `_Measures[Total Revenue]`
  - Filters on Visual: Top N filter on `product_category_name` by `[Total Revenue]`, Value: `15`.
  - Styling: Bar color `#16213E`, Accent border `#E94560`, Data labels on (Currency display units: Thousands/Millions).
- **Visual 3: Orders by State (Horizontal Bar Chart or Filled Map)**:
  - Position: X: 40, Y: 630, Width: 700, Height: 400
  - Y-Axis: `customers[customer_state]` (sorted descending by `[Total Orders]`)
  - X-Axis: `_Measures[Total Orders]`
  - Styling: Gradient fill based on `[Total Orders]` (Low: `#16213E`, High: `#00CEC9`).
- **Visual 4: New vs Repeat Customers (Donut Chart)**:
  - Position: X: 760, Y: 630, Width: 520, Height: 400
  - Legend: `rfm_results[frequency]` grouped into `New Customer` (freq=1) vs `Repeat Customer` (freq>1).
  - Values: `_Measures[Total Customers]`
  - Colors: New Customers = `#0F3460`, Repeat Customers = `#E94560`.
  - Detail Labels: Category, percent of total.
- **Visual 5: Monthly Orders Volume (Clustered Column Chart)**:
  - Position: X: 1300, Y: 630, Width: 580, Height: 400
  - X-Axis: `Calendar[Month-Year]`
  - Y-Axis: `_Measures[Total Orders]`
  - Bar Color: `#00CEC9`, Corner radius 4px.

---

## 7. Page 2: Customer Segmentation — Visual Specifications

- **Page Title**: `Customer Segmentation`
- **Objective**: Operationalize the 11 RFM customer segments to guide marketing re-engagement and VIP retention.

```text
+-------------------------------------------------------------------------------------------------------------+
| TOP BANNER: RFM SEGMENTATION INTELLIGENCE (Recency, Frequency, Monetary Distribution)                      |
+-------------------------------------------------------+-----------------------------------------------------+
| SEGMENT DISTRIBUTION (Donut Chart)                    | REVENUE BY SEGMENT (Horizontal Bar Chart)           |
| Legend: rfm_results[segment], Value: Total Customers  | Y: Segment, X: Total Revenue                        |
+-------------------------------------------------------+-----------------------------------------------------+
| CUSTOMER VALUE COMPARISON (Clustered Bar)             | RFM SEGMENT MATRIX (Conditional Formatting Table)   |
| X: Segment, Y: Avg Recency, Avg Frequency, Avg Spend  | Segment, Customers, % Cust, Revenue, % Rev, AOV     |
+-------------------------------------------------------+-----------------------------------------------------+
| SCATTER PLOT: RECENCY VS MONETARY                                                                           |
| X-Axis: Recency (Days), Y-Axis: Monetary Spend ($), Bubble Size: Frequency, Color: Segment                  |
+-------------------------------------------------------------------------------------------------------------+
```

### 7.1 Visual Configuration Details
1. **Segment Distribution Donut Chart**:
   - Legend: `rfm_results[segment]`
   - Values: `_Measures[Total Customers]`
   - Detail Labels: Percent of total and data value.
   - Segment Color Palette:
     - Champions: `#00B894` (Vibrant green)
     - Loyal Customers: `#00CEC9` (Cyan)
     - Potential Loyalists: `#74B9FF` (Light blue)
     - Recent Customers: `#A29BFE` (Periwinkle)
     - Promising: `#FFEAA7` (Soft yellow)
     - Customers Needing Attention: `#FDCB6E` (Amber)
     - About to Sleep: `#E17055` (Terracotta)
     - At Risk: `#D63031` (Crimson)
     - Can't Lose Them: `#E84393` (Deep magenta)
     - Hibernating: `#636E72` (Slate grey)
     - Lost: `#2D3436` (Charcoal)
2. **Revenue by Segment Bar Chart**:
   - Y-Axis: `rfm_results[segment]` (Sorted descending by `[Total Revenue]`)
   - X-Axis: `_Measures[Total Revenue]`
   - Data labels: Enabled, Currency Millions/Thousands.
3. **Customer Value Comparison (Clustered Column Chart)**:
   - X-Axis: `rfm_results[segment]`
   - Y-Axis: `Average of rfm_results[monetary]`
   - Tooltip fields: `Average of rfm_results[recency]`, `Average of rfm_results[frequency]`.
4. **Segment Matrix Table**:
   - Columns:
     1. `rfm_results[segment]`
     2. `[Total Customers]`
     3. `[Champions % of Customers]` (or generic `% of Customers`)
     4. `[Total Revenue]`
     5. `[Champions % of Revenue]` (or generic `% of Revenue`)
     6. `[AOV]`
   - Conditional Formatting:
     - `% of Revenue`: Data bars in Cyan (`#00CEC9`).
     - `AOV`: Background color gradient (Dark navy `#16213E` to Emerald `#00B894`).
5. **Scatter Plot: Recency vs. Monetary**:
   - Position: X: 40, Y: 720, Width: 1840, Height: 320
   - X-Axis: `rfm_results[recency]` (Inverted axis toggle: low recency on the right or left)
   - Y-Axis: `rfm_results[monetary]`
   - Size (Bubble Size): `rfm_results[frequency]`
   - Legend: `rfm_results[segment]`

---

## 8. Page 3: Retention & Cohort Analytics — Visual Specifications

- **Page Title**: `Retention & Cohort`
- **Objective**: Visualize customer retention decay across acquisition cohorts and monitor repeat purchasing frequency.

```text
+-------------------------------------------------------------------------------------------------------------+
| KPI CARDS: [ Repeat Purchase Rate: 3.1% ]  [ Cohort Baseline (Month 0): 100% ]  [ 12-Month Retention: 0.8% ]|
+-------------------------------------------------------------------------------------------------------------+
| COHORT RETENTION MATRIX (Matrix Table with Heatmap Background Shading)                                      |
| Rows: cohort_retention[cohort_month] (YYYY-MM)                                                              |
| Columns: cohort_retention[month_number] (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)                           |
| Values: [Cohort Retention Rate] (%)                                                                         |
+-------------------------------------------------------+-----------------------------------------------------+
| RETENTION DECAY TRENDS (Line Chart)                   | CUSTOMER ORDER FREQUENCY DISTRIBUTION (Column Chart)|
| X: month_number, Y: Cohort Retention Rate,            | X: Order Count (1, 2, 3, 4, 5+),                    |
| Legend: cohort_month                                  | Y: Unique Customers                                 |
+-------------------------------------------------------+-----------------------------------------------------+
```

### 8.1 Visual Configuration Details
1. **Cohort Retention Matrix Table**:
   - Rows: `cohort_retention[cohort_month]` (Format: `yyyy-mm`)
   - Columns: `cohort_retention[month_number]` (0 through 12+)
   - Values: `_Measures[Cohort Retention Rate]`
   - Cell Formatting:
     - Font size: 10pt.
     - Background Color Conditional Formatting:
       - Format style: Gradient
       - Minimum (0.0%): Dark Slate (`#16213E`)
       - Midpoint (2.5%): Cyan (`#00CEC9`)
       - Maximum (100.0%): Vibrant Emerald (`#00B894`)
2. **Retention Decay Curves (Line Chart)**:
   - X-Axis: `cohort_retention[month_number]` (Continuous or Categorical 1 to 12)
   - Y-Axis: `_Measures[Cohort Retention Rate]`
   - Legend: `cohort_retention[cohort_month]`
   - Filter: Exclude Month 0 so scale highlights months 1–12 retention dynamics.
3. **Customer Order Frequency Distribution (Column Chart)**:
   - X-Axis: Calculated column or group on `rfm_results[frequency]` (`"1 Order"`, `"2 Orders"`, `"3 Orders"`, `"4+ Orders"`)
   - Y-Axis: `_Measures[Total Customers]`
   - Data Labels: Value and percentage of total.

---

## 9. Page 4: Churn Intelligence — Visual Specifications

- **Page Title**: `Churn Analysis`
- **Objective**: Identify impending attrition, isolate revenue at risk, and pinpoint high-value customers needing urgent intervention.

```text
+-------------------------------------------------------------------------------------------------------------+
| TOP CARDS: [ Total Churned: 42,180 ]   [ At-Risk Customers: 14,350 ]   [ Revenue at Risk: $2.41M (Orange) ]|
+-------------------------------------------------------+-----------------------------------------------------+
| CHURN STATUS DISTRIBUTION (Donut Chart)               | AT-RISK & CHURNED REVENUE BY STATE (Horizontal Bar) |
| Legend: churn_results[churn_status]                   | Y: State, X: [Revenue At Risk]                      |
| Values: Total Customers                               | Color: #F39C12                                      |
+-------------------------------------------------------+-----------------------------------------------------+
| CHURN PROBABILITY VS RECENCY (Scatter Plot)                                                                 |
| X: Recency Days, Y: Churn Probability %, Color: Segment, Bubble: Total Revenue                              |
+-------------------------------------------------------------------------------------------------------------+
| HIGH-VALUE AT-RISK & CHURNED CUSTOMERS (Action Table)                                                       |
| Customer Unique ID | Segment | Recency Days | Orders | Total Spend | Churn Status | Action Priority        |
+-------------------------------------------------------------------------------------------------------------+
```

### 9.1 Visual Configuration Details
1. **Primary Exposure Card (Revenue at Risk)**:
   - Field: `_Measures[Revenue At Risk]`
   - Callout Value: Font 36pt Bold Amber/Orange (`#F39C12`).
   - Title: `REVENUE AT RISK (IMMEDIATE ACTION REQUIRED)`.
   - Card Background: `#16213E` with 2px solid border in `#F39C12`.
2. **Churn Status Donut Chart**:
   - Legend: `churn_results[churn_status]` (`Active`, `At Risk`, `Churned`)
   - Values: `_Measures[Total Customers]`
   - Color mapping:
     - `Active`: `#00B894` (Emerald Green)
     - `At Risk`: `#F39C12` (Warning Amber)
     - `Churned`: `#E94560` (Alert Red)
3. **Churn by State Bar Chart**:
   - Y-Axis: `customers[customer_state]`
   - X-Axis: `_Measures[Revenue At Risk]`
   - Sort: Descending by revenue at risk.
4. **High-Value Customer Action Table**:
   - Fields:
     - `customers[customer_unique_id]`
     - `rfm_results[segment]`
     - `churn_results[recency_days]`
     - `churn_results[total_orders]`
     - `churn_results[total_revenue]`
     - `churn_results[churn_status]`
   - Filter on Visual: `churn_results[churn_status]` IN (`"At Risk"`, `"Churned"`) AND `churn_results[total_revenue]` > $500.
   - Sort: `churn_results[total_revenue]` descending.

---

## 10. Page 5: Product & Category Revenue — Visual Specifications

- **Page Title**: `Product & Revenue`
- **Objective**: Uncover product category gross sales, average order economics, and geographic revenue generation.

```text
+-------------------------------------------------------------------------------------------------------------+
| TOP CARDS: [ Product Categories: 73 ]   [ Top Category Share: 11.2% ]   [ Highest AOV Category: $385.10 ]  |
+-------------------------------------------------------+-----------------------------------------------------+
| CATEGORY REVENUE (Ranked Bar Chart)                   | CATEGORY AOV (Horizontal Bar Chart)                 |
| Y: Category, X: [Total Revenue]                       | Y: Category, X: [Category AOV]                      |
+-------------------------------------------------------+-----------------------------------------------------+
| GEOGRAPHIC REVENUE DISTRIBUTION (Map / State Matrix)  | MONTHLY CATEGORY TRENDS (Multi-Line Chart)          |
| Bubble / Choropleth: State, Size: Total Revenue       | X: Month, Y: Category Revenue, Legend: Top 5 Cats   |
+-------------------------------------------------------+-----------------------------------------------------+
```

### 10.1 Visual Configuration Details
1. **Category Revenue Ranked Bar Chart**:
   - Y-Axis: `order_items[product_category_name]`
   - X-Axis: `_Measures[Total Revenue]`
   - Visual Filter: Top 15 categories.
   - Bar Color: `#16213E`, Accent border: `#00CEC9`.
2. **Category AOV Bar Chart**:
   - Y-Axis: `order_items[product_category_name]`
   - X-Axis: `_Measures[Category AOV]`
   - Visual Filter: Top 15 categories by order volume.
3. **Geographic Revenue Map**:
   - Location: `customers[customer_state]`
   - Bubble Size: `_Measures[Total Revenue]`
   - Tooltips: `[Total Orders]`, `[AOV]`, `[Total Customers]`.
4. **Monthly Category Trend Line Chart**:
   - X-Axis: `Calendar[Month-Year]`
   - Y-Axis: `_Measures[Total Revenue]`
   - Legend: `order_items[product_category_name]` (Top 5 categories by revenue).

---

## 11. Design System, Dark Theme & Formatting Standards

### Custom Theme JSON
Save the following configuration as `ecommerce_dark_theme.json` and import it into Power BI Desktop via **View > Themes > Browse for themes**:

```json
{
  "name": "EcommerceDarkNavy",
  "dataColors": [
    "#00B894",
    "#00CEC9",
    "#E94560",
    "#F39C12",
    "#74B9FF",
    "#A29BFE",
    "#E84393",
    "#FDCB6E",
    "#0984E3",
    "#D63031"
  ],
  "background": "#1a1a2e",
  "foreground": "#FFFFFF",
  "tableAccent": "#16213e",
  "visualStyles": {
    "*": {
      "*": {
        "background": [
          {
            "show": true,
            "color": { "solid": { "color": "#16213e" } },
            "transparency": 10
          }
        ],
        "border": [
          {
            "show": true,
            "color": { "solid": { "color": "#252d4a" } },
            "radius": 8
          }
        ],
        "dropShadow": [
          {
            "show": true,
            "color": { "solid": { "color": "#0a0a14" } },
            "position": "Outer",
            "preset": "BottomRight"
          }
        ],
        "title": [
          {
            "show": true,
            "fontColor": { "solid": { "color": "#FFFFFF" } },
            "fontFamily": "Segoe UI Semibold",
            "fontSize": 12
          }
        ],
        "labels": [
          {
            "color": { "solid": { "color": "#A0A0B0" } },
            "fontFamily": "Segoe UI",
            "fontSize": 10
          }
        ]
      }
    },
    "page": {
      "*": {
        "background": [
          {
            "color": { "solid": { "color": "#1a1a2e" } },
            "transparency": 0
          }
        ]
      }
    }
  }
}
```

### Visual Consistency Checklist
- [x] **Canvas Aspect Ratio**: 16:9 (1920 × 1080 px).
- [x] **Primary Font**: `Segoe UI` across all titles, axes, callouts, and data labels.
- [x] **Card Padding**: 16px internal padding, corner radius 8px.
- [x] **Grid Alignment**: Enable **View > Snap to grid** and **Lock objects** before publishing.

---

## 12. Publishing, Scheduled Refresh & Service Configuration

### 12.1 Publishing Steps
1. In Power BI Desktop, click **File > Save As** and name the project `Ecommerce_Customer_Analytics.pbix`.
2. Click **Home > Publish > Select Workspace** (e.g., `Executive Analytics Workspace`).
3. Confirm publication success dialog and open the report link in Power BI Service.

### 12.2 Scheduled Refresh Setup (On-Premises Data Gateway)
Because the datasets originate from local CSV files:
1. Install and launch the **Power BI On-Premises Data Gateway (Standard Mode)** on the host machine.
2. Register the gateway under your Power BI tenant.
3. In Power BI Service, navigate to **Settings > Manage connections and gateways**.
4. Add a new Folder / File data source pointing to `c:\Users\ramee\Downloads\e commerce\Ecommerce-Customer-Analytics\exports\`.
5. Under dataset settings, enable **Scheduled Refresh**:
   - Frequency: Daily.
   - Time: `06:00 AM UTC` (before executive business hours).
   - Notification: Send refresh failure notifications to dataset owner.

### 12.3 Mobile Layout Configuration
1. In Power BI Desktop, navigate to **View > Mobile Layout**.
2. Drag and drop the 6 Executive KPI Cards in a single-column scrolling ribbon.
3. Add the Monthly Revenue Line Chart and Churn Status Donut Chart.
4. Save and re-publish to ensure responsive layout on iOS and Android Power BI mobile apps.
