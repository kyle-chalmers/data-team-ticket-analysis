# QC Review - leslie/DATA-12
verdict: APPROVE
review_mode: independent-subagent
subagent_isolation: documented
team_docs: none configured
human_signoff: 2026-10-28, Leslie (leslie): "Approve and ship"

Pyramid: lint ok - counts & dedup ok - reconcile ok - re-run diff ok - output & docs ok

## Summary
Independent `qc-reviewer` subagent re-ran the deliverable and its own queries. Re-run data rows are byte-identical to the committed CSV (header differs only in case, lowercased after export as the README discloses). Totals reconcile to the cent against an independently shaped query and kyle/DATA-1's EUROPE value. Both grains are unique. The plan's Validation strategy is met in full. No Critical or Should-fix findings; two Review notes.

## Layer results
1. **Dialect lint (Snowflake):** params CTE, inner joins only, no `= NULL` / `SELECT *` / `NOT IN` / division; `QUALIFY ROW_NUMBER() <= top_n` gives exactly 15 rows; explicit final `ORDER BY` with tie-break.
2. **Counts & dedup:** `PARTSUPP` 800,000 rows = 800,000 distinct (part, supplier); Europe subset 158,960 rows, 1,987 suppliers; 0 NULL measures; qty 1-9999, cost 1.00-1000.00; 150 part types, one row each; CSV 15 rows, 15 distinct types, ranks 1-15, strictly descending; no ties among the 150 (smallest gap 4,913.84); #15 leads #16 by about 17.6M.
3. **Reconciliation:** 0 `PARTSUPP` rows without a `SUPPLIER` or `PART`; one EUROPE region (France, Germany, Romania, Russia, United Kingdom); Europe total 397,934,639,557.59 = kyle/DATA-1 EUROPE to the cent; top-15 total 43,689,988,041.29 (10.98%).
4. **Re-run + anti-patterns:** re-run data rows identical to the CSV; author's QC script 8/8 TRUE; no correctness, performance or data-quality problems.
5. **Static output checks:** header on row 1; filename count matches 15 rows; ASCII only; README has context, 5 assumptions, results and QC.

## Findings
- [Review] kind: defect - `final_deliverables/1_europe_inventory_value_by_part_type.sql:25,29` - the rounded output alias `inventory_value` shadows the unrounded source column, so the final `ORDER BY` uses the rounded value while the window functions use the unrounded one. No effect today (no ties); optional fix is a distinct alias.
- [Review] kind: defect - `qc_queries/1_reconciliation.sql:16` - `eu.*` in an internal QC CTE; harmless.

## Verification queries run (read-only)
1. Re-ran the deliverable SQL and diffed it against the committed CSV (data rows identical).
2. Re-ran `qc_queries/1_reconciliation.sql` (8/8 TRUE).
3. Source grain, NULL, range and join-match checks across `PARTSUPP`, `PART`, `SUPPLIER`, `REGION`.
4. Independent Europe aggregation via an IN-subquery semi-join (150 types, 158,960 rows, same totals).
5. CSV static checks (ASCII, trailing newline, row count vs filename).
