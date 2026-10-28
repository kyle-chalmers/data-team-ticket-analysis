# DATA-1: Inventory value by supplier region

## Ticket Information
- **Link:** https://kclabs.atlassian.net/browse/DATA-1
- **Type:** Task
- **Status:** To Do
- **Epic/Parent:** none
- **Assignee:** Kyle Chalmers
- **Warehouse target(s):** SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)

## Business Context
Which regions hold the most supplier inventory value? I want to see a complete list of the regions ordered from the highest value to the lowest value.

Clarification from requester: inventory value is available quantity times supply cost from SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP, rolled up by the supplier's region (SUPPLIER, NATION, REGION).

## Investigation Scope
Roll up supplier inventory value to region. Objects (read-only): `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP` (800,000 rows) joined to `SUPPLIER` (10,000), `NATION` (25), `REGION` (5). No prior tickets to reuse (archive was empty). See [plan.md](plan.md).

build_mode: inline
subagent_isolation: documented (not used: plan needs no spec)

## Assumptions Made
1. **Business Definition**: inventory value = `PS_AVAILQTY * PS_SUPPLYCOST`, summed per region.
   - **Reasoning**: given by the requester in the ticket request.
   - **Context**: `PARTSUPP` carries one row per part/supplier pair.
   - **Impact**: this is supply-cost value, not retail value.
2. **Status/Population Filter**: only rows with `PS_AVAILQTY > 0` count (requester chose "exclude zero-quantity rows").
   - **Reasoning**: requester's answer during scoping.
   - **Context**: minimum quantity in the data is 1, so 0 rows are excluded.
   - **Impact**: none today; all 800,000 rows are included.
3. **Data Interpretation**: a supplier's region is `SUPPLIER.S_NATIONKEY` -> `NATION.N_REGIONKEY` -> `REGION`.
   - **Reasoning**: the path named in the request.
   - **Context**: no NULL keys and no orphaned suppliers were found.
   - **Impact**: every PARTSUPP row maps to exactly one region.
4. **Output Format**: CSV columns `rank, region_name, inventory_value`; value rounded to 2 decimals; tied regions would share a rank and sort by region name (no ties occur). The CSV header is lowercased after export (Snowflake returns it uppercase); data rows are otherwise exactly the SQL output.
   - **Reasoning**: requester's answer during scoping; TPCH has no currency field, so the value is unitless.
   - **Context**: the five regions sit within about 4% of each other.
   - **Impact**: the ranking is a straight sort on the summed value.
5. **Scope/Time Window**: a point-in-time snapshot of the sample data; no date filter applies.
   - **Reasoning**: `PARTSUPP` has no date column.
   - **Context**: sample data is static.
   - **Impact**: none.

## Deliverables
1. [final_deliverables/1_inventory_value_by_region_5_records.csv](final_deliverables/1_inventory_value_by_region_5_records.csv) - 5 regions ranked by inventory value (highest to lowest). Warehouse target: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (read-only).
2. [final_deliverables/1_inventory_value_by_region.sql](final_deliverables/1_inventory_value_by_region.sql) - the query behind it.

| Rank | Region | Inventory value |
|---|---|---|
| 1 | AMERICA | 407,942,718,701.84 |
| 2 | MIDDLE EAST | 405,058,070,978.87 |
| 3 | ASIA | 400,599,873,546.96 |
| 4 | EUROPE | 397,934,639,557.59 |
| 5 | AFRICA | 392,074,106,221.66 |

Total across regions: 2,003,609,409,006.92.

## Quality Control
*The `/review` verdict + pyramid results (counts/dedup, reconciliation, anti-patterns) — from
`qc_queries/<n>_review_verdict.md`. If the ticket shipped unreviewed, this section says so: the
verdict on file is `SKIPPED`, and it names who chose that and when.*

Build-time checks ([qc_queries/1_reconciliation.sql](qc_queries/1_reconciliation.sql)), all passing:
- Joined rows 800,000 = filtered `PARTSUPP` rows 800,000 = all `PARTSUPP` rows (the zero-quantity filter removes nothing).
- `PARTSUPP` grain is unique: 800,000 distinct part/supplier pairs.
- Region sum 2,003,609,409,006.92 = independent whole-table sum, to the cent.
- 5 output regions = 5 `REGION` rows; no duplicates.
- CSV re-read after export: 5 rows, strictly descending, sum matches, ASCII only.

Review verdict: APPROVE ([qc_queries/2_review_verdict.md](qc_queries/2_review_verdict.md)); independent-subagent review, human sign-off by Kyle Chalmers on 2026-10-27.
