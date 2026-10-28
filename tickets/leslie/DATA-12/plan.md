# Plan — DATA-12: Europe inventory value by part type

**Confidence (1–10): 9**

## Goal
Show which part types hold the most supplier inventory value in Europe, so the requester can see where European stock value is concentrated.

## Scope
- **In:** suppliers whose nation is in the EUROPE region; value = `PS_AVAILQTY * PS_SUPPLYCOST`; grouped by full `PART.P_TYPE` (150 distinct values); top 15.
- **Explicitly out:** other regions, retail value, the two-word type group (e.g. "ECONOMY ANODIZED"), any time trend (`PARTSUPP` has no dates).

## Builds on
- kyle/DATA-1 (shared object `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP`, same value definition): reuse its query shape (`final_deliverables/1_inventory_value_by_region.sql`) and reconciliation pattern (`qc_queries/1_reconciliation.sql`); its EUROPE total 397,934,639,557.59 is this ticket's reconciliation anchor.

## Deliverables expected
1. `final_deliverables/1_europe_inventory_value_by_part_type_15_records.csv` - one row per part type, columns `rank, part_type, inventory_value`.
2. `final_deliverables/1_europe_inventory_value_by_part_type.sql` - the query behind it.
3. `qc_queries/1_reconciliation.sql` - build-time checks.

## Approach
1. Adapt DATA-1's query: add the `PART` join, filter `R_NAME = 'EUROPE'`, group by `P_TYPE`, rank by value, keep the top 15.
2. Run the QC checks, then the query; export the CSV with an explicit `ORDER BY` and a lowercased header.
3. Fill the README (assumptions, results table, QC results), then run `/review`.

## Validation strategy (defined BEFORE code)
- Joined Europe rows = 158,960 and the `PART` join drops no rows.
- `PARTSUPP` grain (part, supplier) is unique; each part type appears once in the output.
- Sum over all 150 types = independent Europe total = DATA-1's 397,934,639,557.59, to the cent.
- Output has 15 rows, strictly descending, ASCII only; the CSV re-read matches the SQL output.

## Touched
- **Objects/files:** `PARTSUPP`, `PART`, `SUPPLIER`, `NATION`, `REGION` (read-only); `tickets/leslie/DATA-12/`.
- **Tool slots:** warehouse (Snowflake reads), tracker (Jira read; comment at ship), vcs (GitHub branch + PR).

## Questions for the requester
- Ties at 15th place? Exactly 15 rows; ties share a rank and are broken by part type name.
- Columns? `rank, part_type, inventory_value`, mirroring DATA-1.
- Zero-quantity rows? Excluded (`PS_AVAILQTY > 0`), matching DATA-1; none exist today.

## Risks
- Ties near the cut could make #15 arbitrary: handled by the deterministic name tie-break.
- "Part type" misread as the type group: the ticket names `P_TYPE`, so the full value is used.

## Next step
- **spec:** not required
- Then `/build leslie/DATA-12` → `/ship leslie/DATA-12` on APPROVE.
