# DATA-12: Europe inventory value by part type

## Ticket Information
- **Link:** https://kclabs.atlassian.net/browse/DATA-12
- **Type:** Task
- **Status:** Done
- **Epic/Parent:** 
- **Assignee:** leslie
- **Warehouse target(s):** SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 <!-- omit this line when the stack has no warehouse seam -->

## Business Context
For suppliers in Europe, break supplier inventory value (available quantity times supply cost from SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP) out by part type (PART.P_TYPE). Top 15 part types.

## Investigation Scope
Break Europe's supplier inventory value out by part type and keep the top 15. Objects (read-only): `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP` joined to `PART`, `SUPPLIER`, `NATION`, `REGION`. Mirrors [kyle/DATA-1](../../kyle/DATA-1/README.md) (same value definition and region join; its EUROPE total is this ticket's reconciliation anchor). See [plan.md](plan.md).

build_mode: inline
subagent_isolation: documented (not used: plan needs no spec)

## Assumptions Made
1. **Business Definition**: inventory value = `PS_AVAILQTY * PS_SUPPLYCOST`, summed per part type.
   - **Reasoning**: given in the ticket; same definition as kyle/DATA-1.
   - **Context**: `PARTSUPP` has one row per part/supplier pair.
   - **Impact**: supply-cost value, not retail value; TPCH has no currency, so values are unitless.
2. **Status/Population Filter**: suppliers whose nation is in the EUROPE region (`SUPPLIER.S_NATIONKEY` -> `NATION.N_REGIONKEY` -> `REGION.R_NAME = 'EUROPE'`); rows with `PS_AVAILQTY > 0` only.
   - **Reasoning**: the ticket asks for suppliers in Europe; the zero-quantity filter matches DATA-1 (requester confirmed during scoping).
   - **Context**: 158,960 of 800,000 `PARTSUPP` rows are European; no zero-quantity rows exist.
   - **Impact**: the filter removes nothing today.
3. **Data Interpretation**: "part type" is the full `PART.P_TYPE` value (150 distinct, e.g. "STANDARD ANODIZED TIN"), not the two-word type group.
   - **Reasoning**: the ticket names `PART.P_TYPE`.
   - **Context**: no NULL part types; every European row joins to a part.
   - **Impact**: the top 15 is chosen from 150 types.
4. **Output Format**: CSV columns `rank, part_type, inventory_value`; value rounded to 2 decimals; exactly 15 rows, ties share a rank and are broken by part type name (requester confirmed). Header lowercased after export (Snowflake returns it uppercase); data rows are exactly the SQL output.
   - **Reasoning**: requester's answers during scoping; mirrors DATA-1.
   - **Context**: no tie exists at or around the 15th place.
   - **Impact**: none on today's result.
5. **Scope/Time Window**: a point-in-time snapshot of the static sample data; no date filter.
   - **Reasoning**: `PARTSUPP` has no date column.
   - **Context**: sample data is static.
   - **Impact**: none.

## Deliverables
1. [final_deliverables/1_europe_inventory_value_by_part_type_15_records.csv](final_deliverables/1_europe_inventory_value_by_part_type_15_records.csv) - top 15 part types by European supplier inventory value. Warehouse target: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (read-only).
2. [final_deliverables/1_europe_inventory_value_by_part_type.sql](final_deliverables/1_europe_inventory_value_by_part_type.sql) - the query behind it.

| Rank | Part type | Inventory value |
|---|---|---|
| 1 | STANDARD ANODIZED TIN | 2,990,098,860.71 |
| 2 | MEDIUM BURNISHED COPPER | 2,981,859,753.37 |
| 3 | ECONOMY BURNISHED COPPER | 2,963,353,094.67 |
| 4 | ECONOMY ANODIZED STEEL | 2,960,387,366.40 |
| 5 | PROMO BRUSHED BRASS | 2,954,497,978.13 |
| 6 | PROMO POLISHED TIN | 2,941,807,949.91 |
| 7 | LARGE PLATED STEEL | 2,913,095,078.92 |
| 8 | MEDIUM ANODIZED TIN | 2,891,088,453.23 |
| 9 | LARGE ANODIZED BRASS | 2,885,580,019.80 |
| 10 | STANDARD PLATED BRASS | 2,875,851,495.92 |
| 11 | SMALL POLISHED TIN | 2,872,000,342.40 |
| 12 | SMALL POLISHED COPPER | 2,871,332,351.88 |
| 13 | SMALL BRUSHED TIN | 2,864,648,755.27 |
| 14 | STANDARD POLISHED TIN | 2,862,606,695.82 |
| 15 | SMALL PLATED NICKEL | 2,861,779,844.86 |

Top 15 total: 43,689,988,041.29 (11.0% of Europe's 397,934,639,557.59). Value is spread evenly: #1 and #15 differ by about 4.5%.

## Quality Control
Build-time checks ([qc_queries/1_reconciliation.sql](qc_queries/1_reconciliation.sql)), all passing:
- Europe rows 158,960 = scoping count; the `PART` join drops no rows.
- Zero-quantity filter is a no-op (all 800,000 `PARTSUPP` rows have quantity > 0).
- Grain unique: 158,960 distinct part/supplier pairs.
- 150 part types, one row each; their sum = the Europe total = kyle/DATA-1's EUROPE value (397,934,639,557.59), to the cent.
- No tie straddles the top-15 cut.
- CSV re-read after export: 15 rows, 15 distinct types, ranks 1-15, strictly descending, ASCII only.

Review verdict: APPROVE ([qc_queries/2_review_verdict.md](qc_queries/2_review_verdict.md)); independent-subagent review, human sign-off by Leslie on 2026-10-28.
