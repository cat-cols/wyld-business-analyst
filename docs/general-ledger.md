---

# Business Logic:
* gross sales should generally be >= net sales
* gross margin should generally be close to `net_sales - cogs` depending on sign conventions


---

Below is a **General Ledger cheat sheet written for a Business Analyst**, not an accountant. Think of it as the mental toolkit you carry when reconciling data, building dashboards, or explaining numbers to executives.

A business analyst sits at an interesting intersection: operations produce events, finance produces accounting truth, and analytics translates between them. The General Ledger is where those worlds meet.

---

# General Ledger Cheat Sheet for Business Analysts

## 1. What the General Ledger Actually Is

The **General Ledger (GL)** is the company’s **official financial record**. It is the system accountants use to produce:

* Income Statements
* Balance Sheets
* Cash Flow Statements
* Investor reporting
* Tax reporting

Every operational system eventually gets summarized into the GL.

For example:

| Operational System | Example Data              |
| ------------------ | ------------------------- |
| POS                | Each gummy sale           |
| Distributor system | Shipments to dispensaries |
| ERP inventory      | Production batches        |
| Payroll system     | Labor hours               |
| Expenses           | Rent, marketing, travel   |

All of these ultimately become **journal entries in the GL**.

Your analytics models usually sit **between operations and the GL**.

---

# 2. Core GL Concepts a Business Analyst Must Know

## Chart of Accounts (COA)

The **chart of accounts** is the master list of financial categories.

Example structure:

| Account | Name               | Type           |
| ------- | ------------------ | -------------- |
| 4000    | Product Revenue    | Revenue        |
| 4010    | Discounts          | Contra Revenue |
| 5000    | Cost of Goods Sold | Expense        |
| 6100    | Payroll Expense    | Expense        |
| 7200    | Rent Expense       | Expense        |

Think of it as the **taxonomy of money**.

When analysts reconcile numbers, they often need to know which accounts map to which KPI.

---

## Journal Entries

A **journal entry** records a financial event.

Example:

| Date  | Account | Debit | Credit |
| ----- | ------- | ----- | ------ |
| Jan 5 | Cash    | 1000  |        |
| Jan 5 | Revenue |       | 1000   |

Accounting requires **double-entry** bookkeeping:

Every transaction must balance.

```
Debits = Credits
```

This is how accountants ensure financial integrity.

---

# 3. The Income Statement Structure

Most GL analytics work revolves around the **income statement**.

Typical hierarchy:

```
Gross Sales
- Discounts / Returns
= Net Sales

Net Sales
- Cost of Goods Sold (COGS)
= Gross Margin

Gross Margin
- Operating Expenses
= Operating Profit

Operating Profit
- Taxes / Interest
= Net Income
```

These relationships are extremely important when building KPIs.

---

# 4. The KPIs Analysts Usually Work With

For a consumer products company like Wyld, the most important GL-aligned metrics are:

| Metric             | Formula                                       | Why It Matters            |
| ------------------ | --------------------------------------------- | ------------------------- |
| Gross Sales        | Total product revenue before discounts        | Topline demand            |
| Net Sales          | Gross Sales – Discounts                       | True revenue              |
| COGS               | Cost to produce goods                         | Unit economics            |
| Gross Margin       | Net Sales – COGS                              | Product profitability     |
| Operating Expenses | Payroll, marketing, rent                      | Business overhead         |
| EBITDA             | Earnings before interest, taxes, depreciation | Operational profitability |

Most dashboards ultimately reconcile to these.

---

# 5. Why Analysts Reconcile to the GL

Operational systems and accounting systems **rarely match perfectly**.

For example:

| System                | Net Sales |
| --------------------- | --------- |
| POS system            | $832,000  |
| Distributor shipments | $830,000  |
| General Ledger        | $810,000  |

A business analyst must investigate why.

Common causes:

| Cause              | Explanation                   |
| ------------------ | ----------------------------- |
| Timing differences | Accounting uses posting dates |
| Returns            | Sales reversed later          |
| Discounts          | Finance adjustments           |
| Accruals           | Expenses recognized later     |
| Data gaps          | Missing operational records   |

Reconciliation ensures analytics is **credible**.

---

# 6. Operational Data vs Financial Data

This distinction trips up many analysts.

Operational systems track **events**.

Financial systems track **financial recognition**.

Example:

