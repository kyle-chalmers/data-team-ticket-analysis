# DATA-2: Order count by order status

## Ticket Information
- **Link:** https://kclabs.atlassian.net/browse/DATA-2
- **Type:** Task
- **Status:** Done
- **Epic/Parent:** none
- **Assignee:** Kyle Chalmers
- **Warehouse target(s):** SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)

## Business Context
How many orders are in each order status? Use SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS.

## Investigation Scope
Count orders per order status. Object (read-only): `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` (1,500,000 rows, one per `O_ORDERKEY`). No prior tickets to reuse (recall found no match on `ORDERS`). See [plan.md](plan.md).

build_mode: inline
subagent_isolation: documented (not used: plan needs no spec)

## Assumptions Made
1. **Business Definition**: an order's status is `O_ORDERSTATUS`; one `ORDERS` row is one order.
   - **Reasoning**: the ticket names `ORDERS`; `O_ORDERKEY` is unique (1,500,000 rows, 1,500,000 distinct).
   - **Context**: no NULL statuses were found.
   - **Impact**: a row count is an order count; nothing falls out of the grouping.
2. **Data Interpretation**: the labels are F = Fulfilled, O = Open, P = Partially shipped.
   - **Reasoning**: TPCH has no status lookup table; the TPC-H spec sets `O_ORDERSTATUS` to F when all line items are shipped (`L_LINESTATUS` = F), O when none are, and P otherwise.
   - **Context**: profiling dates fit this reading: F orders run 1992 to mid-1995, O orders from 1995 on, P orders sit in the 1995 cut-over window.
   - **Impact**: the label column is descriptive only; the counts do not depend on it.
3. **Output Format**: CSV columns `order_status, status_meaning, order_count, pct_of_orders`; share is a percent of all orders to 2 decimals. The header is lowercased after export (Snowflake returns it uppercase).
   - **Reasoning**: chosen during scoping (code, label, count, share).
   - **Context**: sorted by count, highest first, then status code.
   - **Impact**: none on the numbers.
4. **Scope/Time Window**: all orders in the sample data, no date filter.
   - **Reasoning**: the ticket asks for no window.
   - **Context**: sample data is static.
   - **Impact**: none.

## Deliverables
1. [final_deliverables/1_order_count_by_status_3_records.csv](final_deliverables/1_order_count_by_status_3_records.csv) - order count and share per status. Warehouse target: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (read-only).
2. [final_deliverables/1_order_count_by_status.sql](final_deliverables/1_order_count_by_status.sql) - the query behind it.

| Status | Meaning | Orders | Share |
|---|---|---|---|
| O | Open | 732,044 | 48.80% |
| F | Fulfilled | 729,413 | 48.63% |
| P | Partially shipped | 38,543 | 2.57% |

Total: 1,500,000 orders.

## Quality Control
*The `/review` verdict + pyramid results (counts/dedup, reconciliation, anti-patterns) — from
`qc_queries/<n>_review_verdict.md`. If the ticket shipped unreviewed, this section says so: the
verdict on file is `SKIPPED`, and it names who chose that and when.*

Build-time checks ([qc_queries/1_reconciliation.sql](qc_queries/1_reconciliation.sql)), all passing:
- Sum of status counts 1,500,000 = `ORDERS` rows.
- `O_ORDERKEY` unique: 1,500,000 distinct, so a row is an order.
- 3 output rows = 3 distinct statuses; no duplicates, no NULL status.
- Shares sum to 100.00.
- CSV re-read after export: 3 data rows, header row 1, ASCII only.

Review verdict: APPROVE ([qc_queries/2_review_verdict.md](qc_queries/2_review_verdict.md)); independent-subagent review, sign-off by Kyle Chalmers through the batch pre-approval on 2026-10-28.
