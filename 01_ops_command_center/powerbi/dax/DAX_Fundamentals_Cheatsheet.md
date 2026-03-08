# DAX Fundamentals Cheat Sheet
**For Business Analysts | Power BI | Data Modeling**

---

## 📚 WHAT IS DAX?

**DAX (Data Analysis Expressions)** is a formula language for Power BI, Excel Power Pivot, and Analysis Services.

**Think of it as:**
- Excel formulas + SQL logic + Table relationships
- Used to create calculated columns, measures, and tables
- Optimized for aggregations and business intelligence

**Key Difference from SQL:**
- SQL operates on rows and columns
- DAX operates on tables and columns with relationships

---

## 🎯 CORE CONCEPTS

### 1. MEASURES vs. CALCULATED COLUMNS

**Measures** (most common in BI)
- Evaluated at query time
- Aggregate data
- Dynamic (change based on filters/slicers)
- More efficient
- Example: Total Sales, Average Revenue

**Calculated Columns**
- Evaluated when data refreshes
- Row-by-row calculation
- Static (stored in model)
- Use more memory
- Example: Full Name = FirstName & " " & LastName

**RULE OF THUMB:** Use measures for aggregations, calculated columns for attributes.

---

## 📐 AGGREGATION FUNCTIONS

### Basic Aggregations

```dax
// Sum
Total Revenue = SUM(Sales[Revenue])

// Average
Average Price = AVERAGE(Sales[Price])

// Count rows
Row Count = COUNTROWS(Sales)

// Count non-blank
Customer Count = COUNT(Sales[CustomerID])

// Count distinct
Unique Customers = DISTINCTCOUNT(Sales[CustomerID])

// Min/Max
Highest Sale = MAX(Sales[Amount])
Lowest Sale = MIN(Sales[Amount])
```

**Wyld Use Case:**
```dax
// Total cannabis sales
Total Sales = SUM(Sales[Revenue])

// Average order value
Avg Order Value = DIVIDE(SUM(Sales[Revenue]), COUNTROWS(Sales))

// Unique products sold
Product Count = DISTINCTCOUNT(Sales[ProductSKU])

// Gross margin
Gross Margin = 
    DIVIDE(
        SUM(Sales[Revenue]) - SUM(Sales[COGS]),
        SUM(Sales[Revenue])
    )
```

---

## 🔢 MATHEMATICAL OPERATIONS

```dax
// Division with zero handling
Margin Percent = 
    DIVIDE(
        [Gross Profit],
        [Total Revenue],
        0  // Returns 0 if denominator is zero
    )

// Absolute value
Sales Variance = ABS([Actual Sales] - [Budget])

// Rounding
Rounded Revenue = ROUND([Total Revenue], 2)

// Percentage
Growth Rate = 
    DIVIDE(
        [Current Year Sales] - [Prior Year Sales],
        [Prior Year Sales]
    )
```

---

## 🎭 CONTEXT: Filter vs. Row Context

**CRITICAL CONCEPT:** DAX calculations depend on context.

### Filter Context
- Determined by slicers, filters, rows/columns in visuals
- Affects which data is included in calculation
- Example: Selecting "Oregon" filters all measures to Oregon data

### Row Context
- Iterates row-by-row (like a loop)
- Used in calculated columns and iterator functions
- Example: Calculating profit for each transaction

**Example:**
```dax
// Measure (Filter Context) - changes based on slicers
Total Sales = SUM(Sales[Amount])  // Respects filters

// Calculated Column (Row Context) - per row
Profit = Sales[Revenue] - Sales[Cost]  // Calculated once per row
```

---

## 🔍 THE CALCULATE FUNCTION

**CALCULATE** is the MOST IMPORTANT DAX function. It modifies filter context.

**Syntax:**
```dax
CALCULATE(
    <expression>,
    <filter1>,
    <filter2>,
    ...
)
```

### Examples:

