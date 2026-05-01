# KPI Driver Tree — Decision Engine

## Purpose

This document defines the metric hierarchy used by the Decision Engine.

Earlier projects create trusted facts, KPIs, reconciliation controls, and reporting-ready marts. This project uses those trusted outputs to help leadership understand:

- What changed?
- Why did it change?
- Where is the issue concentrated?
- What action should we take?

The KPI driver tree acts as the blueprint for root-cause views, alert tables, opportunity tables, and executive summaries.

---

# 1. Revenue Driver Tree

## Primary KPI

**Net Sales**

## Business question

Are we growing or declining, and what is driving the change?

## Core drivers

| Driver | Meaning | Example Decision |
|---|---|---|
| Units Sold | Volume movement | Increase distribution, adjust inventory, investigate demand drop |
| Average Net Price | Price after discounts | Review pricing or promo strategy |
| Discount Rate | Promo / price pressure | Reduce discount depth or check promo ROI |
| Channel Mix | Sales shifting across retail, wholesale, distributor | Rebalance channel strategy |
| Store / Account Mix | Sales shifting across stores/accounts | Focus field team support |
| SKU Mix | Sales shifting across products | Prioritize high-growth or high-margin SKUs |

## Root-cause examples

- Revenue decline caused by unit volume drop
- Revenue decline caused by higher discounting
- Revenue growth concentrated in low-margin SKUs
- Revenue growth limited by inventory availability
- Revenue decline concentrated in specific stores, states, or channels

---

# 2. Margin Driver Tree

## Primary KPI

**Gross Margin %**

## Business question

Are we making profitable sales, or are revenue gains coming at the cost of margin?

## Core drivers

| Driver | Meaning | Example Decision |
|---|---|---|
| Net Sales | Revenue base | Grow sales where margin is healthy |
| COGS | Cost of goods sold | Investigate cost increase or product margin erosion |
| Discount Amount | Promo pressure | Review discounting strategy |
| Average Net Price | Realized selling price | Adjust price floor or promo rules |
| SKU Mix | Margin changes due to product mix | Promote higher-margin SKUs |
| Channel Mix | Margin changes due to sales channel | Review wholesale/distributor economics |

## Root-cause examples

- Margin fell because discounting increased
- Margin fell because COGS increased
- Margin improved because mix shifted to higher-margin SKUs
- Revenue increased but margin declined because growth came from low-margin products

---

# 3. Inventory Health Driver Tree

## Primary KPIs

**In-Stock Rate**  
**Days of Supply**

## Business question

Can we fulfill demand without overstocking or understocking?

## Core drivers

| Driver | Meaning | Example Decision |
|---|---|---|
| On-Hand Units | Available inventory position | Replenish or reduce stock |
| Units Sold | Demand velocity | Increase supply for fast movers |
| Backordered Units | Demand not fulfilled | Prioritize replenishment |
| Shipments | Supply movement | Investigate fulfillment gaps |
| SKU Distribution Status | Whether SKU is carried | Expand or clean assortment |
| Days of Supply | Inventory coverage | Prevent stockouts or excess inventory |

## Root-cause examples

- High-growth SKU has low days of supply
- Strong store sales limited by low inventory
- Backorders concentrated in specific states or SKUs
- Inventory is healthy but sales are weak, suggesting demand issue rather than supply issue

---

# 4. Labor Efficiency Driver Tree

## Primary KPI

**Sales per Labor Hour**

## Business question

Are labor hours aligned with sales activity?

## Core drivers

| Driver | Meaning | Example Decision |
|---|---|---|
| Net Sales | Output generated | Compare labor to business volume |
| Labor Hours | Time worked | Review staffing levels |
| Labor Cost | Cost of labor | Monitor labor cost pressure |
| OT Hours | Overtime pressure | Reduce overtime or rebalance staffing |
| Employee Count | Staffing level | Compare headcount to store activity |
| Store Mix | Labor efficiency by location | Investigate underperforming locations |

## Root-cause examples

- Sales declined but labor hours stayed flat
- Store has high labor cost but low revenue
- Sales growth outpaced labor hours, suggesting strong productivity
- Overtime is rising without matching sales growth

---

# 5. Decision Output Mapping

| Business Question | Decision Output |
|---|---|
| Which metrics changed? | `mart.decision_revenue_variance_root_cause` |
| Why did revenue change? | `mart.decision_revenue_variance_root_cause` |
| Where is margin unhealthy? | `mart.alerts_low_margin` |
| Where is inventory creating risk? | `mart.alerts_inventory_risk` |
| Which SKUs deserve more focus? | `mart.opportunity_high_growth_skus` |
| Which stores need attention? | `mart.store_performance_flags` |
| What should leadership do? | `mart.executive_decision_summary` |

---

# 6. Decision Engine Rule

Every output in Project 5 must answer at least one of these:

1. What happened?
2. Why did it happen?
3. Where is it concentrated?
4. What should we do next?

If a table does not answer one of those questions, it does not belong in the Decision Engine.