| Event    | Operational Date | Accounting Date           |
| -------- | ---------------- | ------------------------- |
| Shipment | Jan 30           | Feb 1 revenue recognition |
| Invoice  | Jan 30           | Jan financial period      |
| Return   | Feb 5            | Jan adjustment            |

This is why numbers rarely align perfectly month-to-month.

---

# 7. Common GL Reconciliation Patterns

A business analyst often builds queries like:

```
Operational Sales (warehouse)
vs
Financial Sales (GL)
```

Example reconciliation logic:

```
Monthly Net Sales (Warehouse)
-
Monthly Net Sales (GL)
=
Variance
```

Variance analysis usually includes:

| Field              | Purpose              |
| ------------------ | -------------------- |
| Difference         | Absolute variance    |
| Percent difference | Scale of error       |
| Tolerance          | Acceptable deviation |

Your SQL recon view in your project is **exactly this pattern**.

---

# 8. Dimensions Analysts Must Understand

Finance numbers often depend on these dimensions:

| Dimension   | Example               |
| ----------- | --------------------- |
| Time        | Month, Quarter        |
| Product     | SKU, product line     |
| Market      | State or region       |
| Channel     | Distributor vs retail |
| Entity      | Legal company         |
| Cost center | Department            |

Example:

```
Revenue by state
Revenue by product
Revenue by distributor
```

These are crucial for **Power BI dashboards**.

---

# 9. Variance Analysis (Very Important)

Business analysts spend a lot of time explaining **why numbers changed**.

Three common variance types:

### Volume variance

More or fewer units sold.

### Price variance

Selling price changed.

### Cost variance

COGS changed due to ingredient costs or manufacturing efficiency.

Example explanation:

```
Net sales increased 12% QoQ due to:

• 7% increase in unit volume
• 3% increase in average selling price
• 2% new market expansion
```

Executives love this type of narrative.

---

# 10. The Data Sources Analysts Usually Combine

A typical analytics stack for a company like Wyld might include:

| System            | Data                     |
| ----------------- | ------------------------ |
| Distributor sales | Shipments                |
| Retail POS        | Sell-through             |
| ERP               | Production and inventory |
| Payroll           | Labor cost               |
| Finance ERP       | GL actuals               |
| Marketing         | Campaign performance     |

Your job is to integrate them.

---

# 11. Common Business Analyst Deliverables

From the job description, the deliverables probably include:

### Power BI dashboards

Examples:

* Sales by product
* Sales by state
* Gross margin trends
* Sales per labor hour
* Inventory turnover

### Variance analysis reports

```
Budget vs Actual
Actual vs Forecast
Actual vs Last Year
```

### Executive presentations

Explain what changed and why.

---

# 12. Data Quality Checks Analysts Should Always Run

Good analysts are skeptical.

Typical checks:

| Check               | Example                 |
| ------------------- | ----------------------- |
| Null checks         | Missing product codes   |
| Outlier detection   | Abnormally large sales  |
| Duplicate detection | Double counted invoices |
| Reconciliation      | Warehouse vs GL         |
| Freshness checks    | Late data feeds         |

Your QA SQL scripts are a **very strong signal of maturity** here.

---

# 13. Questions Analysts Ask When Numbers Don't Match

When recon fails, analysts investigate:

1. Are we using the same **time period**?
2. Are we using the same **metric definition**?
3. Are there **returns or adjustments**?
4. Are we missing **data sources**?
5. Are we using **gross vs net revenue**?

These questions are the bread and butter of the job.

---

# 14. Mental Model for the Role

Think of the business analyst as a translator between three worlds.

```
Operations
   ↓
Analytics
   ↓
Finance
```

Operations says:

> “We sold 12,000 gummies.”

Finance says:

> “Recognized revenue was $810K.”

Executives ask:

> “Why did revenue drop 5%?”

Your job is to connect those dots.

---

# 15. The Three Skills That Matter Most

From the job description, the job really boils down to:

### 1. Data Integration

```
SQL
Power Query
ETL
```

Combine messy sources.

---

### 2. Variance Investigation

```
Why do these numbers differ?
```

This is analytical detective work.

---

### 3. Storytelling

Translate:

```
Complex data → clear explanation
```

Executives do not want SQL.

They want:

> “Sales dropped because distributor inventory was high after the holiday season.”

---

# The Truth About This Job

The technical part is manageable.

The real skill is **reasoning about messy business data**.

Numbers rarely align perfectly.

A strong analyst can look at mismatches and calmly ask:

> “What assumption changed?”

That mindset is far more valuable than memorizing accounting rules.

---
---

