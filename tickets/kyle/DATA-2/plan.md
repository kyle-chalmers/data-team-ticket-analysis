# Plan — DATA-2: Order count by order status

**Confidence (1–10): 9**

## Goal
Tell the requester how many orders sit in each order status, so they can see how the order book splits between finished, open and partly shipped orders.

## Scope
- **In:** a count of `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` rows per `O_ORDERSTATUS`, with each status's share of all orders. Every status present (3 today: F, O, P) is listed.
- **Explicitly out:** line-item level status (`L_LINESTATUS`), trends over time, revenue by status, any write to the warehouse.

## Builds on
None found. Recall returned no matches: the only prior ticket, kyle/DATA-1, reads PARTSUPP, SUPPLIER, NATION and REGION, none of which this ticket uses. The repeat check found no earlier ticket on `ORDERS`.

## Deliverables expected
1. `final_deliverables/1_order_count_by_status_3_records.csv` - grain: one row per order status; columns `order_status, status_meaning, order_count, pct_of_orders` (ASCII only, header row first, explicit `ORDER BY order_count DESC, order_status`).
2. `final_deliverables/1_order_count_by_status.sql` - the query that produced it, with a `-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` header.

## Approach
1. Write the group-by query on `ORDERS`, with a CASE label per status code and the share as a percent to 2 decimals.
2. Run it read-only on `COMPUTE_EXTRA_SMALL` with `--format csv`, strip any preamble, lowercase the header.
3. Run the QC query (below) and save it in `qc_queries/`.
4. Fill the README with assumptions and QC results.

## Validation strategy (defined BEFORE code)
- **Row reconciliation:** the sum of `order_count` equals `COUNT(*)` of `ORDERS` (1,500,000 from profiling).
- **Duplicates:** each status appears once; output rows equal `COUNT(DISTINCT O_ORDERSTATUS)` (3).
- **Grain check:** `O_ORDERKEY` is unique (profiling: 1,500,000 rows, 1,500,000 distinct), so a row count is an order count.
- **NULLs:** no NULL status (profiling: 0), so no order falls out of the grouping.
- **Shares:** `pct_of_orders` sums to 100 within rounding (0.01).
- /review re-runs the queries independently.

## Touched
- **Objects/files:** `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` (read only); new files under `tickets/kyle/DATA-2/`.
- **Tool slots:** tracker (Jira: read the ticket, move to Done on ship), warehouse (Snowflake via `snow` CLI, read only), vcs (GitHub: branch `DATA-2`, PR), docstore (Drive backup on ship).

## Questions for the requester
- Q: Which columns should the CSV carry? A: the status code, a plain label, the count and the share of all orders (`order_status, status_meaning, order_count, pct_of_orders`).

## Risks
- The status codes have no lookup table in TPCH. The labels (F = fulfilled, O = open, P = partially shipped) come from the TPC-H spec definition, where status follows the line items' `L_LINESTATUS`; the README states this so the reader can check it.
- P is small (about 2.6%), so a rounding slip would be visible in the share; the shares are checked to sum to 100.

## Next step
- **spec:** not required
- Then `/build kyle/DATA-2` → `/ship kyle/DATA-2` on APPROVE.
