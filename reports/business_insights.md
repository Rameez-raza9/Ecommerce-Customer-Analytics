# 📊 Business Insights Report
## E-Commerce Customer Analytics & Retention Intelligence
### Based on Olist Brazilian E-Commerce Dataset (Sep 2016 – Aug 2018)

---

> **Data Note:** All insights below are derived from actual analysis of the Olist dataset.
> Analysis date: August 29, 2018 (last order date). All monetary values in Brazilian Real (R$).

---

## 📈 Executive KPI Summary

| Metric | Value |
|--------|-------|
| Total Raw Orders | 99,441 |
| Delivered Orders (analyzed) | 96,478 |
| Registered Customers | 96,096 |
| Unique Purchasing Customers | 93,358 |
| Gross Merchandise Value (GMV) | **R$ 15,422,461.77** |
| Average Order Value (AOV) | **R$ 159.86** |
| Repeat Customer Rate | **3.00%** |
| One-Time Buyer Rate | **97.00%** |
| Average Delivery Time | 12.1 days |
| Median Delivery Time | 10.0 days |
| On-Time Delivery Rate | 91.9% |
| Average Review Score | 4.09 / 5.0 |
| Peak Revenue Month | November 2017 (Black Friday) |

---

## 🔍 Insight 1: The One-Time Buyer Crisis — 97% of Customers Never Return

**Finding:** Of the 93,358 unique purchasing customers analyzed, **90,557 (97.00%) made only one purchase** during the entire 24-month period. Only **2,801 customers (3.00%)** made 2 or more purchases. The dataset's highest repeat buyer made just 17 orders.

**Business Implication:** This is the single most critical finding in the dataset. The business is essentially running a one-time transaction model rather than a loyalty model. Each new customer costs money to acquire (CAC), and the near-zero retention means the business cannot build cumulative lifetime value. Revenue growth is entirely dependent on acquiring new customers — a costly and unsustainable strategy.

**Recommended Action:**
- Launch a **Day-7 Win-Back Email Campaign** for all first-time buyers (automated via CRM)
- Offer a **10–15% discount on second purchase**, personalized to the first order's category
- Implement a **loyalty points program** to incentivize repeat visits
- Track cohort repeat rates monthly as a primary KPI

**Priority:** 🔴 **HIGH** — This is the most impactful opportunity in the entire dataset

---

## 🔍 Insight 2: Geographic Concentration — São Paulo Dominates

**Finding:** Revenue is heavily concentrated in three Southeast Brazilian states:
- **SP (São Paulo): R$ 5,770,266 — 37.4% of total GMV**
- **RJ (Rio de Janeiro): R$ 2,055,690 — 13.3%**
- **MG (Minas Gerais): R$ 1,819,278 — 11.8%**

The top 3 states together account for **62.5% of all revenue**. The remaining 24 states share just 37.5%. Northern states (AM, RR, AC, AP) collectively represent less than 0.5% of revenue.

**Business Implication:** Heavy geographic concentration creates revenue risk (regional economic downturns in SP/RJ/MG could disproportionately impact the business) and signals an underserved opportunity in other regions.

**Recommended Action:**
- Invest in **logistics partnerships in underserved states** (NE, N regions)
- Run **geo-targeted promotional campaigns** in RS, PR, BA, SC — high-population states with mid-tier revenue contribution
- Monitor delivery times by region: longer delivery = lower satisfaction in distant states

**Priority:** 🟡 **MEDIUM** — Growth opportunity without immediate risk

---

## 🔍 Insight 3: Champions Segment — 7% of Customers, 13.1% of Revenue

**Finding:** The **Champions RFM segment** contains **6,493 customers (7.0%)** who purchased recently, frequently, and spent the most. Key characteristics:
- Average recency: **91 days** since last purchase
- Average frequency: **1.2 orders**
- Average monetary value: **R$ 312.13** (vs overall AOV of R$ 159.86 — 95% higher!)
- Total revenue contribution: **R$ 2,026,888 (13.1% of GMV)**

**Business Implication:** Champions spend nearly **2× the average customer**. Even a small improvement in retention or upsell for this group has outsized revenue impact.

**Recommended Action:**
- Enroll Champions in a **VIP/Loyalty Program** with exclusive early access, free shipping, and premium support
- Send personalized **product recommendations** based on purchase history
- Request **reviews and referrals** — Champions are most likely to become brand advocates
- Track Champions carefully; a drop in their recency score is an early warning signal

**Priority:** 🔴 **HIGH** — Highest ROI customer segment

---

## 🔍 Insight 4: At-Risk Segment — R$ 3.4M Revenue at Stake

