# DATA-5: Customer count by market segment

## Ticket Information
- **Link:** https://kclabs.atlassian.net/browse/DATA-5
- **Type:** Task
- **Status:** To Do
- **Epic/Parent:** none
- **Assignee:** Kyle Chalmers
- **Warehouse target(s):** SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)

## Business Context
How many customers are in each market segment? Use SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER.

## Investigation Scope
Count customers per market segment. Object (read-only): `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER` (150,000 customers, one row per `C_CUSTKEY`). The QC query also reads `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS`, only to count customers with no orders. Reuses the customer profiling from the earlier top-customers ticket. See [plan.md](plan.md).

build_mode: inline
subagent_isolation: documented (not used: plan needs no spec)

## Assumptions Made
1. **Status/Population Filter**: every customer record counts, whether or not it has orders.
   - **Reasoning**: the ticket names only `CUSTOMER`; chosen during scoping.
   - **Context**: 50,004 of the 150,000 customers (33.3%) have no orders.
   - **Impact**: counting only buyers would give 99,996 customers in total.
2. **Data Interpretation**: market segment is `C_MKTSEGMENT`; one `CUSTOMER` row is one customer.
   - **Reasoning**: `C_CUSTKEY` is unique (150,000 distinct); no NULL segments.
   - **Context**: 5 segments exist.
   - **Impact**: none.
3. **Output Format**: CSV columns `market_segment, customer_count, pct_of_customers`; share is a percent of all customers to 2 decimals, largest segment first. The header is lowercased after export.
   - **Reasoning**: count plus share shows the split at a glance.
   - **Context**: segments are within 0.3 points of an even 20% each.
   - **Impact**: none on the numbers.

## Deliverables
1. [final_deliverables/1_customer_count_by_segment_5_records.csv](final_deliverables/1_customer_count_by_segment_5_records.csv) - customer count and share per segment. Warehouse target: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (read-only).
2. [final_deliverables/1_customer_count_by_segment.sql](final_deliverables/1_customer_count_by_segment.sql) - the query behind it.

| Segment | Customers | Share |
|---|---|---|
| HOUSEHOLD | 30,189 | 20.13% |
| BUILDING | 30,142 | 20.09% |
| FURNITURE | 29,968 | 19.98% |
| MACHINERY | 29,949 | 19.97% |
| AUTOMOBILE | 29,752 | 19.83% |

Total: 150,000 customers. The split is close to even.

## Quality Control
*The `/review` verdict + pyramid results (counts/dedup, reconciliation, anti-patterns) — from
`qc_queries/<n>_review_verdict.md`. If the ticket shipped unreviewed, this section says so: the
verdict on file is `SKIPPED`, and it names who chose that and when.*

Build-time checks ([qc_queries/1_reconciliation.sql](qc_queries/1_reconciliation.sql)), all passing:
- Segment counts sum to 150,000 = `CUSTOMER` rows; `C_CUSTKEY` unique.
- 5 output rows = 5 distinct segments; no NULL segment.
- Shares sum to 100.00.
- Info: 50,004 customers have no orders (counted, per assumption 1).
- CSV re-read: 5 data rows, header row 1, ASCII only.
