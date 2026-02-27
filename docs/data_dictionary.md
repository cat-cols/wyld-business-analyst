# Data Dictionary (Repo-Level)

**Repo:** wyld-business-analyst
**Owner:** Brandon Hardison
**Status:** Draft v1 (2026-02-26)

## Purpose

This repo contains multiple portfolio projects. Each project has its own detailed data dictionary.

This repo-level dictionary exists to:
- describe the overall data domains and where artifacts live
- define shared conventions (naming, units, types)
- point readers to project-level dictionaries (source of truth)

## Where to find detailed dictionaries

- **Project 1 (Ops Command Center):** `01_ops_command_center/docs/data_dictionary.md`
- **Project 2 (Quarterly DC QA/QC):** `02_quarterly_dc_qaqc_system/docs/data_dictionary.md` *(planned)*
- **Project 3 (Forecasting):** `03_forecasting_variance_story/docs/data_dictionary.md` *(planned)*
- **Project 4 (GHG):** `04_ghg_scope_reporting/docs/data_dictionary.md` *(planned)*

## Repo-wide conventions

### Naming
- `*_key` = surrogate integer key used for joins
- `*_amount` = currency totals (USD)
- `*_price` = per-unit price (USD per unit)
- `*_rate` = proportion (0–1)
- `*_count` = count
- `is_*` / `*_flag` = boolean represented as `0/1`

### Currency + units
- Currency is **USD** unless specified.
- Prices are **USD per unit**.
- Rates are **0–1 decimals** (not percent strings).

### Source vs modeled layers
- **Source extracts** simulate messy real-world inputs and may contain:
  - inconsistent headers
  - casing/whitespace drift
  - missing keys
  - mixed date formats

- **Modeled tables** are clean “truth” tables intended for analytics, marts, and reporting.
## Key output locations (high level)
- `01_ops_command_center/data/source_extracts/**` = simulated incoming files (“messy”)
- `01_ops_command_center/data/modeled/**` = modeled truth tables (dims/facts)
- `01_ops_command_center/data/sample/**` = small sample-only subsets
- `01_ops_command_center/docs/**` = project documentation + run manifests