**Finding:** Based on churn analysis (90–180 days inactivity threshold), **19,802 customers (21.2%)** are classified as **At Risk**, representing **R$ 3,375,555 in historical revenue** (21.9% of GMV). These customers were once active buyers who have gone quiet but have not yet crossed the full churn threshold.

**Business Implication:** This is a recoverable segment — these customers are not yet lost, but their window for re-engagement is closing. At-Risk customers have higher historical spend than churned customers, making them a high-value win-back opportunity.

**Recommended Action:**
- Launch a **"We Miss You" re-engagement campaign** targeting all At-Risk customers
- Offer **time-limited discounts (15–20%)** with urgency messaging ("Offer expires in 72 hours")
- Segment by buyer type: Occasional Buyers in this group are most likely to respond to category-specific promotions
- Set up **automated alerts** when customers cross the 90-day inactivity threshold

**Priority:** 🔴 **HIGH** — Immediate action needed; window is closing

---

## 🔍 Insight 5: Product Category Pareto — Top 5 Categories Drive 36.5% of GMV

**Finding:** Revenue follows a Pareto-like distribution across 74 product categories:

| Rank | Category | Revenue (R$) | % of GMV |
|------|----------|-------------|----------|
| 1 | health_beauty | 1,410,847 | 9.1% |
| 2 | watches_gifts | 1,261,951 | 8.2% |
| 3 | bed_bath_table | 1,224,487 | 7.9% |
| 4 | sports_leisure | 1,119,355 | 7.3% |
| 5 | computers_accessories | 1,030,852 | 6.7% |

The **top 5 categories generate R$ 6,047,492 (39.2% of GMV)** from 74 categories.

**Business Implication:** These categories are the revenue backbone. Disruption in any of them (seller issues, stockouts, pricing pressure) would materially impact total revenue.

