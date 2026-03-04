## Project 3 — “Forecasting + Variance Story” (Planning, trends, partial info)
> forecast + actuals + variance bridge

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