# DATA-8: Returned items by ship mode

## Ticket Information
- **Link:** https://kclabs.atlassian.net/browse/DATA-8
- **Type:** Task
- **Status:** To Do
- **Epic/Parent:** none
- **Assignee:** Kyle Chalmers
- **Warehouse target(s):** SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)

## Business Context
Count of returned line items (L_RETURNFLAG = 'R') by ship mode from SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM.

## Investigation Scope
Count returned line items per ship mode. Object (read-only): `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM` (6,001,215 line items). Reuses the per-mode count-and-share shape of the earlier late-shipments ticket on the same table. See [plan.md](plan.md).

build_mode: inline
subagent_isolation: documented (not used: plan needs no spec)

## Assumptions Made
1. **Business Definition**: a returned line item has `L_RETURNFLAG = 'R'`.
   - **Reasoning**: given in the ticket.
   - **Context**: the flag takes 3 values: `R` (1,478,870), `A` (1,478,493) and `N` (3,043,852). `R` and `A` occur only on items received by 1995-06-17; every later item is `N`.
   - **Impact**: about half (50.01%) of items old enough to carry a return flag were returned.
2. **Output Format**: the share is returned items over all of the mode's line items, to 2 decimals.
   - **Reasoning**: chosen during scoping.
   - **Context**: over all items the share is 24.64%; over returnable items (flag `A` or `R`) it is 50.01%.
   - **Impact**: the share in the file is the lower, all-items figure.
3. **Data Interpretation**: ship mode is `L_SHIPMODE`; one `LINEITEM` row is one line item.
   - **Reasoning**: (`L_ORDERKEY`, `L_LINENUMBER`) is unique; no NULL ship modes or flags.
   - **Context**: 7 ship modes exist.
   - **Impact**: none.
4. **Output Format**: CSV columns `ship_mode, line_items, returned_line_items, pct_returned`; most returns first, then ship mode. The header is lowercased after export.
   - **Reasoning**: the ticket asks for the count; the share puts it in context.
   - **Context**: TPC-H data is synthetic.
   - **Impact**: none on the numbers.

## Deliverables
1. [final_deliverables/1_returned_items_by_ship_mode_7_records.csv](final_deliverables/1_returned_items_by_ship_mode_7_records.csv) - returned line items per ship mode. Warehouse target: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (read-only).
2. [final_deliverables/1_returned_items_by_ship_mode.sql](final_deliverables/1_returned_items_by_ship_mode.sql) - the query behind it.

| Ship mode | Line items | Returned | % returned |
|---|---|---|---|
| RAIL | 856,484 | 211,640 | 24.71% |
| AIR | 858,104 | 211,384 | 24.63% |
| MAIL | 857,401 | 211,365 | 24.65% |
| SHIP | 858,036 | 211,348 | 24.63% |
| FOB | 857,324 | 211,143 | 24.63% |
| REG AIR | 856,868 | 211,114 | 24.64% |
| TRUCK | 856,998 | 210,876 | 24.61% |

Total: 1,478,870 returned of 6,001,215 line items (24.64%). The modes differ by at most 764 returns (0.1 point of share), so no ship mode has notably more returns.

## Quality Control
*The `/review` verdict + pyramid results (counts/dedup, reconciliation, anti-patterns) — from
`qc_queries/<n>_review_verdict.md`. If the ticket shipped unreviewed, this section says so: the
verdict on file is `SKIPPED`, and it names who chose that and when.*

Build-time checks ([qc_queries/1_reconciliation.sql](qc_queries/1_reconciliation.sql)), all passing:
- Mode counts sum to 6,001,215 = `LINEITEM` rows; line-item grain unique.
- Returned counts sum to 1,478,870 = independent whole-table `R` count.
- 7 output rows = 7 distinct ship modes; no NULL mode or flag.
- Every `pct_returned` equals returned / items within 0.01.
- Info: `R` is 50.01% of items flagged `A` or `R`.
- CSV re-read: 7 data rows, header row 1, ASCII only.

Review verdict: APPROVE ([qc_queries/2_review_verdict.md](qc_queries/2_review_verdict.md)); independent-subagent review, sign-off by Kyle Chalmers through the batch pre-approval on 2026-10-28.
