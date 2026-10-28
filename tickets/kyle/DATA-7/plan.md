# Plan — DATA-7: Late shipments by ship mode

**Confidence (1–10): 9**

## Goal
Show the requester what share of line items arrive after their committed date, for each ship mode, so they can see whether any carrier type is less reliable.

## Scope
- **In:** for each `L_SHIPMODE` in `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM`, the number of line items, the number received late (`L_RECEIPTDATE > L_COMMITDATE`) and the late share. All 7 ship modes, all line items.
- **Explicitly out:** how many days late, order-level lateness, a date window (the ticket names none), any write to the warehouse.

## Builds on
None found. Recall returned no matches: no earlier ticket reads `LINEITEM`. The repeat check found no earlier ticket on the same table.

## Deliverables expected
1. `final_deliverables/1_late_shipments_by_ship_mode_7_records.csv` - grain: one row per ship mode; columns `ship_mode, line_items, late_line_items, pct_late` (percent to 2 decimals, ASCII only, header row first, explicit `ORDER BY pct_late DESC, ship_mode`).
2. `final_deliverables/1_late_shipments_by_ship_mode.sql` - the query that produced it, with a `-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` header.

## Approach
1. Write the group-by on `LINEITEM` by `L_SHIPMODE`, counting all rows and rows with `L_RECEIPTDATE > L_COMMITDATE`.
2. Run it read-only on `COMPUTE_EXTRA_SMALL` with `--format csv`, strip any preamble, lowercase the header.
3. Run the QC query (below) and save it in `qc_queries/`.
4. Fill the README with assumptions and QC results.

## Validation strategy (defined BEFORE code)
- **Row reconciliation:** the sum of `line_items` equals `COUNT(*)` of `LINEITEM` (6,001,215).
- **Late reconciliation:** the sum of `late_line_items` equals an independent whole-table count of `L_RECEIPTDATE > L_COMMITDATE` (3,793,296).
- **Grain check:** (`L_ORDERKEY`, `L_LINENUMBER`) is unique (profiling: 6,001,215 distinct), so a row is a line item.
- **Duplicates:** 7 output rows = 7 distinct ship modes; no NULL ship mode, receipt or commit date (profiling: 0).
- **Shares:** each `pct_late` equals `late_line_items / line_items` within 0.01.
- /review re-runs the queries independently.

## Touched
- **Objects/files:** `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM` (read only); new files under `tickets/kyle/DATA-7/`.
- **Tool slots:** tracker (Jira: read the ticket, move to Done on ship), warehouse (Snowflake via `snow` CLI, read only), vcs (GitHub: branch `DATA-7`, PR), docstore (Drive backup on ship).

## Questions for the requester
- Q: Does an item received on its commit date count as late? A: no; late means received strictly after the commit date (`L_RECEIPTDATE > L_COMMITDATE`). About 7,000 items per mode arrive on the day.

## Risks
- Every mode sits at about 63.2% late, a spread of under 0.2 points, so the ranking carries no real signal; the README says the modes perform the same.
- A high late share is a feature of how TPC-H generates dates, not a real carrier problem; the README notes the data is synthetic.

## Next step
- **spec:** not required
- Then `/build kyle/DATA-7` → `/ship kyle/DATA-7` on APPROVE.
