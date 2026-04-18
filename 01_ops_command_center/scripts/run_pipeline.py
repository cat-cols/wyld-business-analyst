#!/usr/bin/env python3
# scripts/run_pipeline.py
"""
One-button pipeline runner.

Runs, in order:
1) source_drop_simulator.py
2) pg_bootstrap.py
3) ingest_raw.py
4) standardize.py
5) dq_checks.py
6) model.py
7) export_samples.py

Usage:
  export PROJECT1_PG_DSN="postgresql://<username>@localhost:5432/wyld_chyld"
  python3 scripts/run_pipeline.py --start 2025-01-01 --end 2025-01-31 --days 90
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import uuid
from pathlib import Path


def get_repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def run(cmd: list[str]) -> None:
    print("\n" + " ".join(cmd))
    subprocess.run(cmd, check=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--start", default="2025-01-01")
    ap.add_argument("--end", default="2025-01-14")
    ap.add_argument("--days", type=int, default=90)
    ap.add_argument("--dsn", default=os.getenv("PROJECT1_PG_DSN", ""))
    ap.add_argument("--base", default=".")
    ap.add_argument("--skip-sim", action="store_true")
    ap.add_argument("--skip-bootstrap", action="store_true")
    args = ap.parse_args()

    if not args.dsn.strip():
        raise SystemExit("Missing DSN. Set PROJECT1_PG_DSN or pass --dsn.")

    repo = get_repo_root()
    scripts = repo / "scripts"

    pipeline_run_id = uuid.uuid4().hex[:12]

    env = os.environ.copy()
    env["PROJECT1_PG_DSN"] = args.dsn

    # We’ll pass run_id to ingest + dq so you can trace a full run if you want
    # (standardize + model currently rebuild whole tables — portfolio-simple.)
    if not args.skip_sim:
        run([sys.executable, str(scripts / "source_drop_simulator.py"), "--start", args.start, "--end", args.end, "--base", args.base])

    if not args.skip_bootstrap:
        run([sys.executable, str(scripts / "pg_bootstrap.py"), "--dsn", args.dsn])

    run([sys.executable, str(scripts / "ingest_raw.py"), "--dsn", args.dsn, "--base", args.base, "--run-id", pipeline_run_id])
    run([sys.executable, str(scripts / "standardize.py"), "--dsn", args.dsn, "--run-id", pipeline_run_id])
    run([sys.executable, str(scripts / "dq_checks.py"), "--dsn", args.dsn, "--run-id", pipeline_run_id])
    run([sys.executable, str(scripts / "model.py"), "--dsn", args.dsn])
    run([sys.executable, str(scripts / "export_samples.py"), "--dsn", args.dsn, "--days", str(args.days), "--base", args.base])

    print(f"\n✅ Pipeline finished. pipeline_run_id={pipeline_run_id}\n")


if __name__ == "__main__":
    main()