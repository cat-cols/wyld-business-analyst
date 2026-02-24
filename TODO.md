# TODO

## Repo Polish
- [ ] Reduce repo bloat by moving large databases/assets to GitHub Releases
- [ ] Reconcile duplicate definition files into one master definition file
- [ ] Refactor Project 1 download links in `getting-started.md` so they pull the correct files from GitHub

## Setup & Environment
- [ ] Add `requirements-forecasting` option to bash setup script
- [ ] Add `requirements-dq` option to bash setup script
- [ ] Add setup script option for `minimal` vs `full` environment install

## Project 1
- [ ] Update `generate_project1_data.py` to use the new product definition file
- [ ] Update `generate_project1_data.py` to use the new location definition file
- [ ] Update `generate_project1_data.py` to separate warehouse/retail locations into their own tables from locations table(where wyld sells to)
- [ ] Should I separate the location generation into its own script?
- [ ] Update `generate_project1_data.py` to use the new channel definition file / Should I separate the channel generation into its own script?

## Portfolio Presentation
- [ ] Finalize clean root README (what it is, what it proves, how to run)
- [ ] Add architecture diagram to README/docs
- [ ] Add sample dashboard screenshot
- [ ] Add sample DQ scorecard screenshot
- [ ] Ensure only small sample data is tracked
- [ ] Finalize reproducible setup steps
- [ ] Add clear simulation / no proprietary data disclaimer

## README
- [ ] Update the author line if you want a different display name
- [ ] Add 2–3 screenshots (even placeholders) ASAP — that gives the repo instant visual credibility
- [ ] If you want, I can also write a **killer Project 1 README** next so the root README links into something equally polished.


## Screenshots (add these to strengthen the repo)
Add these to `assets/screenshots/` and embed them here:

- [ ] Ops Command Center dashboard
- [ ] Reconciliation / data confidence page
- [ ] DQ scorecard (Project 2)
- [ ] GHG scorecard (Project 4)
- [ ] Star schema / data flow diagram

Example (replace paths once added):
```md
![Ops Command Center](assets/screenshots/ops_command_center.png)
![DQ Scorecard](assets/screenshots/dq_scorecard.png)
```

## Results / Insights
- [ ] Add one “Results / Insights” section in root README with 3–5 bullets (what business questions Project 1 answers). Right now you describe architecture and process well, but business outcomes need one more spotlight
