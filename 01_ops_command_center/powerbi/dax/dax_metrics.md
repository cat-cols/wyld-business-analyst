
For a cannabis edibles company like Wyld (multi-product, multi-state, promo-heavy, retail/distributor complexity), you usually need a **stack of pricing + volume + margin + inventory + mix metrics** working together. Wyld’s product positioning (consistent dosing, gummies, multiple cannabinoid/ratio formats) makes mix and price architecture especially important. ([Wyld][1])

---

>## 1) Net Sales and Gross Sales

These are foundational, not optional.

* **Gross Sales** = before discounts/promos
* **Net Sales** = after discounts/allowances

Why it matters:

* You can’t interpret VWAP without knowing whether revenue is growing because of **price**, **volume**, or **discounting**
* Cannabis/CPG promos can make “sales growth” look better than realized profitability

**Useful pair with VWAP:**

* Gross VWAP vs Net VWAP
* Gross Sales vs Net Sales

---

>## 2) Volume and Unit Velocity

VWAP tells you price realization. You also need to know whether products are moving.

### Key metrics

* **Units Sold**
* **Unit Growth % (MoM / YoY)**
* **SKU Velocity** (units per store per week, units per account per week)
* **Sell-through %** (if you have shipped vs retail sold data)

Why it matters:

* A rising VWAP can be bad if volume collapses
* A lower VWAP can be good if it drives velocity and margin dollars

This is especially relevant because Wyld roles often call out tracking inventory movement and omnichannel performance, not just topline sales. ([Indeed][2])

---

>## 3) Product Mix %

This one is sneaky-important in edibles.

### What to track

* % of revenue by:

  * **Flavor**
  * **Cannabinoid type** (THC / CBN / CBD / CBG / ratio)
  * **Pack size**
  * **State**
  * **Channel/account**
* % of units by the same slices

Why it matters:

* Your average price can move just because the mix shifts toward premium or higher-dose SKUs
* A “pricing issue” is often really a **mix issue**

Example:

* If CBN sleep gummies gain share, total VWAP might rise even with no list-price changes (and this kind of category shift has been happening in market trends). ([SFGATE][3])

---

>## 4) Gross Margin % and Gross Margin Dollars

If I had to pick a metric that fights with VWAP for “most important,” this is it.

### Metrics

* **Gross Margin %**
* **Gross Margin $**
* **Margin per Unit**
* **Margin per SKU / State / Account**

Why it matters:

* VWAP can look healthy while margins get wrecked by COGS, promo spend, or wholesale concessions
* Finance teams care deeply about **profit dollars**, not just price realization

