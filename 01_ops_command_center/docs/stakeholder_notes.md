# Stakeholder Notes — Project 1

These notes are meant to help a reviewer, hiring manager, or business user interpret the first version of the Ops Command Center without stepping on the semantic rakes.

## KPI Interpretation Notes

### Sales
- **Net Sales** is the primary revenue metric for most reporting views.
- **Gross Sales** is useful for discount analysis, but should not be mistaken for realized revenue.
- **Distributor sales** and **POS sales** are related but not interchangeable. The comparison is valuable, but exact equality is not always expected.

### Profitability
- **Gross Margin $** and **Gross Margin %** are modeled from synthetic pricing and COGS logic.
- Finance-style actuals currently exist mainly as a reconciliation reference, not as a perfectly aligned accounting truth layer.

### Labor / productivity
- **Sales per Labor Hour** is one of the strongest cross-functional KPIs in the project.
- A low productivity reading should be interpreted alongside staffing mix, labor hours, and store / day context rather than as a standalone verdict.

### Inventory
- **In-Stock Rate** is a daily inventory-health indicator.
- **Days of Supply** is best used directionally; extreme highs or lows should be interpreted with snapshot timing and recent shipments in mind.

## Control / Trust Notes
- Freshness failures can be expected in a static simulated dataset and do not always indicate a broken model.
- Missing-dimension-join controls are more serious because they indicate facts that cannot fully participate in the semantic model.
- Finance reconciliation failures are currently a known simulation limitation and should be called out openly.

## Threshold / Review Guidance
- Exact INT-to-MART reconciliations should normally be **0 variance**.
- Finance-style sales-to-GL comparisons can be allowed a small tolerance, but repeated unexplained variance should still be investigated.
- Any KPI that depends on incomplete joins or stale source data should carry a caution note in reporting.

## Recommended Narrative Framing
When presenting the project, describe it as:
> a cross-functional analytics build that emphasizes standardization, trust controls, and explainable KPI logic rather than only visual output.

That tells the truth and also avoids the cursed portfolio trap where the dashboard looks shiny but nobody can tell whether the numbers are nonsense.
