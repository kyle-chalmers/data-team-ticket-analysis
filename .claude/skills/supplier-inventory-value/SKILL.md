---
name: supplier-inventory-value
description: Supplier inventory value (available quantity times supply cost) ranked by region, nation or part type, optionally limited to one region and the top N. Use when a ticket asks which regions, nations or part types hold the most supplier inventory value. Parameterized, QC-gated, golden-tested; hard-halts before any external post.
argument-hint: --ticket DATA-<n> --group-by region|nation|part_type [--region <R_NAME>] [--top-n <N>]
built_from: [kyle/DATA-1, leslie/DATA-12]
read_objects: [SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP, SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PART, SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER, SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION, SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.REGION]
---

# /supplier-inventory-value

Generated replacement for the clone-the-last-ticket supplier-inventory-value workflow
([kyle/DATA-1](../../../tickets/kyle/DATA-1/README.md) by region,
[leslie/DATA-12](../../../tickets/leslie/DATA-12/README.md) Europe by part type, top 15).
Parameterized, phased, QC-gated, and **hard-halts before any external post**. Reads the merged
config (`bin/tw effective_config.py`) and resolves all I/O via adapters; only the leaf scripts in
`bin/` name the warehouse CLI. Run on demand, when a ticket like this arrives.

## Required parameters
| Flag | Format | Example | Notes |
|---|---|---|---|
| `--ticket` | `DATA-<n>` | `DATA-13` | Required. Folder: an existing `tickets/*/<id>`, else `tickets/<you>/<id>`; `--assignee <dir>` overrides |
| `--group-by` | `region` \| `nation` \| `part_type` | `part_type` | Required. Output column: `region_name`, `nation_name` or `part_type` (full `P_TYPE`, 150 values) |
| `--region` | a `REGION.R_NAME`, any case | `EUROPE` | Optional; omitted = all regions. Checked against the live `REGION` table (QC check 1) |
| `--top-n` | integer >= 1 | `15` | Optional; omitted = every group. Ties broken by group name; QC check 7 halts if a tie straddles the cut |

## Phase 0 — Pre-flight (halt-on-fail)
1. Interview first, per `reduce_assumptions`: confirm with the requester the group-by, region, top N and
   whether the DATA-1 definitions (value = qty x supply cost, qty > 0 only, full `P_TYPE`) still hold.
   A different definition means this skill does not fit; fall back to `/ticket`.
2. `bash .claude/skills/supplier-inventory-value/bin/drift_check.sh` — every object in `read_objects`
   still reachable; halt on any miss.
3. `bash "$(git rev-parse --show-toplevel)/bin/tw" verify_stack.sh` for the warehouse seam; halt with
   the adapter's auth notes if unreachable.
4. Parameter validation runs inside `bin/run.sh` (exit 1 on a bad flag, before any query).

## Phases 1-3 — Render, QC, export (one command)
```bash
bash .claude/skills/supplier-inventory-value/bin/run.sh --ticket DATA-<n> --group-by <dim> [--region <R>] [--top-n <N>]
```
Fast (seconds on TPCH_SF1), so it runs in the foreground. It:
- **Phase 1:** renders `sql/qc.sql.tmpl` and `sql/inventory_value.sql.tmpl` through
  `render_and_validate.sh --strict` (no leftover tokens, no token in a comment, quoted literals,
  balanced quotes/parens; exit 2 on any finding). It writes them with a `-- warehouse-target:` line 1 to
  `qc_queries/1_reconciliation.sql` and `final_deliverables/1_<region_>inventory_value_by_<dim>.sql`.
  Read-only SQL: no DB writes, so no approval gate and no rollback key.
- **Phase 2, QC (atomic checkpoint):** runs QC **before** exporting anything; exit 4 on any hard-halt failure.