Let’s build the **mental dashboard** that someone in Wyld’s finance/analytics team probably lives inside. A cannabis edibles company is essentially a **CPG (consumer packaged goods)** business with some regulatory twists, so the KPIs look very similar to food/beverage companies.

A business analyst doesn’t just calculate these metrics — they explain **why they changed**. That’s the game.

---

# The 15 Most Important Finance KPIs for a Company Like Wyld

Think of these in four layers:

1. **Revenue**
2. **Profitability**
3. **Operational efficiency**
4. **Growth & market performance**

---

# 1. Revenue KPIs

## Gross Sales

This is **total product sales before discounts**.

Formula

```
Gross Sales = Units Sold × Price per Unit
```

Example

```
10,000 gummy packages × $18 wholesale price = $180,000
```

Why it matters
It measures **raw demand**.

Executives ask:

> Are people buying more product?

---

## Net Sales

The most important revenue metric.

```
Net Sales = Gross Sales – Discounts – Returns – Allowances
```

Example

```
Gross Sales     $903,000
Discounts        $72,000
Returns             $300

Net Sales       $830,700
```

Net sales is the **real revenue the company keeps**.

This is usually the number the CFO cares about most.

---

## Sales Growth

Measures how fast the business is growing.

```
Growth % = (Current Period Sales – Previous Period Sales) / Previous Period Sales
```

Example

```
Jan Net Sales: $810k
Feb Net Sales: $860k

Growth = 6.2%
```

Executives use this to answer:

> Are we expanding or stagnating?

---

## Sales by Market (State)

Cannabis companies operate state-by-state because regulations differ.

Example breakdown

| State | Net Sales |
| ----- | --------- |
| OR    | $2.4M     |
| CA    | $5.1M     |
| WA    | $1.2M     |

Analysts look for:

* fastest growing markets
* declining markets
* expansion opportunities

---

## Sales by Product

Example:

| Product                  | Net Sales |
| ------------------------ | --------- |
| Huckleberry Gummies      | $1.3M     |
| Elderberry Sleep Gummies | $900k     |
| Blood Orange CBC         | $600k     |

Executives ask:

> Which products are driving the brand?

---

# 2. Profitability KPIs

These tell you whether the company is **making money on the product**.

---

## Cost of Goods Sold (COGS)

Cost to produce the product.

Includes things like:

* ingredients
* packaging
* manufacturing labor
* production overhead

Example

```
COGS = $328,543
```

---

## Gross Margin

One of the most important metrics in CPG businesses.

```
Gross Margin = Net Sales – COGS
```

Example

```
Net Sales  = $810,000
COGS       = $328,000

Gross Margin = $482,000
```

Executives care because it measures **product profitability**.

---

## Gross Margin %

This shows how profitable each dollar of revenue is.

```
Gross Margin % = Gross Margin / Net Sales
```

Example

```
$482k / $810k = 59.5%
```

Higher is better.

---

## Contribution Margin

Similar to gross margin but may exclude fixed manufacturing costs.

Example

```
Contribution Margin =
Net Sales
– variable costs
```

Useful for **pricing decisions**.

---

# 3. Operational KPIs

These measure efficiency.

---

## Sales per Labor Hour

A very common operations metric.

```
Sales per Labor Hour =
Net Sales / Total Labor Hours
```

Example

```
$810,000 / 7,200 hours = $112 per hour
```

Executives ask:

> Are we staffing efficiently?

---

## Inventory Turnover

Measures how quickly product sells.

```
Inventory Turnover =
COGS / Average Inventory
```

Example

```
COGS = $330k
Avg Inventory = $500k

Turnover = 0.66 per month
```

High turnover means inventory moves quickly.

---

## Days of Inventory

Another inventory efficiency metric.

```
Days Inventory =
Inventory / Average Daily COGS
```

Example

```
Inventory = $500k
Daily COGS = $11k

≈ 45 days of inventory
```

Executives ask:

> Are we overproducing?

---

# 4. Market Performance KPIs

These show how well the company competes.

---

## Market Share

Example

```
Wyld OR sales = $2.4M
Total OR edible market = $20M

Market share = 12%
```

Used to track competitive position.

---

## Average Selling Price (ASP)

Measures pricing.

```
ASP = Net Sales / Units Sold
```

Example

```
$810,000 / 45,000 units = $18
```

Changes may indicate:

* price increases
* discounting
* product mix changes

---

## Product Mix

Example