A lot of cannabis operator KPI guidance emphasizes margin metrics because taxes/fees/COGS/regulatory overhead make gross revenue misleading by itself. ([The Cannabis CPA\'s][4])

---

>## 5) Discount Rate and Promo Lift

This is a business analyst goldmine.

### Metrics

* **Discount %** = (Gross Sales - Net Sales) / Gross Sales
* **Promo Penetration %** = % units sold on promo
* **Promo Lift** = (units during promo - baseline units) / baseline units
* **Promo ROI** = incremental margin / promo cost

Why it matters:

* Tells you whether discounts are creating real incremental demand or just giving away margin
* Helps answer the classic finance/sales food fight:

  * “We need more promos”
  * “No, promos are killing profitability”

VWAP + Discount % + Promo Lift is an elite combo.

---

>## 6) Distribution and Rate of Sale

For a brand like Wyld, this is huge.

### Metrics

* **Doors / Active Accounts** (how many retailers carry the product)
* **Weighted Distribution** (if available from syndicated data)
* **Rate of Sale** = units per active account per week
* **On-shelf availability / In-stock %**

Why it matters:

* Revenue can grow because you gained more stores, not because products are performing better
* Rate-of-sale tells you whether the product is actually winning where it’s stocked

This also matches the “track, trace, and communicate omnichannel performance / inventory movement” flavor of the role. ([Indeed][2])

---

>## 7) Inventory Health Metrics

Necessary if you touch operations (and the Wyld postings suggest cross-functional work across sales/ops/people).

### Core metrics

* **Days of Inventory on Hand (DOH / DIO)**
* **Inventory Turnover**
* **Stockout Rate**
* **Aging Inventory %**
* **Fill Rate / OTIF** (on-time, in-full), if supply chain data exists

Why it matters:

* Cannabis products are regulated, shelf-life-sensitive, and operationally messy
* Fast sell-through with frequent stockouts = lost sales
* Slow sell-through = cash tied up + risk of write-offs

---

>## 8) Forecast Accuracy

This is the “grown-up analyst” metric.

### Metrics

* **MAPE** (Mean Absolute Percentage Error)
* **Bias** (systematically over/under-forecasting)
* **Forecast Accuracy %** by SKU/state/week

Why it matters:

* Better forecasts improve production planning, inventory, and promo timing
* You become way more valuable when you improve decisions, not just report results

The Wyld BA posting language around decision-making models and cross-functional support screams “forecasting and planning hygiene” even if they don’t use that exact phrase. ([Indeed][2])

---

>## 9) Customer / Account Concentration

For wholesale-heavy brands, concentration risk matters.

### Metrics

* **Top 10 accounts % of sales**
* **Revenue concentration by distributor / chain / region**
* **Account growth vs account dependency**

Why it matters:

* If one account drives too much volume, your revenue is fragile
* Helps sales leadership prioritize account diversification

---

>## 10) Price Pack Architecture Metrics

Super important in edibles.

### Metrics

* **Price per Pack**
* **Price per Gummy**
* **Price per mg THC (or cannabinoid-specific mg)**
* **Net Revenue per mg**
* **Margin per mg**

Why it matters:

* Cannabis consumers compare value in weird ways (pack, dosage, cannabinoid, effect)
* For Wyld’s product variety (THC/CBN/CBD/ratio), potency-adjusted metrics can reveal what’s really priced “premium” vs just packaged differently. ([Wyld][1])

This is the cousin of VWAP that most analysts miss.

---

>## 11) Repeat Purchase / Retention Signals

If you have retail scan or loyalty-level data, this becomes a cheat code.

### Metrics

* **Repeat Rate**
* **Time to Repeat**
* **Cohort retention**
* **Customer lifetime value (if DTC/hemp side data exists)**

Why it matters:

* Tells you whether growth is sustainable or just trial
* Great for product launches and new cannabinoid formats

---

>## 12) Variance Analysis (Price / Volume / Mix decomposition)

This is one of the most useful “finance + business analyst” outputs.

### Decompose revenue change into:

* **Price effect**
* **Volume effect**
* **Mix effect**
* (Sometimes distribution effect too)

Why it matters:

* Instead of saying “sales are up 8%,” you can say:

  * “+3% from volume”
  * “+2% from favorable mix”
  * “+3% from net price”
* This is decision-grade analysis and exactly the kind of thing hiring managers love

---

>## The “minimum viable KPI stack” I’d track at Wyld

If you want the practical shortlist (the stuff I’d build first in Power BI):

1. **Gross Sales**
2. **Net Sales**
3. **Units Sold**
4. **Gross VWAP**
5. **Net VWAP**
6. **Discount %**
7. **Gross Margin %**
8. **Gross Margin $**
9. **SKU Velocity (units/store/week)**
10. **Inventory DOH**
11. **Stockout Rate**
12. **Revenue Price/Volume/Mix decomposition**

That set covers pricing, demand, profitability, and operations without turning the dashboard into a spaceship cockpit.

---

## 💡💡 Very Wyld-specific angle that will make your dashboard stronger

Because Wyld has multiple effect/cannabinoid product types (THC, CBN, CBD, ratio products, etc.), build a **Cannabinoid Mix Performance** page:

* Revenue by cannabinoid family
* Net VWAP by cannabinoid family
* Margin % by cannabinoid family
* Velocity by cannabinoid family
* Promo dependence by cannabinoid family

That gives leadership a direct answer to:
**“Which product effects/formulations are actually driving profitable growth?”**

That’s a very business-analyst-at-Wyld kind of question.

If you want, next move is I can map these into a **Power BI metric framework** (measures + dimensions + page layout) so your portfolio dashboard looks like something a finance/sales ops team would actually use.

[1]: https://www.wyldcanna.com/us/products/?utm_source=chatgpt.com "Wyld Products | America's Favorite Cannabis Gummies"
[2]: https://www.indeed.com/q-business-analyst-l-tualatin%2C-or-jobs.html?utm_source=chatgpt.com "Business Analyst Jobs, Employment in Tualatin, OR"
[3]: https://www.sfgate.com/cannabis/article/new-california-sleep-aid-market-share-20323767.php?utm_source=chatgpt.com "New sleep aid jumps 525% in market share in 5 years. But does it work?"
[4]: https://thecannacpas.com/essential-kpis-for-cannabis-business-owners-and-how-to-track-them/?utm_source=chatgpt.com "Essential KPIs for Cannabis Business Owners (and How to ..."


Absolutely. This is the kind of metric library that turns a dashboard from “pretty chart machine” into “actual decision tool.”

A quick truth-bomb before the DAX dump: a few of these metrics (especially **Promo Lift, Distribution, Forecast Accuracy, Repeat Purchase, and Price/Volume/Mix decomposition**) depend heavily on your **data model and grain** (daily vs weekly, account-level vs retail scan, snapshot inventory tables, etc.). So I’ll give you **production-style DAX patterns** that are useful and adaptable.

># Q: Why does it depend on my data model and grain?
> CHECK A: Because the math is different for different data models and grains. For example, if you have a daily sales table, you can’t just sum units sold and divide by distinct accounts because you’d be double-counting accounts with multiple sales. You need to use `CALCULATE` with `DISTINCTCOUNT` to get the right count.

---

# Assumed Power BI Model (example)

### Fact table: `Sales`

Columns (example names):

* `Sales[Date]`
* `Sales[Brand]`
* `Sales[ProductID]`
* `Sales[ProductName]`
* `Sales[AccountID]`
* `Sales[State]`
* `Sales[UnitsSold]`
* `Sales[GrossUnitPrice]`
* `Sales[NetUnitPrice]`
* `Sales[GrossSalesAmount]` *(optional, else calculated)*
* `Sales[NetSalesAmount]` *(optional, else calculated)*
* `Sales[COGSAmount]`
* `Sales[IsPromo]` (TRUE/FALSE or 1/0)
* `Sales[InStockFlag]` (1 if in stock, 0 if stockout snapshot row)
* `Sales[InventoryUnitsOnHand]` *(if inventory snapshots live here; otherwise separate table)*
* `Sales[CustomerID]` *(if consumer/loyalty-level data exists)*

### Optional fact tables (recommended)

* `InventorySnapshots` (daily inventory by SKU/account)
* `Forecast` (forecasted units or sales by date/SKU/account)
* `StoreStatus` (active doors/accounts)
* `RepeatOrders` or customer-level transactions

### Date table

* `DimDate[Date]` (marked as date table)
* `DimDate[WeekStart]`, `DimDate[Month]`, etc.

---

# Foundation Measures (start here)

These are the “atoms” everything else builds on.

```DAX
Volume Units =
SUM(Sales[UnitsSold])
```

```DAX
Gross Sales =
SUMX(
    Sales,
    Sales[GrossUnitPrice] * Sales[UnitsSold]
)
```

> If you already have a `Sales[GrossSalesAmount]` column, use `SUM(Sales[GrossSalesAmount])` instead.

```DAX
Net Sales =
SUMX(
    Sales,
    Sales[NetUnitPrice] * Sales[UnitsSold]
)
```

> If you already have `Sales[NetSalesAmount]`, use that directly.

```DAX
COGS $ =
SUM(Sales[COGSAmount])
```

```DAX
Gross Margin $ =
[Net Sales] - [COGS $]
```

```DAX
Gross Margin % =
DIVIDE([Gross Margin $], [Net Sales])
```

```DAX
Discount $ =
[Gross Sales] - [Net Sales]
```

```DAX
Discount Rate =
DIVIDE([Discount $], [Gross Sales])
```

---

# VWAP (you already asked for these, included for completeness)

```DAX
Gross VWAP =
DIVIDE([Gross Sales], [Volume Units])
```

```DAX
Net VWAP =
DIVIDE([Net Sales], [Volume Units])
```

---

# Unit Velocity / Rate of Sale / Distribution

These are closely related and often confused, so let’s make them clean.

## Distribution (Active Accounts / Doors)

This depends on what “distribution” means in your company.

### A) Active Accounts (sold at least 1 unit in current context)

```DAX
Active Accounts (Sold) =
CALCULATE(
    DISTINCTCOUNT(Sales[AccountID]),
    Sales[UnitsSold] > 0
)
```

### B) Total Eligible Accounts (if you have a store/account master table)

If you have `DimAccount[AccountID]` and a relationship:

```DAX
Total Accounts =
DISTINCTCOUNT(DimAccount[AccountID])
```

### C) Numeric Distribution %

```DAX
Numeric Distribution % =
DIVIDE([Active Accounts (Sold)], [Total Accounts])
```

---

## Rate of Sale (ROS)

Usually “units per active account” over the selected period.

```DAX
Rate of Sale (Units per Active Account) =
DIVIDE([Volume Units], [Active Accounts (Sold)])
```

---

## Unit Velocity (Units / Store / Week)

If your context is monthly or arbitrary date ranges, normalize by weeks.

```DAX
Weeks in Context =
DIVIDE(
    DISTINCTCOUNT(DimDate[Date]),
    7
)
```

```DAX
Unit Velocity (Units/Store/Week) =
DIVIDE(
    [Volume Units],
    [Active Accounts (Sold)] * [Weeks in Context]
)
```

> If you have a proper `DimDate[WeekStart]`, use distinct weeks instead for cleaner math:

```DAX
Weeks in Context (Distinct) =
DISTINCTCOUNT(DimDate[WeekStart])
```

```DAX
Unit Velocity (Units/Store/Week) =
DIVIDE(
    [Volume Units],
    [Active Accounts (Sold)] * [Weeks in Context (Distinct)]
)
```

---

# Product Mix %

You can define mix on **sales**, **units**, or **margin**. The most common is sales mix.

## Product Mix % (Net Sales)

This works when slicing by product/cannabinoid/flavor/etc.

```DAX
Product Mix % (Net Sales) =
DIVIDE(
    [Net Sales],
    CALCULATE([Net Sales], ALLSELECTED(Sales[ProductName]))
)
```

If you want mix across all products regardless of slicer on product, use `ALL` instead of `ALLSELECTED`.

## Unit Mix %

```DAX
Product Mix % (Units) =
DIVIDE(
    [Volume Units],
    CALCULATE([Volume Units], ALLSELECTED(Sales[ProductName]))
)
```

---

# Promo Metrics (Promo Lift, Promo Penetration, Promo Rate)

## Promo Sales / Units

```DAX
Promo Units =
CALCULATE(
    [Volume Units],
    Sales[IsPromo] = TRUE()
)
```

```DAX
Non-Promo Units =
CALCULATE(
    [Volume Units],
    Sales[IsPromo] = FALSE()
)
```

```DAX
Promo Net Sales =
CALCULATE(
    [Net Sales],
    Sales[IsPromo] = TRUE()
)
```

## Promo Penetration %

```DAX
Promo Penetration % (Units) =
DIVIDE([Promo Units], [Volume Units])
```

---

## Promo Lift (simple pattern)

Promo Lift requires a **baseline**. The cleanest practical approach is:

* compare **promo velocity** vs **non-promo velocity** in same selected context

### Promo ROS

```DAX
Promo ROS =
DIVIDE(
    [Promo Units],
    CALCULATE([Active Accounts (Sold)], Sales[IsPromo] = TRUE())
)
```

### Non-Promo ROS

```DAX
Non-Promo ROS =
DIVIDE(
    [Non-Promo Units],
    CALCULATE([Active Accounts (Sold)], Sales[IsPromo] = FALSE())
)
```

### Promo Lift %

```DAX
Promo Lift % =
DIVIDE(
    [Promo ROS] - [Non-Promo ROS],
    [Non-Promo ROS]
)
```

> Working theory note: this is a decent dashboard metric, but “true” lift analysis usually needs matched time windows (pre/post) or test-vs-control.

---

# Inventory Health Metrics

These are best with a separate snapshot table (`InventorySnapshots`) at daily SKU/account grain.

## Assumed `InventorySnapshots` columns

* `InventorySnapshots[Date]`
* `InventorySnapshots[ProductID]`
* `InventorySnapshots[AccountID]`
* `InventorySnapshots[OnHandUnits]`
* `InventorySnapshots[InStockFlag]` (1/0)

## Inventory On Hand (Units)

```DAX
Inventory On Hand Units =
SUM(InventorySnapshots[OnHandUnits])
```

---

## Average Daily Units Sold

```DAX
Avg Daily Units Sold =
DIVIDE(
    [Volume Units],
    DISTINCTCOUNT(DimDate[Date])
)
```

---

## Days of Inventory on Hand (DOH / DIO)

```DAX
Days Inventory On Hand =
DIVIDE([Inventory On Hand Units], [Avg Daily Units Sold])
```

---

## Inventory Turnover (units-based proxy)

Traditional turnover uses COGS / Avg Inventory Value, but units-based is often easier.

```DAX
Average Inventory Units =
AVERAGEX(
    VALUES(DimDate[Date]),
    CALCULATE([Inventory On Hand Units])
)
```

```DAX
Inventory Turnover (Units) =
DIVIDE([Volume Units], [Average Inventory Units])
```

---

## Aging Inventory % (if you track received date / age buckets)

This needs inventory lot/aging data. Example assumes `InventorySnapshots[AgeBucket]`.

```DAX
Aged Inventory Units (90+ Days) =
CALCULATE(
    [Inventory On Hand Units],
    InventorySnapshots[AgeBucket] = "90+"
)
```

```DAX
Aged Inventory % (90+ Days) =
DIVIDE([Aged Inventory Units (90+ Days)], [Inventory On Hand Units])
```

---

# Forecast Accuracy (MAPE, Bias)

Best with a separate `Forecast` table related by date/product/account.

## Assumed `Forecast` table

* `Forecast[Date]`
* `Forecast[ProductID]`
* `Forecast[AccountID]`
* `Forecast[ForecastUnits]`

And actuals come from `Sales`.

## Forecast Units

```DAX
Forecast Units =
SUM(Forecast[ForecastUnits])
```

## Forecast Error

```DAX
Forecast Error Units =
[Volume Units] - [Forecast Units]
```

## Forecast Bias %

Positive = underforecasted actuals (depending on convention)

```DAX
Forecast Bias % =
DIVIDE([Forecast Error Units], [Forecast Units])
```

## MAPE (Mean Absolute Percentage Error)

This should be computed at a lower grain (date/product/account) then averaged.

```DAX
MAPE % =
AVERAGEX(
    SUMMARIZE(
        Sales,
        DimDate[Date],
        Sales[ProductID],
        Sales[AccountID]
    ),
    VAR ActualUnits = CALCULATE([Volume Units])
    VAR FcstUnits =
        CALCULATE([Forecast Units])
    RETURN
        IF(
            ActualUnits > 0,
            ABS(DIVIDE(ActualUnits - FcstUnits, ActualUnits)),
            BLANK()
        )
)
```

> This one is sensitive to table relationships. If Forecast granularity differs, we can tune it.

---

# Customer / Account Concentration

## Total Net Sales (for concentration denominator)

```DAX
Total Net Sales (All Accounts) =
CALCULATE(
    [Net Sales],
    ALL(Sales[AccountID])
)
```

## Account Concentration % (current account row)

Use in a table by account.

```DAX
Account Revenue Share % =
DIVIDE([Net Sales], [Total Net Sales (All Accounts)])
```

## Top 10 Accounts % of Sales

```DAX
Top 10 Accounts Net Sales =
SUMX(
    TOPN(
        10,
        VALUES(Sales[AccountID]),
        [Net Sales],
        DESC
    ),
    [Net Sales]
)
```

```DAX
Top 10 Accounts % of Sales =
DIVIDE([Top 10 Accounts Net Sales], [Total Net Sales (All Accounts)])
```

---

# Price Pack Architecture Metrics

This is huge for cannabis.

## Price per Pack (basically Net VWAP if one row = one pack)

```DAX
Net Price per Pack =
[Net VWAP]
```

## Price per Unit (same as above if unit = pack)

```DAX
Net Price per Unit =
[Net VWAP]
```

## Price per Gummy (if you have gummies per pack)

Assume `Sales[GummiesPerPack]`.

```DAX
Total Gummies Sold =
SUMX(Sales, Sales[UnitsSold] * Sales[GummiesPerPack])
```

```DAX
Net Price per Gummy =
DIVIDE([Net Sales], [Total Gummies Sold])
```

---

## Price per mg THC (or cannabinoid)

Assume `Sales[THCMgPerPack]` and `Sales[CBDMgPerPack]`.

```DAX
Total THC mg Sold =
SUMX(Sales, Sales[UnitsSold] * Sales[THCMgPerPack])
```

```DAX
Net Revenue per THC mg =
DIVIDE([Net Sales], [Total THC mg Sold])
```

```DAX
Gross Margin per THC mg =
DIVIDE([Gross Margin $], [Total THC mg Sold])
```

You can repeat this pattern for CBN/CBD/CBG.

---

# Repeat Purchase / Retention Signals

This requires consumer/customer-level transaction data (`CustomerID`). If you only have wholesale account data, you can do **account retention** instead.

## A) Repeat Customer Rate (consumer-level)

Count customers with 2+ orders in selected period.

### Orders per Customer

(Measure used inside iterators)

```DAX
Orders Count =
DISTINCTCOUNT(Sales[OrderID])
```

### Repeat Customers

```DAX
Repeat Customers =
COUNTROWS(
    FILTER(
        VALUES(Sales[CustomerID]),
        CALCULATE(DISTINCTCOUNT(Sales[OrderID])) >= 2
    )
)
```

### Total Customers

```DAX
Total Customers =
DISTINCTCOUNT(Sales[CustomerID])
```

### Repeat Purchase Rate %

```DAX
Repeat Purchase Rate % =
DIVIDE([Repeat Customers], [Total Customers])
```

---

## B) Account Retention (wholesale-friendly)

Accounts that bought in current period and prior period.

### Active Accounts Current Period

```DAX
Active Accounts Current =
CALCULATE(
    DISTINCTCOUNT(Sales[AccountID]),
    Sales[UnitsSold] > 0
)
```

### Active Accounts Prior Period (example: prior month)

```DAX
Active Accounts Prior =
CALCULATE(
    DISTINCTCOUNT(Sales[AccountID]),
    DATEADD(DimDate[Date], -1, MONTH),
    Sales[UnitsSold] > 0
)
```

### Retained Accounts

```DAX
Retained Accounts =
COUNTROWS(
    INTERSECT(
        CALCULATETABLE(VALUES(Sales[AccountID]), Sales[UnitsSold] > 0),
        CALCULATETABLE(VALUES(Sales[AccountID]), DATEADD(DimDate[Date], -1, MONTH), Sales[UnitsSold] > 0)
    )
)
```

### Account Retention %

```DAX
Account Retention % =
DIVIDE([Retained Accounts], [Active Accounts Prior])
```

---

# Variance Analysis (Price / Volume / Mix decomposition)

This is the spicy one. There are many valid methods. Here’s a practical and common decomposition comparing current vs prior period.

## Period-over-period base measures

```DAX
Net Sales Prior Period =
CALCULATE(
    [Net Sales],
    DATEADD(DimDate[Date], -1, MONTH)
)
```

```DAX
Volume Prior Period =
CALCULATE(
    [Volume Units],
    DATEADD(DimDate[Date], -1, MONTH)
)
```

```DAX
Net VWAP Prior Period =
CALCULATE(
    [Net VWAP],
    DATEADD(DimDate[Date], -1, MONTH)
)
```

---

## Revenue Variance $

```DAX
Revenue Variance $ =
[Net Sales] - [Net Sales Prior Period]
```

---

## Price Effect $

Approximation: current volume × change in price

```DAX
Price Effect $ =
([Net VWAP] - [Net VWAP Prior Period]) * [Volume Prior Period]
```

## Volume Effect $

Approximation: prior price × change in volume

```DAX
Volume Effect $ =
([Volume Units] - [Volume Prior Period]) * [Net VWAP Prior Period]
```

## Mix Effect $

Residual method (very common in dashboarding)

```DAX
Mix Effect $ =
[Revenue Variance $] - [Price Effect $] - [Volume Effect $]
```

> This residual approach is practical and audit-friendly enough for many BI uses. Full mix decomposition at SKU level can be built too, but it gets heavier.

---

# Stockout Rate

This depends on inventory snapshots. Best practice: calculate from a daily inventory table.

## If `InventorySnapshots[InStockFlag]` exists (1=in stock, 0=stockout)

### In-stock Observations

```DAX
In-Stock Observations =
SUM(InventorySnapshots[InStockFlag])
```

### Total Observations

```DAX
Total Inventory Observations =
COUNTROWS(InventorySnapshots)
```

### In-Stock %

```DAX
In-Stock % =
DIVIDE([In-Stock Observations], [Total Inventory Observations])
```

### Stockout Rate %

```DAX
Stockout Rate % =
1 - [In-Stock %]
```

---

## If you only have OnHandUnits

```DAX
Stockout Observations =
COUNTROWS(
    FILTER(
        InventorySnapshots,
        InventorySnapshots[OnHandUnits] <= 0
    )
)
```

```DAX
Stockout Rate % =
DIVIDE([Stockout Observations], [Total Inventory Observations])
```

---

# “Inventory Health Metrics” (bundle examples)

You asked for this as a category, so here’s a useful mini-pack:

```DAX
Inventory Health Score (Example) =
VAR InStockScore = [In-Stock %]
VAR TurnScore =
    MIN(1, DIVIDE([Inventory Turnover (Units)], 4))   -- cap at 1 for display
VAR AgingPenalty =
    1 - COALESCE([Aged Inventory % (90+ Days)], 0)
RETURN
DIVIDE(InStockScore + TurnScore + AgingPenalty, 3)
```

That’s optional, but teams love a rolled-up health indicator.

---

# “Distribution” and “Rate of Sales” nuance (important)

In cannabis, “distribution” may also mean:

* **Numeric distribution** (% doors carrying)
* **Weighted distribution** (% category sales represented by those doors)

Weighted distribution requires external scan/category data. If you have it, I can write that DAX too.

---

# “Forecast Accuracy” nuance (important)

MAPE gets weird when actuals are tiny or zero. Two alternatives often used:

* **WAPE** (Weighted Absolute Percentage Error)
* **MAE** (Mean Absolute Error)

If you want, I can add a more robust **WAPE** measure (usually better for sales dashboards).

---

# Suggested Power BI layout for Wyld (practical)

If you build this as a portfolio dashboard, I’d split it into 5 pages:

1. **Executive Overview**

   * Net Sales, Gross Margin $, Gross Margin %, Net VWAP, Units, Discount Rate

2. **Pricing & Promo**

   * Gross VWAP vs Net VWAP, Promo Penetration, Promo Lift, Price per mg

3. **Product Mix**

   * Mix %, cannabinoid family mix, flavor mix, margin by mix segment

4. **Distribution & Inventory**

   * Active Accounts, ROS, Unit Velocity, DOH, Turnover, Stockout Rate

5. **Planning & Performance**

   * Forecast Accuracy (MAPE/WAPE), Bias, Price/Volume/Mix variance, concentration

That combo would look very legit for a Wyld-style business analyst portfolio.

---

># VWAP

```dax
// Gross VWAP
Gross VWAP =
DIVIDE(
    SUMX(
        FILTER(Sales, Sales[Brand] = "Wyld"),
        Sales[UnitPrice] * Sales[QuantitySold]
    ),
    SUMX(
        FILTER(Sales, Sales[Brand] = "Wyld"),
        Sales[QuantitySold]
    )
)


// Gross VWAP: This version is usually nicer in Power BI because it respects date/state/product slicers and only forces Brand = Wyld. Auto respect to slicers.
Gross VWAP =
CALCULATE(
    DIVIDE(
        SUMX(Sales, Sales[UnitPrice] * Sales[QuantitySold]),
        SUM(Sales[QuantitySold])
    ),
    Sales[Brand] = "Wyld"
)
```

---

```dax
// Net VWAP
Net VWAP =
DIVIDE(
    SUMX(
        FILTER(Sales, Sales[Brand] = "Wyld"),
        Sales[NetUnitPrice] * Sales[QuantitySold]
    ),
    SUMX(
        FILTER(Sales, Sales[Brand] = "Wyld"),
        Sales[QuantitySold]
    )
)

// Net VWAP: This version is usually nicer in Power BI because it respects date/state/product slicers and only forces Brand = Wyld. Auto respect to slicers.
Net VWAP =
CALCULATE(
    DIVIDE(
        SUMX(Sales, Sales[NetUnitPrice] * Sales[QuantitySold]),
        SUM(Sales[QuantitySold])
    ),
    Sales[Brand] = "Wyld"
)

// If you don’t have NetUnitPrice, you can calc it from discount columns
Net VWAP =
CALCULATE(
    DIVIDE(
        SUMX(
            Sales,
            (Sales[UnitPrice] - Sales[DiscountAmount]) * Sales[QuantitySold]
        ),
        SUM(Sales[QuantitySold])
    ),
    Sales[Brand] = "Wyld"
)
```

---
---

```dax
// VWAP Delta (Promo Impact)
VWAP Delta = [Gross VWAP] - [Net VWAP]
```

```dax
// VWAP Discount %
VWAP Discount % = DIVIDE([Gross VWAP] - [Net VWAP], [Gross VWAP])
```

---
---

Absolutely — here’s a clean DAX version for **Gross VWAP** and **Net VWAP** for Wyld products.

## Assumed columns

Let’s assume your sales table is called **`Sales`** and has:

* `Sales[Brand]`
* `Sales[UnitPrice]` (list/gross price per unit)
* `Sales[NetUnitPrice]` (actual realized price after discounts)
* `Sales[QuantitySold]`

---

## Gross VWAP (DAX)

```DAX
Gross VWAP =
DIVIDE(
    SUMX(
        FILTER(Sales, Sales[Brand] = "Wyld"),
        Sales[UnitPrice] * Sales[QuantitySold]
    ),
    SUMX(
        FILTER(Sales, Sales[Brand] = "Wyld"),
        Sales[QuantitySold]
    )
)
```

---

## Net VWAP (DAX)

```DAX
Net VWAP =
DIVIDE(
    SUMX(
        FILTER(Sales, Sales[Brand] = "Wyld"),
        Sales[NetUnitPrice] * Sales[QuantitySold]
    ),
    SUMX(
        FILTER(Sales, Sales[Brand] = "Wyld"),
        Sales[QuantitySold]
    )
)
```

---

## Better version (respects slicers automatically)

This version is usually nicer in Power BI because it respects date/state/product slicers and only forces **Brand = Wyld**.

### Gross VWAP (recommended)

```DAX
Gross VWAP =
CALCULATE(
    DIVIDE(
        SUMX(Sales, Sales[UnitPrice] * Sales[QuantitySold]),
        SUM(Sales[QuantitySold])
    ),
    Sales[Brand] = "Wyld"
)
```

### Net VWAP (recommended)

```DAX
Net VWAP =
CALCULATE(
    DIVIDE(
        SUMX(Sales, Sales[NetUnitPrice] * Sales[QuantitySold]),
        SUM(Sales[QuantitySold])
    ),
    Sales[Brand] = "Wyld"
)
```

---

## If you don’t have `NetUnitPrice`

You can calculate it from discount columns, for example:

* `Sales[UnitPrice]`
* `Sales[DiscountAmount]` (per unit)

Then net price per unit = `UnitPrice - DiscountAmount`

```DAX
Net VWAP =
CALCULATE(
    DIVIDE(
        SUMX(
            Sales,
            (Sales[UnitPrice] - Sales[DiscountAmount]) * Sales[QuantitySold]
        ),
        SUM(Sales[QuantitySold])
    ),
    Sales[Brand] = "Wyld"
)
```

---

## 💡💡 Bonus: VWAP Price Delta (promo impact)

This is a great KPI for a business analyst dashboard:

```DAX
VWAP Delta =
[Gross VWAP] - [Net VWAP]
```

And percentage impact:

```DAX
VWAP Discount % =
DIVIDE([Gross VWAP] - [Net VWAP], [Gross VWAP])
```

That gives you a fast read on how much promotions/discounts are pulling down realized price — the kind of thing finance and sales teams obsess over (for good reason).

---

## 💡💡 Next move that will make this much easier

If you paste your **actual column names** (or a screenshot of your model fields), I can rewrite all of this into a **drop-in DAX measure pack** with your exact table/column names and include a few polished KPI labels/tooltips. That saves a lot of “why is DAX mad at me” time, which is basically Power BI’s favorite hobby.
