# Plan — DATA-6: Average order value by order priority

**Confidence (1–10): 9**

## Goal
Tell the requester the average order total for each order priority, so they can see whether urgent orders are larger or smaller than routine ones.

## Scope
- **In:** `AVG(O_TOTALPRICE)` per `O_ORDERPRIORITY` over all orders in `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS`, with each priority's order count and total revenue. All 5 priorities are listed.
- **Explicitly out:** a date window (the ticket names none), median or other distribution statistics, line-item values, any write to the warehouse.

## Builds on
- kyle/DATA-3: shares the object `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` and the order-total definition (`O_TOTALPRICE`). Reused: the revenue reconciliation in QC.
- kyle/DATA-2: shares the object `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS`. Reused: the one-row-per-category group-by and its dedup and NULL checks.
- The repeat check lists both because all three read only `ORDERS`; the grain and output differ (an average by priority, not a status count or a monthly sum), so this is not a repeat.

## Deliverables expected
1. `final_deliverables/1_avg_order_value_by_priority_5_records.csv` - grain: one row per order priority; columns `order_priority, order_count, total_revenue, avg_order_value` (2 decimals, ASCII only, header row first, explicit `ORDER BY order_priority`).
2. `final_deliverables/1_avg_order_value_by_priority.sql` - the query that produced it, with a `-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` header.

## Approach
1. Write the group-by on `ORDERS` by `O_ORDERPRIORITY` with count, sum and average of `O_TOTALPRICE`.
2. Run it read-only on `COMPUTE_EXTRA_SMALL` with `--format csv`, strip any preamble, lowercase the header.
3. Run the QC query (below) and save it in `qc_queries/`.
4. Fill the README with assumptions and QC results.

## Validation strategy (defined BEFORE code)
- **Row reconciliation:** the sum of `order_count` equals `COUNT(*)` of `ORDERS` (1,500,000).
- **Value reconciliation:** the sum of `total_revenue` equals the whole-table `SUM(O_TOTALPRICE)`, to the cent.
- **Average check:** for each priority, `avg_order_value` equals `total_revenue / order_count` within 0.01.
- **Duplicates:** 5 output rows = 5 distinct priorities; no NULL priority (profiling: 0).
- /review re-runs the queries independently.

## Touched
- **Objects/files:** `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` (read only); new files under `tickets/kyle/DATA-6/`.
- **Tool slots:** tracker (Jira: read the ticket, move to Done on ship), warehouse (Snowflake via `snow` CLI, read only), vcs (GitHub: branch `DATA-6`, PR), docstore (Drive backup on ship).

## Questions for the requester
- Q: Which time window? A: all orders in the sample data (1992 to 1998); the ticket names no window.

## Risks
- The averages sit within about 0.5% of each other (about 150.8K to 151.6K), so the gaps are too small to read as a real effect; the README says so rather than ranking them as a finding.
- Rows sort by the priority code (`1-URGENT` to `5-LOW`), which is the natural order, not by value.

## Next step
- **spec:** not required
- Then `/build kyle/DATA-6` → `/ship kyle/DATA-6` on APPROVE.
