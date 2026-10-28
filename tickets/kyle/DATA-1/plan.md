# Plan — DATA-1: Inventory value by supplier region

**Confidence (1–10): 9**

## Goal
Give the requester a complete list of all regions ranked by supplier inventory value, highest to lowest. Inventory value is defined as available quantity times supply cost, per the requester.

## Scope
- **In:** `SUM(PS_AVAILQTY * PS_SUPPLYCOST)` over `PARTSUPP` rows with `PS_AVAILQTY > 0`, rolled up to region via `SUPPLIER` -> `NATION` -> `REGION`. Every region (5) is listed, ranked by value descending.
- **Explicitly out:** per-nation, per-part, or per-supplier breakdowns; trends over time; currency conversion (TPCH has no currency field); any write to the warehouse.

## Builds on
None found. The ticket archive has 0 prior tickets and `OBJECTS.md` has no objects.

## Deliverables expected
1. `final_deliverables/1_inventory_value_by_region_5_records.csv` - grain: one row per region; columns `rank, region_name, inventory_value` (2 decimals, ASCII only, header row first, explicit `ORDER BY inventory_value DESC, region_name`).
2. `final_deliverables/1_inventory_value_by_region.sql` - the query that produced it, with a `-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` header.

## Approach
1. Write the roll-up query (inner joins `PARTSUPP` -> `SUPPLIER` -> `NATION` -> `REGION`, filter `PS_AVAILQTY > 0`, group by region, rank by value).
2. Run it read-only on `COMPUTE_EXTRA_SMALL` and export the CSV with `--format csv`, stripping the status preamble.
3. Run QC queries (below) and save them in `qc_queries/`.
4. Fill the README with assumptions and QC results.

## Validation strategy (defined BEFORE code)
- **Row reconciliation:** joined row count equals `PARTSUPP` rows with `PS_AVAILQTY > 0` (800,000 expected, since profiling found 0 zero-quantity rows), so no rows are dropped or fanned out by the joins.
- **Value reconciliation:** the sum across the 5 regions equals an independent whole-table `SUM(PS_AVAILQTY * PS_SUPPLYCOST)` with no joins.
- **Duplicates:** no repeated region in the output; exactly 5 rows, matching `COUNT(*)` of `REGION`.
- **Grain check:** `PARTSUPP` has one row per (`PS_PARTKEY`, `PS_SUPPKEY`); profiling found 800,000 rows and 800,000 distinct keys.
- **Order:** CSV is strictly descending by value (re-checked after export).
- /review re-runs the queries independently.

## Touched
- **Objects/files:** `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP`, `SUPPLIER`, `NATION`, `REGION` (read only); new files under `tickets/kyle/DATA-1/`.
- **Tool slots:** tracker (Jira: read ticket now, comment on ship), warehouse (Snowflake via `snow` CLI, read only), vcs (GitHub: branch `DATA-1`, PR), docstore (Drive backup on ship).

## Questions for the requester
- Q: Which columns should the CSV contain? A: rank, region, value (`rank, region_name, inventory_value`).
- Q: Include every `PARTSUPP` row, or exclude zero-quantity rows? A: exclude zero-quantity rows. Profiling found none, so the filter has no effect on the result; it stays in the SQL as written.

## Risks
- The filter is a no-op today; if the sample data ever changes, the row reconciliation (joined rows vs. rows with `PS_AVAILQTY > 0`) would still catch dropped rows.
- Regional values are within about 4% of each other (about $392B to $408B), so the ranking is sensitive to the definition. The assumptions are written in the README so the reader can see exactly what was summed.
- Values are large (hundreds of billions); the CSV keeps full precision to 2 decimals and the README states the unit is the sample data's unlabeled currency.

## Next step
- **spec:** not required
- Then `/build kyle/DATA-1` → `/ship kyle/DATA-1` on APPROVE.