```dax
// Sales for a specific state
Oregon Sales = 
    CALCULATE(
        SUM(Sales[Revenue]),
        Sales[State] = "OR"
    )

// Sales for multiple states
West Coast Sales = 
    CALCULATE(
        SUM(Sales[Revenue]),
        Sales[State] IN {"OR", "WA", "CA"}
    )

// Remove all filters
All States Sales = 
    CALCULATE(
        SUM(Sales[Revenue]),
        ALL(Sales[State])
    )

// Multiple conditions
Q4 High Value Sales = 
    CALCULATE(
        SUM(Sales[Revenue]),
        Sales[Quarter] = 4,
        Sales[OrderValue] > 1000
    )
```

**Wyld Use Cases:**
```dax
// Gummies revenue only
Gummies Revenue = 
    CALCULATE(
        SUM(Sales[Revenue]),
        Products[Category] = "Gummies"
    )

// THC products (exclude CBD)
THC Sales = 
    CALCULATE(
        SUM(Sales[Revenue]),
        Products[ProductType] = "THC"
    )

// Revenue in legal recreational states
Rec Sales = 
    CALCULATE(
        SUM(Sales[Revenue]),
        States[LegalStatus] = "Recreational"
    )
```

---

## 📅 TIME INTELLIGENCE

Power BI has built-in time intelligence functions (requires proper date table).

### Common Time Functions:

```dax
// Year-to-date
YTD Sales = TOTALYTD(SUM(Sales[Revenue]), Calendar[Date])

// Month-to-date
MTD Sales = TOTALMTD(SUM(Sales[Revenue]), Calendar[Date])

// Quarter-to-date
QTD Sales = TOTALQTD(SUM(Sales[Revenue]), Calendar[Date])

// Previous year
Sales Last Year = 
    CALCULATE(
        SUM(Sales[Revenue]),
        SAMEPERIODLASTYEAR(Calendar[Date])
    )

// Year-over-year growth
YoY Growth = 
    DIVIDE(
        [Total Sales] - [Sales Last Year],
        [Sales Last Year]
    )

// Previous month
Prior Month Sales = 
    CALCULATE(
        SUM(Sales[Revenue]),
        DATEADD(Calendar[Date], -1, MONTH)
    )

// Rolling 12 months
Rolling 12M Sales = 
    CALCULATE(
        SUM(Sales[Revenue]),
        DATESINPERIOD(
            Calendar[Date],
            MAX(Calendar[Date]),
            -12,
            MONTH
        )
    )
```

**Wyld Use Case:**
```dax
// Compare this month vs. last month
Sales vs Prior Month = 
    [Total Sales] - 
    CALCULATE(
        [Total Sales],
        DATEADD(Calendar[Date], -1, MONTH)
    )

// YTD vs Last YTD
YTD Growth = 
    DIVIDE(
        [YTD Sales] - 
        CALCULATE([YTD Sales], SAMEPERIODLASTYEAR(Calendar[Date])),
        CALCULATE([YTD Sales], SAMEPERIODLASTYEAR(Calendar[Date]))
    )
```

---

## 🔄 FILTER FUNCTIONS

### ALL - Remove filters

```dax
// Total sales ignoring any state filter
All States Total = 
    CALCULATE(
        SUM(Sales[Revenue]),
        ALL(Sales[State])
    )

// Percentage of total
Pct of Total = 
    DIVIDE(
        SUM(Sales[Revenue]),
        CALCULATE(SUM(Sales[Revenue]), ALL(Sales))
    )
```

### FILTER - Apply complex conditions

```dax
// Sales for products over $50
Premium Products Sales = 
    CALCULATE(
        SUM(Sales[Revenue]),
        FILTER(
            Products,
            Products[Price] > 50
        )
    )

// High-margin products
High Margin Sales = 
    CALCULATE(
        SUM(Sales[Revenue]),
        FILTER(
            ALL(Products),
            Products[Margin] > 0.6
        )
    )
```

### ALLEXCEPT - Remove all filters except specified

```dax
// Sales total by category, ignoring all other filters
Category Total = 
    CALCULATE(
        SUM(Sales[Revenue]),
        ALLEXCEPT(Products, Products[Category])
    )
```

---

## 🎲 CONDITIONAL LOGIC

### IF Statements

```dax
// Simple IF
Profitability = 
    IF(
        [Gross Margin] > 0.5,
        "Profitable",
        "Unprofitable"
    )

// Nested IF
Performance Tier = 
    IF(
        [Total Sales] > 100000, "Tier 1",
        IF([Total Sales] > 50000, "Tier 2",
        IF([Total Sales] > 25000, "Tier 3",
        "Tier 4"
        ))
    )
```

