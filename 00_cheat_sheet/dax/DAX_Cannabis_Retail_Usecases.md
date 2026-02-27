# Cannabis Retail Analytics - DAX Use Cases
**Business Analyst Interview Prep | Wyld-Specific Scenarios**

---

## 🌿 CANNABIS INDUSTRY CONTEXT

Cannabis retail has unique analytical needs:
- Multi-state operations with different regulations
- Product categories (flower, edibles, concentrates, beverages)
- Compliance tracking (inventory, sales limits, taxes)
- High-margin products with volume constraints
- Rapid market changes and new product launches
- Seasonal patterns and consumption trends

---

### Volume Metrics

```dax
Volume Units =
SUM(Sales[UnitsSold])
```

```dax
Gross Sales =
SUMX(
    Sales,
    Sales[GrossUnitPrice] * Sales[UnitsSold]
)
```

```dax
Net Sales =
SUMX(
    Sales,
    Sales[NetUnitPrice] * Sales[UnitsSold]
)
```

```dax
// COGS: Cost of Goods Sold (Gross Sales - Net Sales)
COGS $ =
SUM(Sales[COGSAmount])
```

```dax
// Gross Profit: Gross Sales - COGS
Gross Profit = [Gross Sales] - [COGS $]
```

```dax
// Gross Margin $: Gross Sales - COGS
Gross Margin $ = [Net Sales] - [COGS $]
```

```dax
// Gross Margin %: Gross Profit / Gross Sales
Gross Margin % = DIVIDE([Gross Profit], [Gross Sales])
```

```dax
// Gross Margin %: Gross Profit / Net Sales
Gross Margin % = DIVIDE([Gross Profit], [Net Sales])
```

```dax
// Discount $:
Discount $ = [Gross Sales] - [Net Sales]
```

```dax
// Discount Rate (%):
Discount Rate % = DIVIDE([Discount $], [Gross Sales])
```

---

## 📊 WYLD-SPECIFIC DAX MEASURES

### Revenue & Sales Metrics

```dax
// Total Revenue
Total Revenue = SUM(Sales[Revenue])

// Revenue by Product Category
Gummies Revenue =
    CALCULATE(
        [Total Revenue],
        Products[Category] = "Gummies"
    )

Beverages Revenue =
    CALCULATE(
        [Total Revenue],
        Products[Category] = "Beverages"
    )

// Revenue by Subcategory (THC vs CBD vs CBN)
THC Revenue =
    CALCULATE(
        [Total Revenue],
        Products[Subcategory] = "THC"
    )

CBD Revenue =
    CALCULATE(
        [Total Revenue],
        Products[Subcategory] = "CBD"
    )

// Average Order Value
AOV = DIVIDE([Total Revenue], DISTINCTCOUNT(Sales[TransactionID]))

// Units Sold
Total Units = SUM(Sales[Units])

// Revenue per Unit
Revenue per Unit = DIVIDE([Total Revenue], [Total Units])
```

---

### Profitability Metrics

```dax
// Cost of Goods Sold
Total COGS = SUM(Sales[COGS])

// Gross Profit
Gross Profit = [Total Revenue] - [Total COGS]

// Gross Margin %
Gross Margin % =
    DIVIDE([Gross Profit], [Total Revenue])

// Gross Margin by Category
Category Margin =
    DIVIDE(
        CALCULATE([Gross Profit], Products[Category] = "Gummies"),
        CALCULATE([Total Revenue], Products[Category] = "Gummies")
    )

// Contribution Margin (Revenue - Variable Costs)
Contribution Margin =
    [Total Revenue] - SUM(Sales[VariableCosts])

// Margin $ per Unit
Margin per Unit = DIVIDE([Gross Profit], [Total Units])

// Product-level profitability
Product ROI =
    DIVIDE(
        [Gross Profit],
        [Total COGS]
    )
```

---

### Geographic Analysis

```dax
// State-level revenue
State Revenue =
    CALCULATE(
        [Total Revenue],
        Sales[State] = "OR"  // Dynamic based on slicer
    )

// Multi-state total (West Coast example)
West Coast Revenue =
    CALCULATE(
        [Total Revenue],
        Sales[State] IN {"OR", "WA", "CA"}
    )

// Revenue by Legal Status
Recreational Revenue =
    CALCULATE(
        [Total Revenue],
        States[LegalStatus] = "Recreational"
    )

Medical Revenue =
    CALCULATE(
        [Total Revenue],
        States[LegalStatus] = "Medical"
    )

// State Rank
State Rank =
    RANKX(
        ALL(Sales[State]),
        [Total Revenue],
        ,
        DESC
    )

// Percentage of Total Revenue by State
State Revenue % =
    DIVIDE(
        [Total Revenue],
        CALCULATE([Total Revenue], ALL(Sales[State]))
    )

// Average Revenue per State
Avg State Revenue =
    AVERAGEX(
        VALUES(Sales[State]),
        [Total Revenue]
    )
```

