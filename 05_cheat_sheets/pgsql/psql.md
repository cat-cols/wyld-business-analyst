# connect to database
psql "$PROJECT1_PG_DSN"

# Drop schema
psql "$PROJECT1_PG_DSN" -c "drop schema if exists stg cascade;"

# Drop table
psql "$PROJECT1_PG_DSN" -c "drop table if exists raw.sales_distributor_extract cascade;"




---

### 1) Just connect correctly from Terminal

Even without any env var:

```bash
psql -h localhost -p 5432 -U b -d wyld_chyld
```

Then check what exists:

```sql
\dn          -- list schemas
\dv stg.*    -- list staging views
\dv int.*    -- list int views
\dv mart.*   -- list mart views
```

If `raw/stg/int/mart` schemas are there, you’re already set.

### 2) If you want your `psql "$PROJECT1_PG_DSN"` commands to work every time

You need to **store** the DSN somewhere your shell loads.

Pick one:

**Project-local (clean + explicit):**
Create `env/project1.env`:

```bash
export PROJECT1_PG_DSN="postgresql://b@localhost:5432/wyld_chyld"
```

Then:

```bash
source env/project1.env
```

**Always-on (global):**
Add to `~/.zshrc`:

```bash
export PROJECT1_PG_DSN="postgresql://b@localhost:5432/wyld_chyld"
```

Then:

```bash
source ~/.zshrc
```

---
---

# ISSUES/DEBUGGING:

* When you run `echo "DSN=[$PROJECT1_PG_DSN]"` and get `[]`, this means **Terminal session has no DSN configured**, even if DBeaver (or Windsurf) is happily connected somewhere else.

* Environment variables like `PROJECT1_PG_DSN` are **per-shell-session** unless you save them somewhere (like `.zshrc`, `.env`, `.envrc`, etc.).

So: **your connection settings *are* “saved somewhere else”** (DBeaver), just not in the place `psql` looks (your shell environment).

## Where else settings might already be saved

* **DBeaver:** yes (connection profile)
* **pgAdmin:** yes (server registration)
* **Windsurf:** maybe (if you configured its DB extension/connection), but that still won’t set Terminal env vars
* **Your shell:** only if you added it to `.zshrc`, `.zprofile`, `.envrc`, or you `export`ed it in that same terminal session earlier

Bottom line: you’re not redoing the database—you're just making sure **your Terminal knows where it is**.