| # | Check | Tier | Remediation |
|---|---|---|---|
| 1 | `--region` matches a `REGION` row | hard-halt | Fix the spelling; list `R_NAME` values |
| 2 | SUPPLIER-NATION-REGION joins keep every `PARTSUPP` row | hard-halt | Orphaned supplier/nation keys: investigate before reporting |
| 3 | `PART` join keeps every in-scope row | hard-halt | Orphaned part keys: investigate |
| 4 | Grain unique: one row per (part, supplier) | hard-halt | Duplicate PARTSUPP rows: the source changed, stop |
| 5 | One row per group, no NULL group | hard-halt | NULL dimension values: decide with requester how to label |
| 6 | Sum over groups = in-scope total, to the cent | hard-halt | Rollup is dropping or double-counting rows |
| 7 | No tie straddles the top-N cut | hard-halt | Ask the requester: widen N or accept the name tie-break |
| 8 | Zero-quantity filter removes no rows | warn | Say how many rows it removed in the README assumptions |

- **Phase 3, export (deterministic):** explicit `ORDER BY inventory_value DESC, <group>`, CLI preamble
  stripped (`split_and_export.sh --strip-only`), header lowercased (Snowflake returns it uppercase; data
  rows are untouched). Canonical name: `final_deliverables/1_<region_>inventory_value_by_<dim>_<N>_records.csv`
  (e.g. `1_europe_inventory_value_by_part_type_15_records.csv`). The CSV is re-read: header row 1, row
  count within top N, unique groups, values non-increasing, ranks from 1, ASCII only (exit 5 on failure).

## Phase 4 — Render docs & HARD HALT
Fill `templates/README.md.tmpl` → the ticket README (results table, QC lines from the run output, every
assumption, including any the requester changed) and `templates/tracker_comment.txt.tmpl` → a draft in
the ticket's `comms/`, under the tracker word limit. Render prose templates with plain `bin/tw render.sh`.
Apply the `/ship` comms rails (word limit, hyperlinks, include-list; voice profile only if one resolves
for the shipper via `resolve_user.py`). Then run `/review` for the independent verdict. Print the summary
and **exit**: no tracker post, no docstore backup, no commit.

## Phase 5 — Post-review (separate invocation)
`/ship <ticket>`. It runs the source-material scan, then commit + PR → merge (asking first) → docstore
backup → tracker comment → chat draft, in that order, each behind `hard_halt_before_external_posts`.
This skill adds nothing to that path.

## Golden test
```bash
bash .claude/skills/supplier-inventory-value/bin/golden_test.sh
```
Replays each `golden/*.json` into a temp folder (ticket folders untouched) and byte-compares the export
to the reference CSV:
- `golden/data-1.json`: `--ticket DATA-1 --group-by region` → 5 rows, total 2,003,609,409,006.92, matches
  `tickets/kyle/DATA-1/final_deliverables/1_inventory_value_by_region_5_records.csv`.
- `golden/data-12.json`: `--ticket DATA-12 --group-by part_type --region EUROPE --top-n 15` → 15 rows,
  total 43,689,988,041.29 (Europe 397,934,639,557.59), matches DATA-12's CSV.

Run it after any edit to `sql/` or `bin/`, and in Phase 0 if the source data may have changed.

## Failure-mode tests
| Input | Expected halt |
|---|---|
| `--group-by brand` / `--ticket 99` / `--top-n abc` | `run.sh` exit 1, before any query |
| A token left in a comment or an unquoted literal in `sql/*.tmpl` | render gate, exit 2 |
| `--region atlantis` | QC check 1 (and 6, empty scope) FAIL, exit 4, no CSV written |
| A table renamed or access revoked | `drift_check.sh` names the unreachable object, non-zero exit |
| Expired warehouse auth | `run.sh` exit 3 with the CLI error |

## Files read / written / side effects
- Reads: `sql/*`, `templates/*`, `golden/*`, `bin/*`, the merged config, the five `read_objects` (read-only)
- Writes: the ticket's `qc_queries/1_reconciliation.sql`, `final_deliverables/*.sql` + `*_records.csv`,
  README, `comms/` tracker draft
- Side effects: none. Warehouse access is read-only; every external post goes via `/ship`.