---

### Product Performance

```dax
// Product Rank
Product Rank =
    RANKX(
        ALL(Products[ProductName]),
        [Total Revenue],
        ,
        DESC
    )

// Top 10 Products Filter
Is Top 10 = IF([Product Rank] <= 10, 1, 0)

// SKU Performance
SKU Revenue =
    CALCULATE(
        [Total Revenue],
        Products[SKU] = "WYLD-RASP-10"
    )

// New Product Performance (launched in last 12 months)
New Product Revenue =
    CALCULATE(
        [Total Revenue],
        Products[LaunchDate] >= DATE(2024, 1, 1)
    )

// Product Mix (% of total units by category)
Product Mix % =
    DIVIDE(
        [Total Units],
        CALCULATE([Total Units], ALL(Products[Category]))
    )

// Cross-category analysis
Gummies vs Beverages =
    DIVIDE(
        CALCULATE([Total Revenue], Products[Category] = "Gummies"),
        CALCULATE([Total Revenue], Products[Category] = "Beverages")
    )

// Average price point
Avg Product Price =
    AVERAGEX(
        Sales,
        RELATED(Products[UnitPrice])
    )

// Price tier analysis
Premium Products Revenue =
    CALCULATE(
        [Total Revenue],
        FILTER(
            Products,
            Products[UnitPrice] > 25
        )
    )
```

---

### Time-Based Analysis

```dax
// Year-to-Date Sales
YTD Sales =
    TOTALYTD([Total Revenue], Calendar[Date])

// Same Period Last Year
Sales SPLY =
    CALCULATE(
        [Total Revenue],
        SAMEPERIODLASTYEAR(Calendar[Date])
    )

// Year-over-Year Growth
YoY Growth =
    DIVIDE(
        [Total Revenue] - [Sales SPLY],
        [Sales SPLY]
    )

// YoY Growth %
YoY Growth % =
    DIVIDE(
        [Total Revenue] - [Sales SPLY],
        [Sales SPLY]
    )

// Month-over-Month Growth
MoM Growth =
    VAR CurrentMonth = [Total Revenue]
    VAR PriorMonth = 
        CALCULATE(
            [Total Revenue],
            DATEADD(Calendar[Date], -1, MONTH)
        )
    RETURN
        DIVIDE(CurrentMonth - PriorMonth, PriorMonth)

// Rolling 3-Month Average
3M Avg Revenue =
    CALCULATE(
        [Total Revenue],
        DATESINPERIOD(
            Calendar[Date],
            LASTDATE(Calendar[Date]),
            -3,
            MONTH
        )
    ) / 3

// Quarter-to-Date
QTD Sales =
    TOTALQTD([Total Revenue], Calendar[Date])

// Seasonal Index
Seasonal Index =
    DIVIDE(
        [Total Revenue],
        CALCULATE(
            AVERAGE([Total Revenue]),
            ALL(Calendar[Month])
        )
    )

// Peak Season Revenue (Summer: Jun-Aug)
Summer Revenue =
    CALCULATE(
        [Total Revenue],
        Calendar[Month] IN {6, 7, 8}
    )
```

---

### Inventory & Operations

```dax
// Inventory Turnover
Inventory Turnover =
    DIVIDE(
        [Total COGS],
        AVERAGE(Inventory[OnHandValue])
    )

// Days of Inventory
Days of Inventory =
    DIVIDE(
        365,
        [Inventory Turnover]
    )

// Sell-through Rate
Sell-through Rate =
    DIVIDE(
        [Total Units],
        SUM(Inventory[UnitsReceived])
    )

// Out-of-stock Products
OOS Products =
    CALCULATE(
        DISTINCTCOUNT(Products[SKU]),
        Inventory[UnitsOnHand] = 0
    )

// Average Order Fulfillment Time
Avg Fulfillment Days =
    AVERAGEX(
        Sales,
        Sales[ShipDate] - Sales[OrderDate]
    )

// Perfect Order Rate (on-time, complete, damage-free)
Perfect Order Rate =
    DIVIDE(
        COUNTROWS(FILTER(Sales, Sales[PerfectOrder] = TRUE)),
        COUNTROWS(Sales)
    )
```

