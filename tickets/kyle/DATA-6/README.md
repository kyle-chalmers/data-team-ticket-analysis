# DATA-6: Average order value by order priority

## Ticket Information
- **Link:** https://kclabs.atlassian.net/browse/DATA-6
- **Type:** Task
- **Status:** Done
- **Epic/Parent:** none
- **Assignee:** Kyle Chalmers
- **Warehouse target(s):** SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)

## Business Context
Average order total by order priority from SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS.

## Investigation Scope
Average order total per order priority. Object (read-only): `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` (1,500,000 orders, one row per `O_ORDERKEY`). Uses the same order-total definition as the earlier revenue tickets on this table. See [plan.md](plan.md).

build_mode: inline
subagent_isolation: documented (not used: plan needs no spec)

## Assumptions Made
1. **Business Definition**: average order value = `AVG(O_TOTALPRICE)`, the mean order total per priority.
   - **Reasoning**: the ticket asks for the average order total.
   - **Context**: no NULL or non-positive `O_TOTALPRICE`; each priority holds about 300,000 orders.
   - **Impact**: a mean, so a few very large orders pull it up; the median is not reported.
2. **Scope/Time Window**: all orders in the sample data (1992 to 1998), no date filter.
   - **Reasoning**: the ticket names no window; chosen during scoping.
   - **Context**: sample data is static.
   - **Impact**: none.
3. **Data Interpretation**: priority is `O_ORDERPRIORITY` as stored (`1-URGENT` to `5-LOW`, including `4-NOT SPECIFIED`).
   - **Reasoning**: the only priority field; no NULLs.
   - **Context**: the code prefix gives the natural order.
   - **Impact**: rows sort by priority code, not by value.
4. **Output Format**: CSV columns `order_priority, order_count, total_revenue, avg_order_value`, 2 decimals. The header is lowercased after export.
   - **Reasoning**: count and total let the reader check each average.
   - **Context**: TPCH has no currency field.
   - **Impact**: none on the numbers.

## Deliverables
1. [final_deliverables/1_avg_order_value_by_priority_5_records.csv](final_deliverables/1_avg_order_value_by_priority_5_records.csv) - average order value per priority. Warehouse target: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (read-only).
2. [final_deliverables/1_avg_order_value_by_priority.sql](final_deliverables/1_avg_order_value_by_priority.sql) - the query behind it.

| Priority | Orders | Total revenue | Avg order value |
|---|---|---|---|
| 1-URGENT | 300,343 | 45,418,729,437.08 | 151,222.87 |
| 2-HIGH | 300,091 | 45,479,776,243.03 | 151,553.28 |
| 3-MEDIUM | 298,723 | 45,153,608,088.46 | 151,155.45 |
| 4-NOT SPECIFIED | 300,254 | 45,276,033,983.10 | 150,792.44 |
| 5-LOW | 300,589 | 45,501,158,695.79 | 151,373.33 |

The averages differ by about 0.5% at most (2-HIGH highest, 4-NOT SPECIFIED lowest), so priority makes no real difference to order size in this data. Overall average: 151,219.54.

## Quality Control
*The `/review` verdict + pyramid results (counts/dedup, reconciliation, anti-patterns) — from
`qc_queries/<n>_review_verdict.md`. If the ticket shipped unreviewed, this section says so: the
verdict on file is `SKIPPED`, and it names who chose that and when.*

Build-time checks ([qc_queries/1_reconciliation.sql](qc_queries/1_reconciliation.sql)), all passing:
- Priority counts sum to 1,500,000 = `ORDERS` rows.
- Priority revenue sums to 226,829,306,447.46 = whole-table revenue, to the cent.
- Every average equals revenue / count within 0.01.
- 5 output rows = 5 distinct priorities; no NULL priority.
- CSV re-read: 5 data rows, header row 1, ASCII only.

Review verdict: APPROVE ([qc_queries/2_review_verdict.md](qc_queries/2_review_verdict.md)); independent-subagent review, sign-off by Kyle Chalmers through the batch pre-approval on 2026-10-28.
