# Plan — DATA-10: Discount impact on 1996 revenue

**Confidence (1–10): 9**

## Goal
Show the requester how much revenue discounts took off 1996 line-item sales: gross revenue, the discount amount and the revenue after discount.

## Scope
- **In:** for line items in `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM` shipped in 1996, gross revenue `SUM(L_EXTENDEDPRICE)`, discounted revenue `SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT))`, the difference, and the discount as a share of gross. One summary row for the year.
- **Explicitly out:** tax (`L_TAX`), monthly or per-discount-level breakdowns, returns, order-level `O_TOTALPRICE`, any write to the warehouse.

## Builds on
- kyle/DATA-8 and kyle/DATA-7: share the object `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM`. Reused: their line-item profiling (grain unique, no NULL dates) and the reconciliation-QC layout.
- The repeat check lists both because all three read only `LINEITEM`; this ticket answers a different question (a revenue total, not a per-mode share), so it is not a repeat.

## Deliverables expected
1. `final_deliverables/1_discount_impact_1996_1_records.csv` - grain: one row for 1996; columns `ship_year, line_items, gross_revenue, discount_amount, discounted_revenue, discount_pct_of_gross` (2 decimals, ASCII only, header row first, explicit `ORDER BY ship_year`).
2. `final_deliverables/1_discount_impact_1996.sql` - the query that produced it, with a `-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` header and the year window as a CTE params row.

## Approach
1. Write the year roll-up on `LINEITEM` with a params CTE holding the ship-date window (`1996-01-01` to `1997-01-01`, end exclusive).
2. Run it read-only on `COMPUTE_EXTRA_SMALL` with `--format csv`, strip any preamble, lowercase the header.
3. Run the QC query (below) and save it in `qc_queries/`.
4. Fill the README with assumptions and QC results.

## Validation strategy (defined BEFORE code)
- **Identity check:** `gross_revenue - discount_amount = discounted_revenue`, to the cent.
- **Independent sum:** discounted revenue equals a row-by-row sum computed a second way (`SUM(L_EXTENDEDPRICE) - SUM(L_EXTENDEDPRICE * L_DISCOUNT)`), within 0.01.
- **Row count:** `line_items` equals the 1996 ship-date row count (913,487 from profiling), and the grain (`L_ORDERKEY`, `L_LINENUMBER`) is unique in the window.
- **Values:** no NULL price or discount; discounts within 0 to 0.10 (profiling).
- **Window:** first and last ship dates are 1996-01-01 and 1996-12-31.
- /review re-runs the queries independently.

## Touched
- **Objects/files:** `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM` (read only); new files under `tickets/kyle/DATA-10/`.
- **Tool slots:** tracker (Jira: read the ticket, move to Done on ship), warehouse (Snowflake via `snow` CLI, read only), vcs (GitHub: branch `DATA-10`, PR), docstore (Drive backup on ship).

## Questions for the requester
- Q: Which date puts a line item in 1996? A: the ship date (`L_SHIPDATE`), the usual TPC-H line-item revenue convention; by order date the year would hold 915,491 items instead of 913,487.
- Q: Should tax be included? A: no; gross and discounted revenue are before tax.

## Risks
- A different date choice moves about 2,000 items in or out of the year; the README states the ship-date choice and the order-date count.
- Rounding: totals are summed unrounded and rounded once, so the identity check holds to the cent.

## Next step
- **spec:** not required
- Then `/build kyle/DATA-10` → `/ship kyle/DATA-10` on APPROVE.
