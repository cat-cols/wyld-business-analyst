## Project 3 — “Forecasting + Variance Story” (Planning, trends, partial info)
> forecast + actuals + variance bridge

This project simulates a business planning workflow that compares forecasted sales against actual performance, explains variance drivers, and translates model output into executive-ready recommendations.

The goal is not just to forecast future sales. The goal is to explain what changed, why it changed, and what the business should do next.

## What this project demonstrates

- Weekly sales forecasting
- Actuals vs forecast comparison
- Forecast accuracy measurement
- Price / volume / mix variance decomposition
- Driver diagnostics for stores, SKUs, channels, promotions, and stockouts
- Power BI-ready mart design
- Executive storytelling for finance and commercial teams

**What it proves:** trend/pattern detection, forecasting, plugging data gaps intelligently, explaining drivers.

**Concept:** Build a forecasting + variance analysis report:

* Forecast next 8–12 weeks of sales (or demand)
* Compare actuals vs forecast/budget
* Attribute variance to drivers (price, volume, mix)

**Model choices (keep it credible, not weird):**

* Baseline: seasonal naive + moving average
* Better: Prophet / SARIMA (optional)
* Add “confidence bands” and explain them simply

**Variance decomposition (this impresses finance people):**

* Sales variance = Price effect + Volume effect + Mix effect
* Margin variance = Rate effect + Volume effect (or a simple bridge chart)

**Deliverables:**

* Power BI dashboard pages:
  * Forecast
  * Variance bridge (waterfall)
  * Driver diagnostics
* Slide deck: “What happened, why, what to do next” (the holy trinity)

---