# DATA-7: Late shipments by ship mode

## Ticket Information
- **Link:** https://kclabs.atlassian.net/browse/DATA-7
- **Type:** Task
- **Status:** To Do
- **Epic/Parent:** none
- **Assignee:** Kyle Chalmers
- **Warehouse target(s):** SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)

## Business Context
Share of line items received after their commit date, by ship mode. Use SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM.

## Investigation Scope
Share of line items received after their commit date, per ship mode. Object (read-only): `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM` (6,001,215 line items, one row per order and line number). No prior tickets to reuse (first ticket on `LINEITEM`). See [plan.md](plan.md).

build_mode: inline
subagent_isolation: documented (not used: plan needs no spec)

## Assumptions Made
1. **Business Definition**: a line item is late when `L_RECEIPTDATE > L_COMMITDATE`.
   - **Reasoning**: the ticket asks for items received after their commit date; chosen during scoping.
   - **Context**: about 7,000 items per mode are received on the commit date itself; they count as not late.
   - **Impact**: counting same-day receipt as late would add about 1 point per mode.
2. **Data Interpretation**: ship mode is `L_SHIPMODE`; one `LINEITEM` row is one line item.
   - **Reasoning**: (`L_ORDERKEY`, `L_LINENUMBER`) is unique (6,001,215 distinct); no NULL ship modes or dates.
   - **Context**: 7 ship modes exist.
   - **Impact**: none.
3. **Scope/Time Window**: all line items (shipped 1992-01-02 onward, received up to 1998-12-31), no date filter.
   - **Reasoning**: the ticket names no window.
   - **Context**: sample data is static.
   - **Impact**: none.
4. **Output Format**: CSV columns `ship_mode, line_items, late_line_items, pct_late`; percent to 2 decimals, highest late share first, then ship mode. The header is lowercased after export.
   - **Reasoning**: counts let the reader check each share.
   - **Context**: TPC-H dates are synthetic, so the high late share reflects how the data was generated, not real carriers.
   - **Impact**: none on the numbers.

## Deliverables
1. [final_deliverables/1_late_shipments_by_ship_mode_7_records.csv](final_deliverables/1_late_shipments_by_ship_mode_7_records.csv) - late share per ship mode. Warehouse target: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (read-only).
2. [final_deliverables/1_late_shipments_by_ship_mode.sql](final_deliverables/1_late_shipments_by_ship_mode.sql) - the query behind it.

| Ship mode | Line items | Late | % late |
|---|---|---|---|
| MAIL | 857,401 | 542,960 | 63.33% |
| TRUCK | 856,998 | 541,782 | 63.22% |
| AIR | 858,104 | 542,360 | 63.20% |
| REG AIR | 856,868 | 541,420 | 63.19% |
| FOB | 857,324 | 541,670 | 63.18% |
| SHIP | 858,036 | 542,145 | 63.18% |
| RAIL | 856,484 | 540,959 | 63.16% |

Overall 3,793,296 of 6,001,215 line items (63.21%) arrived after their commit date. The modes are within 0.17 points of each other, so no ship mode is meaningfully less reliable.

## Quality Control
*The `/review` verdict + pyramid results (counts/dedup, reconciliation, anti-patterns) — from
`qc_queries/<n>_review_verdict.md`. If the ticket shipped unreviewed, this section says so: the
verdict on file is `SKIPPED`, and it names who chose that and when.*

Build-time checks ([qc_queries/1_reconciliation.sql](qc_queries/1_reconciliation.sql)), all passing:
- Mode counts sum to 6,001,215 = `LINEITEM` rows; line-item grain unique.
- Late counts sum to 3,793,296 = independent whole-table late count.
- 7 output rows = 7 distinct ship modes; no NULL mode, receipt or commit date.
- Every `pct_late` equals late / items within 0.01.
- CSV re-read: 7 data rows, header row 1, ASCII only.
