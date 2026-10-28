# Plan — DATA-5: Customer count by market segment

**Confidence (1–10): 9**

## Goal
Tell the requester how many customers sit in each market segment, so they can see how the customer base splits across segments.

## Scope
- **In:** a count of `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER` rows per `C_MKTSEGMENT`, with each segment's share of all customers. All 5 segments are listed.
- **Explicitly out:** whether a customer has ordered (counted separately in the README only), revenue by segment, nation or region breakdowns, any write to the warehouse.

## Builds on
- kyle/DATA-4: shares the object `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER`. Reused: its profiling (`C_CUSTKEY` unique, no NULL `C_MKTSEGMENT`) and the segment field.

## Deliverables expected
1. `final_deliverables/1_customer_count_by_segment_5_records.csv` - grain: one row per market segment; columns `market_segment, customer_count, pct_of_customers` (ASCII only, header row first, explicit `ORDER BY customer_count DESC, market_segment`).
2. `final_deliverables/1_customer_count_by_segment.sql` - the query that produced it, with a `-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` header.

## Approach
1. Write the group-by on `CUSTOMER`, with the share as a percent to 2 decimals.
2. Run it read-only on `COMPUTE_EXTRA_SMALL` with `--format csv`, strip any preamble, lowercase the header.
3. Run the QC query (below) and save it in `qc_queries/`.
4. Fill the README with assumptions and QC results.

## Validation strategy (defined BEFORE code)
- **Row reconciliation:** the sum of `customer_count` equals `COUNT(*)` of `CUSTOMER` (150,000).
- **Grain check:** `C_CUSTKEY` is unique (150,000 distinct), so a row count is a customer count.
- **Duplicates:** each segment appears once; output rows equal `COUNT(DISTINCT C_MKTSEGMENT)` (5).
- **NULLs:** no NULL segment (profiling: 0).
- **Shares:** `pct_of_customers` sums to 100 within rounding (0.01).
- /review re-runs the queries independently.

## Touched
- **Objects/files:** `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER` (read only); new files under `tickets/kyle/DATA-5/`.
- **Tool slots:** tracker (Jira: read the ticket, move to Done on ship), warehouse (Snowflake via `snow` CLI, read only), vcs (GitHub: branch `DATA-5`, PR), docstore (Drive backup on ship).

## Questions for the requester
- Q: Count every customer record, or only customers who have ordered? A: every customer record in `CUSTOMER` (150,000); the 50,004 with no orders are noted in the README, not excluded.

## Risks
- The segments are nearly equal (about 19.8% to 20.1%), so the order of the rows rests on small gaps; the counts are exact, and shares are checked to sum to 100.
- A reader may expect "customers" to mean buyers; the README states that a third of customers have no orders.

## Next step
- **spec:** not required
- Then `/build kyle/DATA-5` → `/ship kyle/DATA-5` on APPROVE.
