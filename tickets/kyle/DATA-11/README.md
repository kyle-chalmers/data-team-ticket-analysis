# DATA-11: Orders per clerk for 1995

## Ticket Information
- **Link:** https://kclabs.atlassian.net/browse/DATA-11
- **Type:** Task
- **Status:** To Do
- **Epic/Parent:** none
- **Assignee:** Kyle Chalmers
- **Warehouse target(s):** SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)

## Business Context
Number of orders handled by each clerk in 1995, top 20. Use SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS.

## Investigation Scope
Orders handled per clerk in 1995, top 20. Object (read-only): `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` (228,637 orders dated in 1995, handled by 1,000 clerks). Reuses the calendar-year window of the earlier 1997 monthly revenue ticket on this table. See [plan.md](plan.md).

build_mode: inline
subagent_isolation: documented (not used: plan needs no spec)

## Assumptions Made
1. **Business Definition**: the clerk who handled an order is `O_CLERK`; one `ORDERS` row is one order.
   - **Reasoning**: the only clerk field; `O_ORDERKEY` is unique in 1995.
   - **Context**: no NULL clerks; 1,000 clerks have 1995 orders.
   - **Impact**: a row count per clerk is an order count.
2. **Scope/Time Window**: an order is in 1995 when its `O_ORDERDATE` falls from 1995-01-01 (inclusive) to 1996-01-01 (exclusive).
   - **Reasoning**: `O_ORDERDATE` is the only date on `ORDERS`.
   - **Context**: 1995 orders run 1995-01-01 to 1995-12-31.
   - **Impact**: none.
3. **Output Format**: CSV columns `rank, clerk, order_count`, most orders first, ties by clerk id. Tied clerks share a rank (`RANK()`); there is no tie at 20th place (258 vs 257), so exactly 20 rows return. The header is lowercased after export.
   - **Reasoning**: chosen during scoping.
   - **Context**: clerk ids are synthetic (`Clerk#000000185`), so the file holds no real personal data.
   - **Impact**: ranks skip after ties (3, 3, 3, then 6).

## Deliverables
1. [final_deliverables/1_orders_per_clerk_1995_20_records.csv](final_deliverables/1_orders_per_clerk_1995_20_records.csv) - top 20 clerks by 1995 orders. Warehouse target: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (read-only).
2. [final_deliverables/1_orders_per_clerk_1995.sql](final_deliverables/1_orders_per_clerk_1995.sql) - the query behind it.

| Rank | Clerk | Orders |
|---|---|---|
| 1 | Clerk#000000185 | 277 |
| 2 | Clerk#000000076 | 270 |
| 3 | Clerk#000000312 | 269 |
| 3 | Clerk#000000840 | 269 |
| 3 | Clerk#000000899 | 269 |
| 6 | Clerk#000000005 | 262 |
| 6 | Clerk#000000081 | 262 |
| 6 | Clerk#000000282 | 262 |
| 6 | Clerk#000000740 | 262 |
| 10 | Clerk#000000002 | 261 |
| 10 | Clerk#000000502 | 261 |
| 10 | Clerk#000000715 | 261 |
| 13 | Clerk#000000302 | 260 |
| 13 | Clerk#000000532 | 260 |
| 15 | Clerk#000000013 | 259 |
| 15 | Clerk#000000474 | 259 |
| 17 | Clerk#000000139 | 258 |
| 17 | Clerk#000000496 | 258 |
| 17 | Clerk#000000705 | 258 |
| 17 | Clerk#000000929 | 258 |

Clerk#000000185 handled the most 1995 orders (277). The top 20 handled 5,255 orders between them, 2.3% of the year's 228,637, against an average of about 229 per clerk.

## Quality Control
*The `/review` verdict + pyramid results (counts/dedup, reconciliation, anti-patterns) — from
`qc_queries/<n>_review_verdict.md`. If the ticket shipped unreviewed, this section says so: the
verdict on file is `SKIPPED`, and it names who chose that and when.*

Build-time checks ([qc_queries/1_reconciliation.sql](qc_queries/1_reconciliation.sql)), all passing:
- Per-clerk counts sum to 228,637 = 1995 `ORDERS` rows; `O_ORDERKEY` unique; no NULL clerk.
- No tie at the cut-off: 20th place has 258 orders, 21st has 257.
- Info: 1,000 clerks had 1995 orders; the top 20 handled 5,255.
- CSV re-read: 20 data rows, 20 distinct clerks, non-increasing counts, header row 1, ASCII only.

Review verdict: APPROVE ([qc_queries/2_review_verdict.md](qc_queries/2_review_verdict.md)); independent-subagent review, sign-off by Kyle Chalmers through the batch pre-approval on 2026-10-28.
