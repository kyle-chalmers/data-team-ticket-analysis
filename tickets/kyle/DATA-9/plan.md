# Plan — DATA-9: Customer count by nation

**Confidence (1–10): 9**

## Goal
Tell the requester how many customers are based in each nation, so they can see where the customer base sits.

## Scope
- **In:** a count of `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER` rows per nation, via `C_NATIONKEY` to `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION.N_NAME`, with each nation's share of all customers. All 25 nations are listed, including any with no customers.
- **Explicitly out:** region roll-up, whether customers have ordered, revenue by nation, any write to the warehouse.

## Builds on
- kyle/DATA-5: shares the object `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER`. Reused: its customer profiling (`C_CUSTKEY` unique) and the count-and-share query shape with its QC.
- kyle/DATA-1: shares the object `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION`. Reused: the nation join key (`N_NATIONKEY`) and its finding that `NATION` has 25 unique rows.

## Deliverables expected
1. `final_deliverables/1_customer_count_by_nation_25_records.csv` - grain: one row per nation; columns `nation_name, customer_count, pct_of_customers` (ASCII only, header row first, explicit `ORDER BY customer_count DESC, nation_name`).
2. `final_deliverables/1_customer_count_by_nation.sql` - the query that produced it, with a `-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` header.

## Approach
1. Write `NATION` left-joined to `CUSTOMER` on the nation key, grouped by nation, with the share as a percent to 2 decimals.
2. Run it read-only on `COMPUTE_EXTRA_SMALL` with `--format csv`, strip any preamble, lowercase the header.
3. Run the QC query (below) and save it in `qc_queries/`.
4. Fill the README with assumptions and QC results.

## Validation strategy (defined BEFORE code)
- **Row reconciliation:** the sum of `customer_count` equals `COUNT(*)` of `CUSTOMER` (150,000), so no customer is dropped by the join.
- **Join check:** no customer has a NULL or unmatched `C_NATIONKEY` (profiling: 0 and 0).
- **Duplicates:** `N_NATIONKEY` is unique (25 rows, 25 distinct), so the join cannot fan out; 25 output rows, no repeated nation.
- **Shares:** `pct_of_customers` sums to 100 within rounding (0.01).
- /review re-runs the queries independently.

## Touched
- **Objects/files:** `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER`, `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION` (read only); new files under `tickets/kyle/DATA-9/`.
- **Tool slots:** tracker (Jira: read the ticket, move to Done on ship), warehouse (Snowflake via `snow` CLI, read only), vcs (GitHub: branch `DATA-9`, PR), docstore (Drive backup on ship).

## Questions for the requester
- Q: List nations by name only, or with their region too? A: by name only; the ticket asks per nation.

## Risks
- Nations sit between about 5,900 and 6,160 customers, and two pairs tie (6,100 and 5,975); ties sort by nation name so re-runs are byte-identical.
- The left join keeps a nation with no customers at 0; none exist today, and the QC counts output rows against `NATION`.

## Next step
- **spec:** not required
- Then `/build kyle/DATA-9` → `/ship kyle/DATA-9` on APPROVE.
