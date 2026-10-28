# Plan — DATA-8: Returned items by ship mode

**Confidence (1–10): 9**

## Goal
Tell the requester how many line items were returned for each ship mode, so they can see whether any ship mode has more returns.

## Scope
- **In:** for each `L_SHIPMODE` in `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM`, the count of line items with `L_RETURNFLAG = 'R'`, the mode's total line items and the returned share. All 7 ship modes.
- **Explicitly out:** returned revenue or quantity, return reasons (TPCH has none), a date window (the ticket names none), any write to the warehouse.

## Builds on
- kyle/DATA-7: shares the object `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM`. Reused: its line-item profiling (grain unique, no NULL ship modes), the per-mode count-and-share query shape and its reconciliation QC.
- This is the 2nd instance of line items meeting a condition, counted and shared by ship mode (after kyle/DATA-7). Only the condition changes (late receipt there, return flag here).

## Deliverables expected
1. `final_deliverables/1_returned_items_by_ship_mode_7_records.csv` - grain: one row per ship mode; columns `ship_mode, line_items, returned_line_items, pct_returned` (percent to 2 decimals, ASCII only, header row first, explicit `ORDER BY returned_line_items DESC, ship_mode`).
2. `final_deliverables/1_returned_items_by_ship_mode.sql` - the query that produced it, with a `-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` header and the flag value as a CTE params row.

## Approach
1. Write the group-by on `LINEITEM` by `L_SHIPMODE`, counting all rows and rows whose `L_RETURNFLAG` equals the params value (`'R'`).
2. Run it read-only on `COMPUTE_EXTRA_SMALL` with `--format csv`, strip any preamble, lowercase the header.
3. Run the QC query (below) and save it in `qc_queries/`.
4. Fill the README with assumptions and QC results.

## Validation strategy (defined BEFORE code)
- **Row reconciliation:** the sum of `line_items` equals `COUNT(*)` of `LINEITEM` (6,001,215).
- **Returned reconciliation:** the sum of `returned_line_items` equals an independent whole-table count of `L_RETURNFLAG = 'R'` (1,478,870).
- **Grain check:** (`L_ORDERKEY`, `L_LINENUMBER`) is unique, so a row is a line item.
- **Duplicates:** 7 output rows = 7 distinct ship modes; no NULL ship mode or return flag.
- **Shares:** each `pct_returned` equals `returned_line_items / line_items` within 0.01.
- /review re-runs the queries independently.

## Touched
- **Objects/files:** `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM` (read only); new files under `tickets/kyle/DATA-8/`.
- **Tool slots:** tracker (Jira: read the ticket, move to Done on ship), warehouse (Snowflake via `snow` CLI, read only), vcs (GitHub: branch `DATA-8`, PR), docstore (Drive backup on ship).

## Questions for the requester
- Q: What share should sit beside the count: of all the mode's line items, or only of items old enough to be returned? A: of all the mode's line items; the README notes that `R` appears only on items received by 1995-06-17.

## Risks
- `L_RETURNFLAG` is `N` for every item received after 1995-06-17, so the share understates the return rate among items that could be returned (about half of those were). The README states both figures.
- The counts per mode differ by under 1,000 (about 0.1 point of share), so there is no meaningful ranking; the README says so.

## Next step
- **spec:** not required
- Then `/build kyle/DATA-8` → `/ship kyle/DATA-8` on APPROVE.
- After /ship: `/skillify line-item condition share by ship mode` (a suggestion, not part of this plan)
