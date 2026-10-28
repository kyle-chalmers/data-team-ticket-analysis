# Plan — DATA-11: Orders per clerk for 1995

**Confidence (1–10): 9**

## Goal
Show the requester the 20 clerks who handled the most orders in 1995, so they can see who carried the heaviest order load.

## Scope
- **In:** a count of `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` rows per `O_CLERK` for orders with `O_ORDERDATE` in calendar 1995; the top 20 by count.
- **Explicitly out:** clerks outside the top 20, order revenue per clerk, other years, any write to the warehouse.

## Builds on
- kyle/DATA-3: shares the object `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS`. Reused: its calendar-year window on `O_ORDERDATE` as a params CTE and the whole-year row reconciliation.
- kyle/DATA-2: shares the object `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS`. Reused: its profiling (`O_ORDERKEY` unique, so a row is an order).
- The repeat check lists these and kyle/DATA-6 because all read only `ORDERS`; this ticket answers a different question (a top-N of clerks), so it is not a repeat.

## Deliverables expected
1. `final_deliverables/1_orders_per_clerk_1995_20_records.csv` - grain: one row per clerk (top 20); columns `rank, clerk, order_count` (ASCII only, header row first, explicit `ORDER BY order_count DESC, clerk`).
2. `final_deliverables/1_orders_per_clerk_1995.sql` - the query that produced it, with a `-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` header and the year window and top-N as a CTE params row.

## Approach
1. Count 1995 orders per `O_CLERK`, rank by count, keep the top N (params CTE: window `1995-01-01` to `1996-01-01`, N = 20).
2. Run it read-only on `COMPUTE_EXTRA_SMALL` with `--format csv`, strip any preamble, lowercase the header.
3. Run the QC query (below) and save it in `qc_queries/`.
4. Fill the README with assumptions and QC results.

## Validation strategy (defined BEFORE code)
- **Row reconciliation:** the per-clerk counts over all clerks sum to the 1995 `ORDERS` row count (228,637 from profiling).
- **Grain check:** `O_ORDERKEY` is unique in 1995, so a row is an order; no NULL `O_CLERK`.
- **Duplicates:** 20 output rows, 20 distinct clerks.
- **Ranking check:** no tie at the cut-off: the 20th clerk's count is strictly above the 21st's (profiling: 258 vs 257).
- **Order:** the CSV is non-increasing by count, ties by clerk.
- /review re-runs the queries independently.

## Touched
- **Objects/files:** `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` (read only); new files under `tickets/kyle/DATA-11/`.
- **Tool slots:** tracker (Jira: read the ticket, move to Done on ship), warehouse (Snowflake via `snow` CLI, read only), vcs (GitHub: branch `DATA-11`, PR), docstore (Drive backup on ship).

## Questions for the requester
- Q: How should tied clerks be ranked? A: tied clerks share a rank (`RANK()`), listed by clerk id; there is no tie at the 20th place, so exactly 20 rows come back.

## Risks
- Counts are tightly bunched (about 1,000 clerks, top 20 between 258 and 277), so several clerks share ranks; the README lists the ties.
- Clerk ids are synthetic (`Clerk#000000185`), so the file holds no real personal data.

## Next step
- **spec:** not required
- Then `/build kyle/DATA-11` → `/ship kyle/DATA-11` on APPROVE.
