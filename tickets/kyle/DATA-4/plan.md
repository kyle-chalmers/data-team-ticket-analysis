# Plan — DATA-4: Top 10 customers by order revenue

**Confidence (1–10): 9**

## Goal
Show the requester the 10 customers who bring in the most order revenue, and which market segment each belongs to, so they can see who the largest accounts are.

## Scope
- **In:** `SUM(O_TOTALPRICE)` per customer over all orders in `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS`, joined to `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER` for name and `C_MKTSEGMENT`; the top 10 by revenue, with each customer's order count.
- **Explicitly out:** a date window (the ticket names none), line-item revenue, customers outside the top 10, nation or region breakdowns, any write to the warehouse.

## Builds on
- kyle/DATA-3: shares the object `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` and the same revenue definition (`SUM(O_TOTALPRICE)`). Reused: that definition and its reconciliation-QC layout.
- kyle/DATA-2: shares the object `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS`. Reused: its profiling (`O_ORDERKEY` unique) and CSV export pattern.
- The provisional repeat check lists both, but only because `CUSTOMER` is new to the archive; this ticket answers a different question (a customer ranking), so it is not a repeat.

## Deliverables expected
1. `final_deliverables/1_top_customers_by_revenue_10_records.csv` - grain: one row per customer (top 10); columns `rank, customer_key, customer_name, market_segment, order_count, order_revenue` (revenue to 2 decimals, ASCII only, header row first, explicit `ORDER BY order_revenue DESC, customer_key`).
2. `final_deliverables/1_top_customers_by_revenue.sql` - the query that produced it, with a `-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` header and the top-N as a CTE params row.

## Approach
1. Aggregate `ORDERS` to one row per `O_CUSTKEY` (count and revenue), join to `CUSTOMER`, rank by revenue, keep the top N (params CTE, N = 10).
2. Run it read-only on `COMPUTE_EXTRA_SMALL` with `--format csv`, strip any preamble, lowercase the header.
3. Run the QC query (below) and save it in `qc_queries/`.
4. Fill the README with assumptions and QC results.

## Validation strategy (defined BEFORE code)
- **Join check:** every `ORDERS` row matches a `CUSTOMER` row (profiling: 0 orphans), so no revenue is lost in the join; the joined total equals the unjoined `SUM(O_TOTALPRICE)`.
- **Duplicates:** `C_CUSTKEY` is unique in `CUSTOMER` (150,000 rows, 150,000 distinct), so the join cannot fan out; output has 10 distinct customers.
- **Ranking check:** each output customer's revenue equals an independent per-customer sum, and no customer outside the list has more revenue than rank 10 (no tie at the cut-off).
- **Order:** the CSV is strictly descending by revenue.
- /review re-runs the queries independently.

## Touched
- **Objects/files:** `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS`, `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER` (read only); new files under `tickets/kyle/DATA-4/`.
- **Tool slots:** tracker (Jira: read the ticket, move to Done on ship), warehouse (Snowflake via `snow` CLI, read only), vcs (GitHub: branch `DATA-4`, PR), docstore (Drive backup on ship).

## Questions for the requester
- Q: Which time window? A: all orders in the sample data (1992 to 1998); the ticket names no window.

## Risks
- A tie at rank 10 would make the list ambiguous; the QC checks the 11th customer's revenue is strictly lower (profiling: 6,135,483.63 vs 6,125,248.52).
- Customer names in TPCH are synthetic (`Customer#000143500`), so the file carries no real personal data; the README says so.

## Next step
- **spec:** not required
- Then `/build kyle/DATA-4` → `/ship kyle/DATA-4` on APPROVE.