| Product       | % of Sales |
| ------------- | ---------- |
| Sleep Gummies | 35%        |
| THC Gummies   | 40%        |
| CBD Products  | 25%        |

Analysts watch mix because different products have different margins.

---

# 5. Forecasting KPIs

These support planning.

---

## Budget vs Actual

Example

| Metric    | Budget | Actual |
| --------- | ------ | ------ |
| Net Sales | $820k  | $810k  |
| COGS      | $320k  | $328k  |

Variance

```
Actual – Budget
```

---

## Run Rate

Projects future performance.

Example

```
Monthly sales = $810k

Annual run rate ≈ $9.7M
```

Executives use this to predict growth.

---

# How These KPIs Show Up in Your Portfolio Project

Your project already models several of them:

```
fact_sales_distributor_daily
fact_labor_daily
fact_inventory_snapshot_daily
```

And your recon view:

```
recon_sales_to_gl_monthly
```

is essentially validating:

```
Net Sales
COGS
Gross Margin
```

against the **finance books**.

That’s extremely realistic.

---

# What Executives Actually Want

When they look at dashboards, they usually ask questions like:

• Why did sales drop in Oregon last month?
• Why are margins lower for Sleep gummies?
• Are discounts increasing?
• Are we carrying too much inventory?
• Which markets should we expand into next?

Your job is to connect the numbers to those answers.

---

# The Analyst’s Superpower

A great analyst can look at a dashboard and say something like:

> Net sales declined 4% in February due to reduced distributor orders in California. Inventory levels increased 18%, suggesting distributors are still working through January stock.

That’s what makes an analyst valuable.

---
---

Here’s the dashboard map I’d expect for a company like Wyld. Not because I have a crystal ball, but because CPG finance teams tend to build the same handful of beasts with different costumes.

A Business Analyst there would probably live across **10 core dashboard/report experiences**.

---

# 1. Executive Revenue Overview

This is the “tell me what happened” dashboard.

## Purpose

Give leadership a fast read on revenue performance.

## Core visuals

* Net Sales trend by month
* Gross Sales vs Net Sales
* Gross Margin and Gross Margin %
* Budget vs Actual
* YoY and MoM growth
* Sales by state / market

## Typical filters

* Month / quarter / year
* State
* Product family
* Channel
* Brand

## Questions it answers

* Are we growing?
* Which markets are carrying the business?
* Did margins improve or get punched in the face?

## Good Power BI measures

```DAX
Net Sales = SUM(fact_sales[net_sales])

Gross Margin = SUM(fact_sales[net_sales]) - SUM(fact_sales[cogs])

Gross Margin % = DIVIDE([Gross Margin], [Net Sales])

Sales MoM % =
DIVIDE(
    [Net Sales] - CALCULATE([Net Sales], DATEADD(dim_date[date], -1, MONTH)),
    CALCULATE([Net Sales], DATEADD(dim_date[date], -1, MONTH))
)
```

---

# 2. Sales Performance by Market

For a cannabis company, state-by-state matters a lot because each market is its own weird little kingdom.

## Purpose

Compare performance across states and regions.

## Core visuals

* Map or ranked bar chart of sales by state
* Gross margin by state
* State trend lines
* Top/bottom markets
* Growth % by market

## Questions it answers

* Which state is outperforming?
* Which market is slowing down?
* Where should leadership focus attention?

## Best narrative angle

Do not just show “California = biggest.” That’s obvious. Show:

* fastest growth
* biggest variance to plan
* best margin mix
* underperforming markets

---

# 3. Product / SKU Performance Dashboard

This is where product strategy starts to matter.

## Purpose

Show which products are winning, fading, or underperforming.

## Core visuals

* Sales by SKU
* Sales by flavor / category / product line
* Gross margin % by product
* Units sold
* ASP (average selling price)
* Product mix contribution

## Questions it answers

* Which gummies drive revenue?
* Which products have the best margin?
* Are lower-margin products eating the mix?

## Useful measures

```DAX
Units Sold = SUM(fact_sales[qty_units])

ASP = DIVIDE([Net Sales], [Units Sold])

Product Mix % = DIVIDE([Net Sales], CALCULATE([Net Sales], ALL(dim_product)))
```

This dashboard gets very spicy if you add:

* top 10 / bottom 10 products
* mix shift over time
* launch cohort tracking

---

# 4. Gross-to-Net Waterfall

This is a very finance-friendly dashboard. Also a great portfolio flex.

## Purpose

Explain how gross sales turn into net sales.

## Core visuals

