#!/usr/bin/env bash
set -euo pipefail
psql -d "${1:-wyld_sim}" -f environment/postgres/01_create_wyld_sim_postgres.sql
psql -d "${1:-wyld_sim}" -f environment/postgres/02_load_wyld_sim_postgres.sql
