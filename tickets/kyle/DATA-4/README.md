# DATA-4: Top 10 customers by order revenue

## Ticket Information
- **Link:** https://kclabs.atlassian.net/browse/DATA-4
- **Type:** Task
- **Status:** To Do
- **Epic/Parent:** none
- **Assignee:** Kyle Chalmers
- **Warehouse target(s):** SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)

## Business Context
Top 10 customers by total order revenue, with their market segment. Use SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS and SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER.

## Investigation Scope
Rank customers by total order revenue and keep the top 10, with market segment. Objects (read-only): `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` (1,500,000 orders from 99,996 customers) and `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER` (150,000 customers). Uses the same revenue definition as the earlier 1997 monthly revenue ticket. See [plan.md](plan.md).

build_mode: inline
subagent_isolation: documented (not used: plan needs no spec)

## Assumptions Made
1. **Business Definition**: a customer's order revenue = `SUM(O_TOTALPRICE)` over all of their orders.
   - **Reasoning**: the ticket asks for total order revenue; `O_TOTALPRICE` is the order total.
   - **Context**: every order matches a customer (0 orphans); `C_CUSTKEY` is unique, so the join cannot double count.
   - **Impact**: gross order value, not net of returns.
2. **Scope/Time Window**: all orders in the sample data (1992 to 1998), no date filter.
   - **Reasoning**: the ticket names no window; chosen during scoping.
   - **Context**: sample data is static.
   - **Impact**: a single-year ranking could differ.
3. **Data Interpretation**: market segment is `CUSTOMER.C_MKTSEGMENT`.
   - **Reasoning**: the only segment field in TPCH.
   - **Context**: no NULL segments.
   - **Impact**: none.
4. **Output Format**: CSV columns `rank, customer_key, customer_name, market_segment, order_count, order_revenue`; revenue to 2 decimals, highest first. Ties would share a rank; there is no tie at the cut-off (rank 10 at 6,135,483.63, rank 11 at 6,125,248.52). The header is lowercased after export.
   - **Reasoning**: key plus name lets the reader look a customer up.
   - **Context**: TPCH customer names are synthetic (`Customer#000143500`), so the file holds no real personal data.
   - **Impact**: none on the numbers.

## Deliverables
1. [final_deliverables/1_top_customers_by_revenue_10_records.csv](final_deliverables/1_top_customers_by_revenue_10_records.csv) - top 10 customers by order revenue, with segment. Warehouse target: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (read-only).
2. [final_deliverables/1_top_customers_by_revenue.sql](final_deliverables/1_top_customers_by_revenue.sql) - the query behind it.

| Rank | Customer | Segment | Orders | Revenue |
|---|---|---|---|---|
| 1 | Customer#000143500 | FURNITURE | 39 | 7,012,696.48 |
| 2 | Customer#000095257 | HOUSEHOLD | 36 | 6,563,511.23 |
| 3 | Customer#000087115 | AUTOMOBILE | 34 | 6,457,526.26 |
| 4 | Customer#000131113 | BUILDING | 37 | 6,311,428.86 |
| 5 | Customer#000103834 | MACHINERY | 31 | 6,306,524.23 |
| 6 | Customer#000134380 | FURNITURE | 37 | 6,291,610.15 |
| 7 | Customer#000069682 | AUTOMOBILE | 39 | 6,287,149.42 |
| 8 | Customer#000102022 | AUTOMOBILE | 41 | 6,273,788.41 |
| 9 | Customer#000098587 | BUILDING | 37 | 6,265,089.35 |
| 10 | Customer#000085102 | AUTOMOBILE | 34 | 6,135,483.63 |

The top 10 bring in 63,904,808.02 together. AUTOMOBILE holds 4 of the 10 places; every one of the 5 segments appears.

## Quality Control
*The `/review` verdict + pyramid results (counts/dedup, reconciliation, anti-patterns) — from
`qc_queries/<n>_review_verdict.md`. If the ticket shipped unreviewed, this section says so: the
verdict on file is `SKIPPED`, and it names who chose that and when.*

Build-time checks ([qc_queries/1_reconciliation.sql](qc_queries/1_reconciliation.sql)), all passing:
- `C_CUSTKEY` unique (150,000); no order without a customer.
- Joined revenue 226,829,306,447.46 = `ORDERS` revenue, to the cent.
- No tie at the cut-off: rank 10 (6,135,483.63) is above rank 11 (6,125,248.52).
- CSV re-read: 10 data rows, strictly descending, total 63,904,808.02 = independent top-10 sum; header row 1, ASCII only.

Review verdict: APPROVE ([qc_queries/2_review_verdict.md](qc_queries/2_review_verdict.md)); independent-subagent review, sign-off by Kyle Chalmers through the batch pre-approval on 2026-10-28.