* Waterfall chart:

  * Gross Sales
  * Discounts
  * Returns
  * Allowances
  * Net Sales
* Trend of discount rate over time
* Discount rate by market or product

## Questions it answers

* Why is net sales below gross sales?
* Are discounts creeping up?
* Are certain markets relying too heavily on trade support?

## Why this matters

Your recon issue basically wandered into this swamp already. This dashboard helps expose semantic mismatches before they become executive confusion.

## Useful measure

```DAX
Discount Rate = DIVIDE([Gross Sales] - [Net Sales], [Gross Sales])
```

---

# 5. Margin and Profitability Dashboard

Revenue is vanity, margin is where the knives come out.

## Purpose

Track profitability by product, market, and time.

## Core visuals

* Gross Margin trend
* Gross Margin % by product
* Gross Margin % by market
* Margin bridge by month
* Scatter plot: sales vs margin %

## Questions it answers

* Which products make money?
* Which markets are dragging profitability?
* Did cost inflation hurt margins?

## Best additions

* COGS trend by unit
* price vs cost trend
* margin erosion alerts

If this dashboard is good, finance people start nodding like owls.

---

# 6. Inventory Health Dashboard

This is a big one for CPG. Too much inventory ties up cash. Too little inventory causes stockouts and angry people.

## Purpose

Monitor stock position and inventory efficiency.

## Core visuals

* Inventory on hand by day / week
* Days of inventory
* Inventory turnover
* Slow-moving inventory
* Stockout risk flags
* Aging buckets

## Questions it answers

* Are we overstocked?
* Which SKUs are not moving?
* Where are we at risk of stockouts?

## Useful measures

```DAX
Inventory Turnover = DIVIDE([COGS], [Average Inventory])

Days of Inventory = DIVIDE([Ending Inventory], DIVIDE([COGS], COUNTROWS(VALUES(dim_date[date]))))
```

For your project, even a simpler version with:

* ending inventory
* rolling average inventory
* inventory days
  would already look strong.

---

# 7. Labor Efficiency Dashboard

This lines up directly with your modeled labor KPI work.

## Purpose

Show how labor inputs relate to output and revenue.

## Core visuals

* Labor hours by day / week
* Sales per labor hour
* Labor cost per sales dollar
* Hours by site/team
* Trend of staffing vs sales

## Questions it answers

* Are we staffing efficiently?
* Did labor rise faster than sales?
* Which locations or teams are most efficient?

## Measures

```DAX
Sales per Labor Hour = DIVIDE([Net Sales], [Labor Hours])

Labor Cost % of Sales = DIVIDE([Labor Cost], [Net Sales])
```

A very strong visual here is:

* combo chart of sales and labor hours
* scatter plot of labor hours vs net sales by store/day

That shows operational leverage beautifully.

---

# 8. Forecast vs Actual / Plan vs Actual Dashboard

Finance loves this one because it turns hindsight into judgment.

## Purpose

Compare performance against plan, budget, or forecast.

## Core visuals

* Actual vs Budget bars
* Variance waterfall
* Variance % heatmap by market/product
* Forecast accuracy trend

## Questions it answers

* Where did we miss plan?
* Was the miss revenue, margin, or cost-driven?
* Which assumptions were wrong?

## Core measures

```DAX
Variance to Budget = [Actual] - [Budget]

Variance to Budget % = DIVIDE([Variance to Budget], [Budget])
```

This is a high-value dashboard because executives care less about “what happened” than “what happened versus expectation.”

---

# 9. Data Quality / Reconciliation Controls Dashboard

This is the sneaky portfolio gem. Most candidates do not build this, which is exactly why you should.

## Purpose

Show trustworthiness of the data pipeline.

## Core visuals

* Freshness status by table
* Row count trend
* Failed QA checks
* Reconciliation statuses
* Missing dimension joins
* Exceptions by domain

## Questions it answers

* Can we trust the dashboard?
* Which pipeline component is stale?
* Are finance and operations aligned?

## Great source tables

You already have the bones for this:

* `mart.controls_rowcounts_daily`
* `mart.controls_missing_dim_joins`
* `mart.recon_sales_distributor_vs_pos`
* `mart.recon_sales_to_gl_monthly`
* `controls_freshness`

This is extremely good for a Wyld-style role because the JD explicitly talks about:

* QA/QC
* reconciling across sources
* tracking gaps and discrepancies
* process integrity and completeness

That is basically a neon sign saying: build the trust layer.

---

# 10. Executive Narrative / KPI Scorecard Page