### SWITCH (better than nested IFs)

```dax
// Product categorization
Product Tier = 
    SWITCH(
        Products[Category],
        "Gummies", "Core",
        "Beverages", "Growth",
        "CBD", "Specialty",
        "Other"
    )

// Quarter-based bonus
Bonus Multiplier = 
    SWITCH(
        TRUE(),
        [Total Sales] > 1000000, 1.5,
        [Total Sales] > 500000, 1.25,
        [Total Sales] > 250000, 1.1,
        1.0
    )
```

**Wyld Use Case:**
```dax
// Product classification
Product Type = 
    SWITCH(
        Products[THC_mg],
        0, "CBD Only",
        10, "Micro-dose",
        50, "Moderate",
        100, "Full Dose",
        "Unknown"
    )

// State regulatory status
Compliance Status = 
    SWITCH(
        Sales[State],
        "OR", "Recreational",
        "WA", "Recreational", 
        "CA", "Recreational",
        "Medical"
    )
```

---

## 🔢 RANKING & SORTING

```dax
// Rank products by revenue
Product Rank = 
    RANKX(
        ALL(Products[ProductName]),
        [Total Revenue],
        ,
        DESC  // Descending (highest = 1)
    )

// Top N filter
Top 10 Products = 
    IF(
        [Product Rank] <= 10,
        [Total Revenue],
        BLANK()
    )

// Percentile rank
Sales Percentile = 
    PERCENTILE.INC(ALL(Sales[Amount]), [Total Sales])
```

---

## 🔗 RELATIONSHIP FUNCTIONS

```dax
// Access related table
Category Sales = 
    RELATED(Categories[CategoryName])

// Sum related rows
Total Orders = 
    RELATEDTABLE(Orders)

// Use specific relationship (if multiple exist)
Budget Variance = 
    USERELATIONSHIP(Sales[Date], Budget[BudgetDate])
```

---

## 📊 ITERATOR FUNCTIONS (X functions)

Iterate row-by-row and aggregate.

```dax
// Sum of products (quantity × price)
Total Revenue = 
    SUMX(
        Sales,
        Sales[Quantity] * Sales[UnitPrice]
    )

// Average margin per product
Avg Product Margin = 
    AVERAGEX(
        Products,
        DIVIDE(
            Products[Price] - Products[Cost],
            Products[Price]
        )
    )

// Count products above threshold
Premium Count = 
    COUNTX(
        FILTER(Products, Products[Price] > 100),
        Products[ProductID]
    )

// Weighted average
Weighted Avg Price = 
    DIVIDE(
        SUMX(Sales, Sales[Quantity] * Sales[Price]),
        SUM(Sales[Quantity])
    )
```

**Wyld Use Case:**
```dax
// Net revenue (after discounts)
Net Revenue = 
    SUMX(
        Sales,
        Sales[Quantity] * Sales[UnitPrice] * (1 - Sales[DiscountPct])
    )

// Average THC per transaction
Avg THC per Order = 
    AVERAGEX(
        Sales,
        RELATED(Products[THC_mg]) * Sales[Quantity]
    )
```

---

## ⚠️ COMMON DAX MISTAKES TO AVOID

### 1. Using SUM instead of SUMX when row-level calc needed
```dax
// ❌ WRONG - won't work
Total = SUM(Sales[Qty] * Sales[Price])

// ✅ CORRECT
Total = SUMX(Sales, Sales[Qty] * Sales[Price])
```

### 2. Not handling division by zero
```dax
// ❌ WRONG - can error
Margin = [Profit] / [Revenue]

// ✅ CORRECT
Margin = DIVIDE([Profit], [Revenue], 0)
```

### 3. Using calculated columns when measures are better
```dax
// ❌ WRONG - calculated column (static, uses memory)
Sales Amount = Sales[Qty] * Sales[Price]

// ✅ CORRECT - measure (dynamic, efficient)
Sales Amount = SUMX(Sales, Sales[Qty] * Sales[Price])
```

