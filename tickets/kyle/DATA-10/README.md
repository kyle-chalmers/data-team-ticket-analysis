# DATA-10: Discount impact on 1996 revenue

## Ticket Information
- **Link:** https://kclabs.atlassian.net/browse/DATA-10
- **Type:** Task
- **Status:** To Do
- **Epic/Parent:** none
- **Assignee:** Kyle Chalmers
- **Warehouse target(s):** SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)

## Business Context
Gross versus discounted line item revenue for 1996 from SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM.

## Investigation Scope
Gross versus discounted line-item revenue for 1996. Object (read-only): `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM` (913,487 line items shipped in 1996). The QC query also reads `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS`, only to count 1996 items by order date for comparison. Reuses the line-item profiling of the earlier ship-mode tickets on this table. See [plan.md](plan.md).

build_mode: inline
subagent_isolation: documented (not used: plan needs no spec)

## Assumptions Made
1. **Business Definition**: gross revenue = `SUM(L_EXTENDEDPRICE)`; discounted revenue = `SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT))`; the discount amount is the difference.
   - **Reasoning**: the ticket asks for gross versus discounted line-item revenue; `L_EXTENDEDPRICE` is quantity times unit price.
   - **Context**: discounts run from 0 to 0.10; no NULL price or discount.
   - **Impact**: tax (`L_TAX`) is left out, so both figures are before tax.
2. **Scope/Time Window**: a line item is in 1996 when its `L_SHIPDATE` is in 1996 (1996-01-01 inclusive to 1997-01-01 exclusive).
   - **Reasoning**: the usual TPC-H convention for line-item revenue; chosen during scoping.
   - **Context**: by order date the year would hold 915,491 items instead of 913,487.
   - **Impact**: the order-date view would move about 2,000 items and about 62M of gross revenue.
3. **Output Format**: one summary row: `ship_year, line_items, gross_revenue, discount_amount, discounted_revenue, discount_pct_of_gross`, 2 decimals. Totals are summed unrounded and rounded once. The header is lowercased after export.
   - **Reasoning**: the ticket asks for one comparison for the year.
   - **Context**: TPCH has no currency field.
   - **Impact**: none on the numbers.

## Deliverables
1. [final_deliverables/1_discount_impact_1996_1_records.csv](final_deliverables/1_discount_impact_1996_1_records.csv) - 1996 gross, discount and discounted revenue. Warehouse target: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (read-only).
2. [final_deliverables/1_discount_impact_1996.sql](final_deliverables/1_discount_impact_1996.sql) - the query behind it.

| Measure | 1996 |
|---|---|
| Line items shipped | 913,487 |
| Gross revenue | 34,966,822,305.99 |
| Discount amount | 1,746,695,120.99 |
| Discounted revenue | 33,220,127,185.00 |
| Discount as % of gross | 5.00% |

Discounts took 1.75B (5.00%) off 1996 gross line-item revenue.

## Quality Control
*The `/review` verdict + pyramid results (counts/dedup, reconciliation, anti-patterns) — from
`qc_queries/<n>_review_verdict.md`. If the ticket shipped unreviewed, this section says so: the
verdict on file is `SKIPPED`, and it names who chose that and when.*

Build-time checks ([qc_queries/1_reconciliation.sql](qc_queries/1_reconciliation.sql)), all passing:
- Gross minus discount equals discounted revenue, to the cent; a second computation agrees within 0.01.
- 913,487 line items, grain unique in the year; ship dates run 1996-01-01 to 1996-12-31.
- No NULL price or discount; all discounts within 0 to 0.10.
- Info: 915,491 items fall in 1996 by order date.
- CSV re-read: 1 data row, header row 1, ASCII only.