This is the “board-meeting-friendly” page.

## Purpose

Turn all the detailed analysis into a simple decision view.

## Core visuals

* KPI cards:

  * Net Sales
  * Gross Margin %
  * Inventory Days
  * Sales per Labor Hour
  * Budget Variance
* Red/yellow/green indicators
* Small trend sparklines
* Top 3 insights / concerns
* Optional commentary panel

## Questions it answers

* What matters most this month?
* Where should leadership act?
* What changed, in plain English?

## Best practice

This page should not look like Times Square ate a chart factory. Keep it calm:

* 5–7 KPI cards
* 2–3 supporting visuals
* one narrative section

---

# If I were designing your portfolio Power BI file

I’d structure it like this:

## Page 1 — Executive Summary

The top-level KPI scorecard.

## Page 2 — Sales & Market Performance

Revenue trends, state performance, product mix.

## Page 3 — Margin & Gross-to-Net

Gross sales, net sales, discounts, margin.

## Page 4 — Inventory & Operations

Inventory days, turnover, stock risk.

## Page 5 — Labor Productivity

Sales per labor hour, staffing efficiency.

## Page 6 — QA / Reconciliation Controls

Freshness, failures, recon status, exceptions.

That would be a very strong portfolio architecture for this job.

---

# What Wyld would probably care about most

If I had to guess which pages would matter most for this role:

1. **Executive Summary**
2. **Sales & Market Performance**
3. **Margin / Gross-to-Net**
4. **QA / Reconciliation Controls**
5. **Labor Efficiency**
6. **Inventory Health**

Why? Because the JD is screaming:

* consolidate multiple sources
* reconcile discrepancies
* create understandable reporting
* support business decisions
* maintain reporting integrity

That is not just “make a pretty dashboard.” It is “make a trustworthy business decision system.”

---

# The sneaky edge for your portfolio

Most people build:

* sales charts
* margin charts
* map charts

Fewer people build:

* reconciliation dashboards
* data quality controls
* bridge pages that explain gross-to-net logic
* pages that connect sales, labor, and inventory together

That cross-functional stitching is exactly what makes a Business Analyst look useful instead of decorative.

---

# The most realistic KPI set to highlight in interviews

If you present your project, I’d emphasize these as your headline metrics:

* Net Sales
* Gross Margin %
* Sales Growth %
* Sales by Market
* Sales by Product
* Inventory Days
* Sales per Labor Hour
* Actual vs Budget Variance
* Reconciliation Status
* Freshness Status

That’s a crisp, job-relevant set.

---

# The simplest way to talk about your project

You could describe it like this:

> I built a multi-source business analytics model that integrates sales, labor, inventory, and finance actuals into a Power BI reporting layer. The project includes conformed dimensions, stable mart facts, reconciliation controls, and QA checks so stakeholders can trust both the KPIs and the story behind them.

That sentence is doing real work. It tells them you understand both data modeling and business meaning, which is the whole cheese wheel here.




---
---


> I can sketch the exact **Power BI page architecture and visual layout** for these 6 pages next, so you have a blueprint for what goes top-left, top-right, middle, and bottom on each report page.

Here’s a clean **6-page Power BI blueprint** for your Wyld-style portfolio project. This is meant to be practical, not decorative nonsense with 47 charts fighting in a parking lot.

The guiding rule:

* **top = what happened**
* **middle = why**
* **bottom = where to investigate**

Also: every page should answer one main business question.

---

# Overall report structure

## Global filters for most pages

Put these in a consistent left panel or top ribbon:

* Date
* State / market
* Product family
* SKU
* Channel
* Brand
* Distributor or store if relevant

## Global design rules

Use the same layout rhythm on every page:

* **Top row:** KPI cards
* **Middle row:** trend + comparison visuals
* **Bottom row:** detail table / exceptions / drivers

That makes the report feel like one system instead of six unrelated chart goblins.

---

# Page 1 — Executive Summary

## Main question

**How is the business performing overall, and where should leadership focus first?**

## Layout

### Top row

Use **6 KPI cards** across the top:

* Net Sales
* Gross Margin %
* Sales Growth %
* Inventory Days
* Sales per Labor Hour
* Recon Status / QA Status

These should include:

* current period value
* variance vs prior period or budget
* small indicator arrow

### Middle left

**Net Sales trend by month**

* line chart
* show current month, prior month, prior year if available

### Middle center

**Gross Margin % trend**

* line chart

### Middle right