---

### Customer Analytics

```dax
// Unique Customers
Customer Count = DISTINCTCOUNT(Sales[CustomerID])

// New Customers
New Customers =
    CALCULATE(
        DISTINCTCOUNT(Sales[CustomerID]),
        FILTER(
            ALL(Sales),
            Sales[Date] = CALCULATE(MIN(Sales[Date]), ALL(Sales[Date]))
        )
    )

// Repeat Customer Rate
Repeat Rate =
    VAR TotalCustomers = [Customer Count]
    VAR RepeatCustomers =
        CALCULATE(
            DISTINCTCOUNT(Sales[CustomerID]),
            FILTER(
                VALUES(Sales[CustomerID]),
                COUNTROWS(FILTER(Sales, Sales[CustomerID] = EARLIER(Sales[CustomerID]))) > 1
            )
        )
    RETURN
        DIVIDE(RepeatCustomers, TotalCustomers)

// Average Customer Value
Customer LTV =
    DIVIDE(
        [Total Revenue],
        [Customer Count]
    )

// Orders per Customer
Avg Orders per Customer =
    DIVIDE(
        DISTINCTCOUNT(Sales[TransactionID]),
        [Customer Count]
    )
```

---

### Compliance & Regulatory

```dax
// Cannabis-specific compliance metrics

// Average THC per Transaction
Avg THC per Order =
    AVERAGEX(
        Sales,
        RELATED(Products[THC_mg]) * Sales[Units]
    )

// Sales Tax Collected
Sales Tax Total =
    SUMX(
        Sales,
        Sales[Revenue] * RELATED(States[TaxRate])
    )

// Excise Tax (cannabis-specific)
Excise Tax =
    SUMX(
        Sales,
        Sales[Revenue] * RELATED(States[ExciseTaxRate])
    )

// Compliance Rate (% of orders within legal limits)
Compliance Rate =
    DIVIDE(
        COUNTROWS(FILTER(Sales, Sales[WithinLegalLimit] = TRUE)),
        COUNTROWS(Sales)
    )

// Metrc Reporting Total (seed-to-sale tracking)
Metrc Units Reported =
    SUMX(
        Sales,
        IF(RELATED(States[RequiresMetrc]) = TRUE, Sales[Units], 0)
    )
```

---

### Advanced Scenarios

```dax
// Product Cannibalization Analysis
// (Did new beverages steal sales from gummies?)

Gummies Revenue Loss =
    VAR GummiesThisYear =
        CALCULATE(
            [Total Revenue],
            Products[Category] = "Gummies",
            Calendar[Year] = 2024
        )
    VAR GummiesLastYear =
        CALCULATE(
            [Total Revenue],
            Products[Category] = "Gummies",
            Calendar[Year] = 2023
        )
    VAR BeveragesThisYear =
        CALCULATE(
            [Total Revenue],
            Products[Category] = "Beverages",
            Calendar[Year] = 2024
        )
    RETURN
        IF(
            AND(GummiesThisYear < GummiesLastYear, BeveragesThisYear > 0),
            GummiesLastYear - GummiesThisYear,
            0
        )

// Market Share by State (if competitor data available)
Wyld Market Share =
    DIVIDE(
        [Total Revenue],
        [Total Revenue] + [Competitor Revenue]
    )

// Product Launch Success Metric
// (Revenue in first 90 days vs. forecast)

Launch Success =
    VAR LaunchRevenue =
        CALCULATE(
            [Total Revenue],
            DATESINPERIOD(
                Calendar[Date],
                RELATED(Products[LaunchDate]),
                90,
                DAY
            )
        )
    VAR LaunchForecast = RELATED(Products[LaunchForecast90d])
    RETURN
        DIVIDE(LaunchRevenue, LaunchForecast)

// Customer Cohort Analysis
// (Revenue from customers acquired in a specific period)

2024 Cohort Revenue =
    CALCULATE(
        [Total Revenue],
        FILTER(
            Sales,
            RELATED(Customers[FirstPurchaseDate]) >= DATE(2024, 1, 1)
            && RELATED(Customers[FirstPurchaseDate]) < DATE(2025, 1, 1)
        )
    )

// Promotion Effectiveness
Promo Lift =
    VAR PromoRevenue =
        CALCULATE(
            [Total Revenue],
            Sales[HasPromotion] = TRUE
        )
    VAR BaselineRevenue =
        CALCULATE(
            [Total Revenue],
            Sales[HasPromotion] = FALSE
        )
    VAR PromoUnits =
        CALCULATE(
            [Total Units],
            Sales[HasPromotion] = TRUE
        )
    VAR BaselineUnits =
        CALCULATE(
            [Total Units],
            Sales[HasPromotion] = FALSE
        )
    RETURN
        DIVIDE(PromoRevenue / PromoUnits, BaselineRevenue / BaselineUnits) - 1
```