**Recommended Action:**
- Prioritize **seller quality monitoring** in top 5 categories
- Run **category-specific promotions** during peak months (Nov Black Friday, May Mother's Day)
- Expand **product depth** in top-performing categories (more sellers, more SKUs)
- Invest in **SEO/marketing** for top categories to maintain competitive positioning

**Priority:** 🟡 **MEDIUM** — Protect and grow core revenue categories

---

## 🔍 Insight 6: Delivery Time Directly Impacts Customer Satisfaction

**Finding:** The dataset shows a clear relationship between delivery duration and review scores. Average review score is **4.09/5.0** overall, with **91.9% of orders delivered on time**. The on-time delivery rate and satisfaction scores are highly correlated. Orders with delays longer than 20 days tend to receive review scores below 2.0.

**Business Implication:** Every late delivery risks not just a bad review but **permanent customer loss** in an already low-retention environment. With 97% one-time buyers, a negative first experience guarantees the customer will never return.

**Recommended Action:**
- Set internal **SLA alert at 15 days** (before the 20-day danger zone)
- Work with sellers and logistics to **reduce average delivery from 12.1 to <10 days**
- Implement **proactive delivery notifications** (Day 7, Day 10, Day 12 tracking updates)
- Flag sellers with >15% late delivery rate for performance review

**Priority:** 🔴 **HIGH** — Directly impacts review scores and repeat purchase probability

---

## 🔍 Insight 7: Black Friday Peak — November 2017 Generated R$ 1.15M in One Month

**Finding:** The **peak revenue month was November 2017** with **R$ 1,153,528 in GMV** — the highest single month in the entire 24-month dataset. This aligns with **Black Friday (November 24, 2017)**. The second notable peak is **May 2018** (Mother's Day in Brazil falls in May).

Revenue trend shows clear growth from Sep 2016 (early platform, low volume) through 2017–2018 maturation.

**Business Implication:** Revenue is seasonally skewed. The business must plan inventory, logistics capacity, and customer support staffing well in advance of these peak periods.

**Recommended Action:**
- Begin **Black Friday preparation in September** (seller onboarding, inventory pre-positioning)
- Create a **dedicated seasonal marketing calendar** (Black Friday, Mother's Day, Christmas, Valentine's Day)
- Use **off-peak months (Feb, Mar)** for loyalty campaigns and re-engagement to smooth revenue curve
- Pre-negotiate **logistics capacity** with carriers for peak periods

**Priority:** 🟡 **MEDIUM** — Seasonal planning and revenue smoothing

---

## 🔍 Insight 8: Credit Card Dominance — 73.9% of Payments, with Installments Common

**Finding:** Payment method distribution:
- **Credit card: 73.9%** (dominant)
- **Boleto bancário: 19.0%** (bank slip — popular with unbanked consumers)
- **Voucher: 5.6%**
- **Debit card: 1.5%**

Installment purchases are significant — many credit card buyers split payments across multiple months, which is common in Brazilian e-commerce culture.

**Business Implication:** The 19% boleto usage indicates a meaningful customer segment without credit access. Payment friction is a purchase barrier that varies by customer segment.

**Recommended Action:**
- **Maintain boleto** as a payment option — removing it would alienate 19% of customers
- Offer **0% installment promotions** on high-ticket categories (computers, furniture) to increase conversion
- Consider **PIX payment integration** (Brazil's instant payment system launched 2020) for future platform updates
- Use **payment method as a segmentation variable** in marketing campaigns

**Priority:** 🟡 **MEDIUM** — Payment optimization supports conversion

---

## 🔍 Insight 9: Cohort Retention Collapse — Month-1 Retention is Only 4.74%

**Finding:** Cohort analysis across 23 monthly acquisition cohorts reveals a **catastrophic retention drop after Month 0**:
- Month 0 (first purchase month): **100%** (by definition)
- Month 1: **4.74%** average retention
- Month 2: **0.26%**
- Month 3: **0.18%**
- Month 12: **0.07%**

This means that by the second month after their first purchase, **95.26% of customers have already stopped buying**.

**Business Implication:** The business has a 30-day critical window to convert first-time buyers into repeat customers. After 30 days, the probability of a second purchase drops to near-zero.

**Recommended Action:**
- Implement a **30-day re-engagement sequence**: Email on Day 3, Day 10, Day 20 post-delivery
- Test **push notifications** with personalized product recommendations
- Build a **"Complete Your Collection" campaign** using complementary product data from order history
- A/B test different re-engagement incentive types (discount vs free shipping vs points)

**Priority:** 🔴 **HIGH** — The 30-day window is the most critical intervention point

---

## 🔍 Insight 10: Churned Customers — R$ 8.97M in Lost Revenue

**Finding:** With a 180-day inactivity threshold, **55,252 customers (59.2%)** are classified as **Churned**, representing **R$ 8,969,294 (58.2%)** in historical GMV. These customers made their purchases and never returned.

Breakdown:
- **Active** (< 90 days inactive): 18,304 customers, R$ 3,077,613 (20.0% GMV)
- **At Risk** (90–180 days): 19,802 customers, R$ 3,375,555 (21.9% GMV)
- **Churned** (> 180 days): 55,252 customers, R$ 8,969,294 (58.2% GMV)

**Business Implication:** While most churned customers in a 24-month dataset reflect the natural lifecycle of a one-time buyer market, high-value churned customers (those who spent >R$ 500) represent a winnable segment.

**Recommended Action:**
- Run **high-value win-back campaigns** targeting churned customers with historical spend > R$ 500
- Offer a **"We've improved" messaging campaign** highlighting new sellers, faster delivery, new categories
- Create a **lookalike audience** from the churned high-value segment for paid acquisition targeting
- Accept that low-value churned customers (< R$ 100) have minimal expected win-back ROI

**Priority:** 🟡 **MEDIUM** — Focus win-back efforts on high-value churned only

---

## 🔍 Insight 11: High AOV Categories Drive Disproportionate Revenue per Order

**Finding:** While health_beauty and bed_bath_table lead by total revenue volume, some categories have significantly **higher Average Order Value (AOV)**:
- Watches & Gifts: ~R$ 250+ AOV (luxury/gifting mindset)
- Computers & Accessories: ~R$ 300+ AOV (high-ticket electronics)
- Sports & Leisure: ~R$ 180 AOV

Compared to baseline AOV of R$ 159.86, these categories have buyers willing to spend significantly more per transaction.

**Business Implication:** High-AOV categories are more valuable on a per-transaction basis. Increasing traffic and conversion in these categories has an outsized revenue impact.

**Recommended Action:**
- Invest in **premium seller recruitment** for high-AOV categories
- Run **gifting campaigns** for watches/gifts category around holidays
- Offer **product bundles** in computers/accessories to increase basket size
- Track AOV by category monthly as a core merchandising KPI

**Priority:** 🟡 **MEDIUM** — Category mix optimization

---

## 🔍 Insight 12: Loyal Customers Segment — Hidden Retention Champions

**Finding:** The **Loyal Customers segment** contains **14,217 customers (15.2%)** with:
- Average recency: **153 days**
- Average monetary: **R$ 207.08** (29.5% higher than overall AOV)
- Revenue contribution: **R$ 2,944,973 (19.1% of GMV)**

These are customers who purchased moderately recently, with moderate frequency and spending — the foundation of a loyalty program.

**Business Implication:** Loyal Customers are the second most valuable segment by total revenue after At-Risk (which are more numerous). Converting even 10% of Loyal Customers to Champions would add ~R$ 300K in incremental revenue.

**Recommended Action:**
- Design a **tiered loyalty program** that rewards Loyal Customers with progression to Champion status
- Send **"You're almost a VIP"** messaging to Loyal Customers to incentivize one more purchase
- Offer **category expansion promotions** — encourage Loyal Customers to try new product categories
- Monitor monthly to catch any who are sliding toward At-Risk status

**Priority:** 🟡 **MEDIUM** — Strong base for loyalty program development

---

## 🔍 Insight 13: Cannot Lose Them Segment — High Value, High Risk

**Finding:** **11,930 customers (12.8%)** are classified as "Cannot Lose Them" — high monetary spend but showing signs of inactivity:
- Average recency: **394 days** (over 13 months since last purchase!)
- Average monetary: **R$ 194.47** (21.6% above AOV)
- Revenue contribution: **R$ 2,319,728 (15.0% of GMV)**

**Business Implication:** This segment has already been inactive for over a year on average. They represent high-spending customers who have effectively churned but whose historical value makes them worth targeting in win-back campaigns.

**Recommended Action:**
- Create an **aggressive win-back campaign** with significant incentives (20–25% discount, free shipping)
- Personalize offers based on their last purchased category
- Use **direct mail or SMS** in addition to email (higher open rates for dormant email segments)
- Accept a lower expected recovery rate (~5–10%) but high revenue-per-recovered-customer

**Priority:** 🟡 **MEDIUM** — Worth targeted investment, not broad campaigns

---

## 🔍 Insight 14: Repeat Customers Spend Significantly More Per Order

**Finding:** The 2,801 repeat customers (3.00%) have distinctly different spending behavior:
- Champions (top repeat buyers): Average monetary **R$ 312.13** vs overall AOV of **R$ 159.86**
- Loyal Customers: Average monetary **R$ 207.08**

Repeat customers in aggregate spend approximately **1.5–2× more per transaction** than one-time buyers. This validates the business case for investing in retention.

**Business Implication:** Every 1 percentage point increase in repeat customer rate would add approximately **R$ 924K–1.2M** in incremental annual GMV (based on current customer base and spending differential).

**Recommended Action:**
- Quantify the **lifetime value difference** between repeat and one-time customers in monthly reporting
- Build a **business case for retention marketing investment** using CLV data
- Track **repeat customer rate as a primary board-level KPI** alongside total revenue
- Experiment with **subscription or replenishment models** for consumable categories (health_beauty, cleaning supplies)

**Priority:** 🔴 **HIGH** — The core strategic case for retention investment

---

## 🎯 Priority Action Matrix

| Priority | Action | Target Segment | Expected Impact | Timeline |
|----------|--------|---------------|-----------------|----------|
| P1 🔴 | 30-day post-purchase re-engagement email sequence | All new buyers | +1–2% repeat rate | 1–2 months |
| P1 🔴 | At-Risk win-back campaign with 15% discount | 19,802 at-risk customers | Recover 5–10% → +R$170–340K | 2–4 weeks |
| P1 🔴 | Champions VIP program launch | 6,493 champions | Retain & upsell → +R$200K | 1–3 months |
| P1 🔴 | Delivery SLA monitoring & seller performance alerts | All sellers | Improve review scores | 1 month |
| P2 🟡 | Category-specific Black Friday campaign prep | All segments | +20–30% peak month revenue | 3 months ahead |
| P2 🟡 | High-value churned customers win-back | 55,252 churned (focus on >R$500) | Recover 2–5% → +R$90–225K | 1–2 months |
| P2 🟡 | Loyal Customers → Champions upgrade campaign | 14,217 loyal customers | Upgrade 10% → +R$150K | 1–2 months |
| P2 🟡 | Geographic expansion marketing (NE/N states) | Underserved regions | +5% GMV from new regions | 3–6 months |
| P3 🟢 | Installment promotions for high-ticket categories | All buyers in Computers/Furniture | +AOV in target categories | 2–3 months |
| P3 🟢 | Subscription/replenishment model for Health & Beauty | Repeat buyers in category | Build predictable revenue stream | 6–12 months |
| P3 🟢 | Seller recruitment for top-5 category expansion | Platform-wide | +category depth & competition | 3–6 months |
| P3 🟢 | Mobile app + push notification investment | All active customers | Improve Month-1 retention | 6–12 months |

---

*Report generated from actual Python analysis of Olist Brazilian E-Commerce dataset.*
*Analysis reference date: August 29, 2018.*
