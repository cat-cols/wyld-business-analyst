-- stg/00_create_schemas.sql
-- Purpose: one-time (but safe to rerun) schema bootstrap for the whole pipeline.
-- Run with: psql "$PROJECT1_PG_DSN" -v ON_ERROR_STOP=1 -f stg/00_create_schemas.sql

-- Create core schemas (idempotent)
create schema if not exists raw;
create schema if not exists stg;
create schema if not exists int;
create schema if not exists mart;
create schema if not exists qa;
create schema if not exists validation;

-- Optional: a dedicated scratch schema for experiments (comment in if you want it)
-- create schema if not exists scratch;

-- Notes:
-- - Avoid extensions here unless you're sure your environment allows them.
-- - If you DO rely on extensions, uncomment and add them below.
-- Example:
-- create extension if not exists pgcrypto;
-- create extension if not exists citext;