---

## 🎯 WYLD INTERVIEW SCENARIOS

### Scenario 1: State Performance Comparison

**Q:** "Show me which states are performing above the company average."

```dax
Above Avg States =
    VAR CompanyAvg =
        CALCULATE(
            [Total Revenue],
            ALL(Sales[State])
        ) / DISTINCTCOUNT(ALL(Sales[State]))
    VAR StateRevenue = [Total Revenue]
    RETURN
        IF(StateRevenue > CompanyAvg, StateRevenue, BLANK())
```

---

### Scenario 2: Product Category Shift

**Q:** "Compare category mix this year vs. last year."

```dax
Category Mix Change =
    VAR CurrentMix =
        DIVIDE(
            [Total Revenue],
            CALCULATE([Total Revenue], ALL(Products[Category]))
        )
    VAR PriorMix =
        CALCULATE(
            DIVIDE(
                [Total Revenue],
                CALCULATE([Total Revenue], ALL(Products[Category]))
            ),
            SAMEPERIODLASTYEAR(Calendar[Date])
        )
    RETURN
        CurrentMix - PriorMix
```

---

### Scenario 3: New Product Ramp

**Q:** "Track revenue trajectory for products launched in last 6 months."

```dax
New Product Revenue =
    CALCULATE(
        [Total Revenue],
        FILTER(
            Products,
            Products[LaunchDate] >= EDATE(TODAY(), -6)
            && Products[LaunchDate] <= TODAY()
        )
    )

New Product Week-by-Week =
    VAR LaunchDate = MIN(Products[LaunchDate])
    VAR WeeksSinceLaunch =
        DATEDIFF(LaunchDate, TODAY(), WEEK)
    RETURN
        CALCULATE(
            [Total Revenue],
            FILTER(
                ALL(Calendar),
                Calendar[Date] >= LaunchDate
                && Calendar[Date] <= EDATE(LaunchDate, WeeksSinceLaunch * 7)
            )
        )
```

---

### Scenario 4: Margin Optimization

**Q:** "Which products have margin below 50% and represent >5% of volume?"

```dax
Low Margin High Volume =
    VAR ProductMargin = [Gross Margin %]
    VAR ProductVolume =
        DIVIDE(
            [Total Units],
            CALCULATE([Total Units], ALL(Products))
        )
    RETURN
        IF(
            AND(ProductMargin < 0.5, ProductVolume > 0.05),
            [Total Revenue],
            BLANK()
        )
```

---

### Scenario 5: Growth Driver Analysis

**Q:** "Break down revenue growth into price vs. volume components."

```dax
Price Effect =
    VAR CurrentAvgPrice = DIVIDE([Total Revenue], [Total Units])
    VAR PriorAvgPrice =
        CALCULATE(
            DIVIDE([Total Revenue], [Total Units]),
            SAMEPERIODLASTYEAR(Calendar[Date])
        )
    VAR PriorUnits =
        CALCULATE(
            [Total Units],
            SAMEPERIODLASTYEAR(Calendar[Date])
        )
    RETURN
        (CurrentAvgPrice - PriorAvgPrice) * PriorUnits

Volume Effect =
    VAR CurrentUnits = [Total Units]
    VAR PriorUnits =
        CALCULATE(
            [Total Units],
            SAMEPERIODLASTYEAR(Calendar[Date])
        )
    VAR PriorAvgPrice =
        CALCULATE(
            DIVIDE([Total Revenue], [Total Units]),
            SAMEPERIODLASTYEAR(Calendar[Date])
        )
    RETURN
        (CurrentUnits - PriorUnits) * PriorAvgPrice

Total Revenue Change = [Price Effect] + [Volume Effect]
```


---

### Rate of Sale (ROS)
```dax
// Rate of Sale (ROS)
Rate of Sale (ROS) = [Total Units] / [Total Transactions]
```

---

**Created by:** Brandon Hardison
**Purpose:** Wyld Business Analyst interview preparation
**Focus:** Cannabis retail analytics with DAX
**Last Updated:** February 2026