**Budget vs Actual waterfall or clustered column**

* Net Sales
* Gross Margin
* maybe Labor Cost

### Bottom left

**Sales by State**

* ranked bar chart, not necessarily a map
* maps are flashy but often less readable than bars

### Bottom center

**Sales by Product Family**

* bar or treemap
* gummies / beverage / enhanced / sleep / etc.

### Bottom right

**Narrative insight box**
This is important. A simple text area or card section with 3 bullets like:

* Net sales down 4.2% MoM, driven by lower California distributor orders
* Gross margin improved 1.8 pts due to favorable product mix
* Inventory days rose to 47, suggesting slower sell-through after January

That is the executive candy.

---

# Page 2 — Sales & Market Performance

## Main question

**Where is revenue coming from, and which markets/products are driving change?**

## Layout

### Top row

KPI cards:

* Net Sales
* Gross Sales
* Units Sold
* ASP
* Market Share proxy if available
* Active SKUs / Active Markets

### Middle left

**Monthly Net Sales by Market**

* stacked column or line chart by state
* alternatively small multiples by state

### Middle center

**Top 10 States by Net Sales**

* horizontal bar chart

### Middle right

**Market Growth %**

* bar chart sorted descending
* make underperformers obvious

### Bottom left

**Product Mix by Market**

* matrix or stacked bar
* rows = market
* columns = product family
* values = % of sales

### Bottom center

**Top Products by Sales**

* bar chart with SKU/product name

### Bottom right

**Detail table**
Columns:

* State
* Product family
* Net Sales
* Units
* ASP
* Margin %
* MoM %
* YoY %

This page should let someone quickly say:
“California is still biggest, Oregon margin is better, and Sleep gummies are gaining share.”

---

# Page 3 — Margin & Gross-to-Net

## Main question

**Are we making money efficiently, and what is happening between gross sales and net sales?**

This page is finance-flavored and very interview-friendly.

## Layout

### Top row

KPI cards:

* Gross Sales
* Net Sales
* Discount Rate
* COGS
* Gross Margin
* Gross Margin %

### Middle left

**Gross-to-Net waterfall**
Steps:

* Gross Sales
* Discounts
* Returns / Allowances
* Net Sales

This is a star visual for this role.

### Middle center

**Gross Margin trend**

* month trend
* maybe with margin % as line and net sales as columns if readable

### Middle right

**Discount Rate by Market or Product**

* bar chart

### Bottom left

**COGS and Net Sales trend**

* combo chart or two separate visuals
* keep readable

### Bottom center

**Margin % by Product Family**

* bar chart sorted descending

### Bottom right

**Variance detail table**
Columns:

* Product / market
* Gross Sales
* Net Sales
* Discount Rate
* COGS
* Gross Margin %
* variance vs prior month

This page is where you explain why big topline doesn’t always mean healthy business.

---

# Page 4 — Inventory & Operations

## Main question

**Are we carrying the right amount of inventory, and is inventory moving efficiently?**

## Layout

### Top row

KPI cards:

* Ending Inventory
* Average Inventory
* Inventory Turnover
* Days of Inventory
* Slow-moving SKU count
* Stockout risk count

### Middle left

**Inventory trend over time**

* line chart of ending inventory

### Middle center

**Days of Inventory by Product Family**

* bar chart

### Middle right

**Inventory Aging**

* stacked bar or buckets:

  * 0–30 days
  * 31–60
  * 61–90
  * 90+

### Bottom left

**Slow-moving SKUs**

* bar chart or table
* rank worst offenders

### Bottom center

**Inventory vs Sales trend**

* dual-axis only if readable; otherwise separate aligned charts
* the goal is to show whether inventory is outrunning sales

### Bottom right

**Exception table**
Columns:

* SKU
* State / warehouse
* On hand qty
* Days on hand
* Recent sales
* Risk flag

This is a nice place for conditional formatting:

* green normal
* amber watch
* red excess / stockout risk

---

# Page 5 — Labor Productivity

## Main question

**Are labor inputs aligned with business output?**

This page helps prove you can connect People + Sales + Ops.

## Layout

### Top row

KPI cards:

* Labor Hours
* Labor Cost if available
* Sales per Labor Hour
* Labor Cost % of Sales
* Avg Hours per Day
* Productivity trend %

### Middle left

**Sales vs Labor Hours over time**

* combo chart
* columns = sales
* line = labor hours
  or separate aligned visuals if clearer

### Middle center

**Sales per Labor Hour by Site / Market**