### 4. Not understanding context
```dax
// ❌ Likely WRONG - doesn't respect filters properly
Total = SUM(Sales[Amount])  // In calculated column

// ✅ CORRECT - use CALCULATE to set context
Total = CALCULATE(SUM(Sales[Amount]), ALL(Sales))
```

---

## 💡 DAX vs. SQL: KEY DIFFERENCES

| Concept | SQL | DAX |
|---------|-----|-----|
| **Operation** | Row-based | Table-based |
| **Aggregation** | GROUP BY | Automatic by context |
| **Filtering** | WHERE | CALCULATE, FILTER |
| **Joins** | JOIN | Relationships (auto) |
| **Window Functions** | OVER (PARTITION BY) | CALCULATE with context |
| **Subqueries** | Nested SELECT | CALCULATETABLE, FILTER |
| **Performance** | Query-time optimization | Pre-aggregated model |

---

## 🎯 WYLD INTERVIEW SCENARIOS

### Q: "Calculate gross margin by product category"

**DAX Answer:**
```dax
Category Margin = 
    DIVIDE(
        SUMX(
            FILTER(
                Sales,
                RELATED(Products[Category]) = "Gummies"
            ),
            Sales[Revenue] - Sales[COGS]
        ),
        SUMX(
            FILTER(
                Sales,
                RELATED(Products[Category]) = "Gummies"
            ),
            Sales[Revenue]
        )
    )
```

**Better Version:**
```dax
Gross Margin = 
    DIVIDE(
        SUM(Sales[Revenue]) - SUM(Sales[COGS]),
        SUM(Sales[Revenue])
    )
// Then slice by Category in visual
```

### Q: "Compare current month to same month last year"

```dax
Sales SPLY = 
    CALCULATE(
        [Total Sales],
        SAMEPERIODLASTYEAR(Calendar[Date])
    )

Sales Growth = [Total Sales] - [Sales SPLY]

Growth % = DIVIDE([Sales Growth], [Sales SPLY])
```

### Q: "Show only states with over $1M revenue"

```dax
Million Dollar States = 
    IF(
        [Total Sales] > 1000000,
        [Total Sales],
        BLANK()
    )
```

---

## 📚 STUDY STRATEGY FOR WYLD INTERVIEW

**Days 1-2: Understand these core concepts**
1. Measures vs. Calculated Columns
2. Filter Context
3. CALCULATE function
4. Basic aggregations (SUM, AVERAGE, COUNT)

**Days 3-4: Practice mental "translation"**
- Take Tableau calculations you've built
- Translate them to DAX syntax in your head
- Example: "If I needed to do this in Power BI, I'd use..."

**Day 5: Cannabis-specific scenarios**
- How would you calculate margin by product category?
- How would you track inventory turnover?
- How would you compare state performance?
- How would you measure YoY growth by SKU?

**Interview Strategy:**
When asked about Power BI/DAX:
> "I haven't used Power BI extensively, but I understand DAX logic translates 
> directly from my Tableau and SQL experience. For instance, CALCULATE in DAX 
> is conceptually similar to LOD expressions in Tableau and filtered aggregations 
> in SQL. I've studied DAX patterns specifically for this role and am confident 
> I can get up to speed quickly since the analytical thinking is identical."

---

## 🔗 QUICK REFERENCE

**Most Common DAX Functions (80% of use cases):**
- SUM, AVERAGE, COUNT, DISTINCTCOUNT
- CALCULATE
- DIVIDE
- IF, SWITCH
- SUMX, AVERAGEX
- FILTER, ALL, ALLEXCEPT
- Time intelligence: TOTALYTD, SAMEPERIODLASTYEAR

**Golden Rule:**
> Use CALCULATE when you need to modify filters.  
> Use X functions (SUMX, AVERAGEX) when you need row-by-row operations.  
> Use DIVIDE to avoid /0 errors.

---

**Created by:** Brandon Hardison  
**Purpose:** Interview preparation for Wyld Business Analyst role  
**Last Updated:** February 2026

---

*This cheat sheet demonstrates understanding of Power BI/DAX concepts even 
without hands-on Power BI experience. The logic translates directly from 
Tableau (LOD expressions) and SQL (window functions, CTEs).*
