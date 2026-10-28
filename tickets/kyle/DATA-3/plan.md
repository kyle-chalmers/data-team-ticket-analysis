# Plan — DATA-3: Monthly order revenue for 1997

**Confidence (1–10): 9**

## Goal
Give the requester total order revenue for each month of 1997, so they can see how 1997 sales moved month to month.

## Scope
- **In:** `SUM(O_TOTALPRICE)` from `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` for orders with `O_ORDERDATE` in calendar 1997, grouped by order month, with each month's order count. All 12 months are listed.
- **Explicitly out:** line-item revenue (`LINEITEM` price, discount, tax), other years, revenue by status or customer, any write to the warehouse.

## Builds on
- kyle/DATA-2: shares the object `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS`. Reused: its profiling (`O_ORDERKEY` unique, so a row is an order), the CSV export pattern, and the reconciliation-QC layout. The repeat check lists it because both read only `ORDERS`, but it answers a different question (a status count, not monthly revenue), so this is not a repeat.

## Deliverables expected
1. `final_deliverables/1_monthly_order_revenue_1997_12_records.csv` - grain: one row per month of 1997; columns `order_month, order_count, order_revenue` (`order_month` as `YYYY-MM`, revenue to 2 decimals, ASCII only, header row first, explicit `ORDER BY order_month`).
2. `final_deliverables/1_monthly_order_revenue_1997.sql` - the query that produced it, with a `-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` header and the year as a CTE params row.

## Approach
1. Write the monthly roll-up on `ORDERS` with a params CTE holding the year window (`1997-01-01` to `1998-01-01`, end exclusive).
2. Run it read-only on `COMPUTE_EXTRA_SMALL` with `--format csv`, strip any preamble, lowercase the header.
3. Run the QC query (below) and save it in `qc_queries/`.
4. Fill the README with assumptions and QC results.

## Validation strategy (defined BEFORE code)
- **Row reconciliation:** the sum of `order_count` equals the 1997 `ORDERS` row count (227,783 from profiling).
- **Value reconciliation:** the sum of `order_revenue` equals an independent whole-year `SUM(O_TOTALPRICE)` (34,373,633,413.04), to the cent.
- **Duplicates:** 12 output rows, one per month, no repeated `order_month`.
- **Window check:** no 1997 order is dropped at the year edges (first and last order dates are 1997-01-01 and 1997-12-31).
- **Values:** no NULL or non-positive `O_TOTALPRICE` (profiling: 0 of each).
- /review re-runs the queries independently.

## Touched
- **Objects/files:** `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` (read only); new files under `tickets/kyle/DATA-3/`.
- **Tool slots:** tracker (Jira: read the ticket, move to Done on ship), warehouse (Snowflake via `snow` CLI, read only), vcs (GitHub: branch `DATA-3`, PR), docstore (Drive backup on ship).

## Questions for the requester
- Q: Which date puts an order in a month? A: the order date, `O_ORDERDATE` (the only date on `ORDERS`).

## Risks
- `O_TOTALPRICE` is the order total as stored (TPC-H computes it from line items with discount and tax). It is not net revenue after returns; the README says so.
- A date-boundary slip would drop or double a month's orders; the row and value reconciliations to the whole-year totals catch that.

## Next step
- **spec:** not required
- Then `/build kyle/DATA-3` → `/ship kyle/DATA-3` on APPROVE.