* bar chart

### Middle right

**Labor Hours by Team / Function**

* stacked bar if you have team detail
* if not, use state/store/date grain

### Bottom left

**Scatter plot: Labor Hours vs Net Sales**

* each dot = store-day or market-day
* this is great for spotting efficiency outliers

### Bottom center

**Trend of labor productivity**

* line chart for sales per labor hour

### Bottom right

**Exception table**
Columns:

* Date
* Site
* Sales
* Labor hours
* Sales per labor hour
* flag for low productivity

This page should make it obvious where staffing is heavy relative to output.

---

# Page 6 — QA / Reconciliation Controls

## Main question

**Can stakeholders trust the data and the KPI layer?**

This is your secret weapon page.

## Layout

### Top row

KPI cards:

* Fresh tables %
* Failed QA checks
* Failed recon checks
* Missing dim joins
* Late sources count
* Last successful build date

### Middle left

**Freshness status by table**

* table or matrix with:

  * table name
  * max date
  * expected lag
  * status

### Middle center

**QA failures by domain**

* bar chart
* sales / inventory / labor / finance / controls

### Middle right

**Recon status summary**

* donut or bar:

  * pass
  * warn
  * fail

### Bottom left

**Sales-to-GL recon detail**

* matrix or table:

  * period_month
  * metric
  * mart_amount
  * gl_amount
  * diff_amount
  * pct_diff
  * status

### Bottom center

**Missing dimension joins / exceptions**

* table by fact table + missing key type

### Bottom right

**Row count / freshness trend**

* line chart
* useful for spotting source drop issues

This page directly supports the job description’s emphasis on:

* QA/QC
* discrepancies
* timeliness
* completeness
* assurance support

That is résumé gold, frankly.

---

# Navigation flow

The pages should tell a story in this order:

1. **Executive Summary** — what happened
2. **Sales & Market** — where it happened
3. **Margin & Gross-to-Net** — why revenue translated the way it did
4. **Inventory & Operations** — operational support and constraints
5. **Labor Productivity** — resource efficiency
6. **QA / Controls** — can we trust the system

That order mirrors how a stakeholder thinks.

---

# Best visual choices by page

A few strong defaults:

* KPI cards for headline metrics
* line charts for trends
* horizontal bar charts for ranked comparisons
* waterfall for bridges and variance explanations
* matrices/tables for detail and exception handling
* scatter plots for relationship spotting
* avoid pie charts except maybe one tiny status distribution
* avoid maps unless geography truly matters more than readability

Maps are often chart theater. Bars usually tell the truth better.

---

# Suggested DAX measure groups

Organize your measures into display folders if you can:

## Revenue

* Gross Sales
* Net Sales
* Units Sold
* ASP
* Sales Growth %

## Profitability

* COGS
* Gross Margin
* Gross Margin %

## Inventory

* Ending Inventory
* Avg Inventory
* Inventory Turnover
* Days of Inventory

## Labor

* Labor Hours
* Sales per Labor Hour
* Labor Cost % of Sales

## Variance

* Budget
* Forecast
* Variance to Budget
* Variance %

## Controls

* Failed QA Count
* Failed Recon Count
* Freshness Status
* Missing Join Count

This makes the model feel deliberate instead of like a sock drawer after a tornado.

---

# Page design tips for this job

For a Finance Business Analyst audience:

* Keep pages clean and businesslike
* Use restrained colors
* Reserve red for failures or high-risk exceptions
* Label metrics clearly
* Prefer “Net Sales” over cryptic abbreviations
* Add tooltip pages for formulas and definitions
* Put definitions somewhere visible for Gross Sales, Net Sales, Margin %, etc.

That last one matters because half of analytics warfare is just people using the same words to mean different things.

---

# Minimum viable build order

If you do not want to build all six at once, build in this order:

1. Executive Summary
2. Sales & Market
3. Margin & Gross-to-Net
4. QA / Controls
5. Labor
6. Inventory

That sequence gives you maximum job relevance fastest.

---

# What to say in an interview

You can describe the report architecture like this:

> I designed the report in layers: an executive summary for high-level performance, then drilldown pages for sales, margin, inventory, and labor, plus a QA/reconciliation page to make the reporting layer auditable and trustworthy.

That sounds exactly like someone who understands the actual job, not just how to drop charts onto a canvas.

---
---

>>> Next I can sketch a **star schema / semantic model blueprint** for these Power BI pages — facts, dimensions, keys, and which page uses which table.

