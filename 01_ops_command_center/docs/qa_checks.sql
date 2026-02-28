Create `docs/qa_phase2_checks.sql` that answers:

1. Do row counts exist for each staging model?
2. What % of rows are flagged?
3. Are the keys usable (how many null keys)?
4. Are there unexpected channel/team/metric values?

Example checks:

* row counts per model
* `avg(flag::int)` per flag
* top 20 unknown KPI categories
* distinct channels list