# DATA-3: Monthly order revenue for 1997

## Ticket Information
- **Link:** https://kclabs.atlassian.net/browse/DATA-3
- **Type:** Task
- **Status:** To Do
- **Epic/Parent:** none
- **Assignee:** Kyle Chalmers
- **Warehouse target(s):** SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)

## Business Context
Total order revenue by month for 1997 from SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS (O_TOTALPRICE).

## Investigation Scope
Monthly order revenue for calendar 1997. Object (read-only): `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` (227,783 orders dated in 1997, one row per `O_ORDERKEY`). Reuses the export and QC pattern of the earlier order-status count on the same table. See [plan.md](plan.md).

build_mode: inline
subagent_isolation: documented (not used: plan needs no spec)

## Assumptions Made
1. **Business Definition**: order revenue = `SUM(O_TOTALPRICE)`, the order total as stored.
   - **Reasoning**: the ticket names `O_TOTALPRICE`.
   - **Context**: TPC-H builds `O_TOTALPRICE` from the order's line items with discount and tax applied; no NULL or non-positive values exist in 1997.
   - **Impact**: this is gross order value at order time, not net of returns.
2. **Scope/Time Window**: an order belongs to the month of its `O_ORDERDATE`; the window is 1997-01-01 (inclusive) to 1998-01-01 (exclusive).
   - **Reasoning**: `O_ORDERDATE` is the only date on `ORDERS`; chosen during scoping.
   - **Context**: 1997 orders run from 1997-01-01 to 1997-12-31.
   - **Impact**: ship or receipt dates (on `LINEITEM`) would shift some revenue between months; they are not used.
3. **Output Format**: CSV columns `order_month, order_count, order_revenue`; month as `YYYY-MM`, revenue to 2 decimals, sorted by month. The header is lowercased after export (Snowflake returns it uppercase).
   - **Reasoning**: one row per month reads as a time series.
   - **Context**: TPCH has no currency field, so revenue is unitless.
   - **Impact**: none on the numbers.

## Deliverables
1. [final_deliverables/1_monthly_order_revenue_1997_12_records.csv](final_deliverables/1_monthly_order_revenue_1997_12_records.csv) - order count and revenue per month of 1997. Warehouse target: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (read-only).
2. [final_deliverables/1_monthly_order_revenue_1997.sql](final_deliverables/1_monthly_order_revenue_1997.sql) - the query behind it.

| Month | Orders | Revenue |
|---|---|---|
| 1997-01 | 19,148 | 2,894,774,512.52 |
| 1997-02 | 17,584 | 2,666,400,698.43 |
| 1997-03 | 19,052 | 2,871,589,959.01 |
| 1997-04 | 18,864 | 2,870,520,226.05 |
| 1997-05 | 19,519 | 2,954,859,129.31 |
| 1997-06 | 18,951 | 2,848,808,520.47 |
| 1997-07 | 19,431 | 2,926,926,018.56 |
| 1997-08 | 19,330 | 2,905,509,503.14 |
| 1997-09 | 18,598 | 2,823,931,892.91 |
| 1997-10 | 19,337 | 2,913,895,092.65 |
| 1997-11 | 18,519 | 2,776,607,117.39 |
| 1997-12 | 19,450 | 2,919,810,742.60 |

Total 1997: 227,783 orders, 34,373,633,413.04 revenue. May is the highest month and February the lowest (it has the fewest days).

## Quality Control
*The `/review` verdict + pyramid results (counts/dedup, reconciliation, anti-patterns) — from
`qc_queries/<n>_review_verdict.md`. If the ticket shipped unreviewed, this section says so: the
verdict on file is `SKIPPED`, and it names who chose that and when.*

Build-time checks ([qc_queries/1_reconciliation.sql](qc_queries/1_reconciliation.sql)), all passing:
- Monthly counts sum to 227,783 = 1997 `ORDERS` rows; `O_ORDERKEY` unique.
- Monthly revenue sums to 34,373,633,413.04 = independent whole-year sum, to the cent.
- 12 output months, no duplicates; no NULL or non-positive `O_TOTALPRICE`.
- CSV re-read after export: 12 data rows, header row 1, ASCII only.
