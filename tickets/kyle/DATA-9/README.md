# DATA-9: Customer count by nation

## Ticket Information
- **Link:** https://kclabs.atlassian.net/browse/DATA-9
- **Type:** Task
- **Status:** To Do
- **Epic/Parent:** none
- **Assignee:** Kyle Chalmers
- **Warehouse target(s):** SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)

## Business Context
Number of customers per nation. Use SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER and SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION.

## Investigation Scope
Count customers per nation. Objects (read-only): `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER` (150,000 customers) joined to `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION` (25 nations) on the nation key. Reuses the count-and-share shape of the earlier segment count on `CUSTOMER`. See [plan.md](plan.md).

build_mode: inline
subagent_isolation: documented (not used: plan needs no spec)

## Assumptions Made
1. **Data Interpretation**: a customer's nation is `C_NATIONKEY` matched to `NATION.N_NATIONKEY`, reported by `N_NAME`.
   - **Reasoning**: the path named in the ticket.
   - **Context**: no NULL or unmatched `C_NATIONKEY`; `N_NATIONKEY` and `N_NAME` are both unique.
   - **Impact**: every customer lands in exactly one nation.
2. **Status/Population Filter**: every customer record counts, with or without orders.
   - **Reasoning**: the ticket names only `CUSTOMER` and `NATION`.
   - **Context**: same population as the segment count on this table.
   - **Impact**: totals 150,000.
3. **Output Format**: CSV columns `nation_name, customer_count, pct_of_customers`; share to 2 decimals; most customers first, ties by nation name (FRANCE and ROMANIA at 6,100; ARGENTINA and PERU at 5,975). The header is lowercased after export.
   - **Reasoning**: chosen during scoping (name only, no region).
   - **Context**: the rounded shares add to 100.03, not 100.00: each of 25 rows rounds by up to 0.005.
   - **Impact**: none on the counts. The plan's 0.01 tolerance on the share sum was too tight for 25 rows; the QC now allows 0.005 per row and also checks that the unrounded shares sum to exactly 100.

## Deliverables
1. [final_deliverables/1_customer_count_by_nation_25_records.csv](final_deliverables/1_customer_count_by_nation_25_records.csv) - customer count and share per nation. Warehouse target: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (read-only).
2. [final_deliverables/1_customer_count_by_nation.sql](final_deliverables/1_customer_count_by_nation.sql) - the query behind it.

| Nation | Customers | Share |
|---|---|---|
| INDONESIA | 6,161 | 4.11% |
| FRANCE | 6,100 | 4.07% |
| ROMANIA | 6,100 | 4.07% |
| RUSSIA | 6,078 | 4.05% |
| INDIA | 6,042 | 4.03% |
| JORDAN | 6,033 | 4.02% |
| CHINA | 6,024 | 4.02% |
| CANADA | 6,020 | 4.01% |
| UNITED KINGDOM | 6,011 | 4.01% |
| IRAN | 6,009 | 4.01% |
| VIETNAM | 6,008 | 4.01% |
| BRAZIL | 5,999 | 4.00% |
| EGYPT | 5,995 | 4.00% |
| KENYA | 5,992 | 3.99% |
| UNITED STATES | 5,983 | 3.99% |
| ARGENTINA | 5,975 | 3.98% |
| PERU | 5,975 | 3.98% |
| MOZAMBIQUE | 5,974 | 3.98% |
| IRAQ | 5,963 | 3.98% |
| ETHIOPIA | 5,952 | 3.97% |
| JAPAN | 5,948 | 3.97% |
| ALGERIA | 5,925 | 3.95% |
| MOROCCO | 5,921 | 3.95% |
| GERMANY | 5,908 | 3.94% |
| SAUDI ARABIA | 5,904 | 3.94% |

Total: 150,000 customers. Every nation holds about 4%: INDONESIA has the most (6,161) and SAUDI ARABIA the fewest (5,904).

## Quality Control
*The `/review` verdict + pyramid results (counts/dedup, reconciliation, anti-patterns) — from
`qc_queries/<n>_review_verdict.md`. If the ticket shipped unreviewed, this section says so: the
verdict on file is `SKIPPED`, and it names who chose that and when.*

Build-time checks ([qc_queries/1_reconciliation.sql](qc_queries/1_reconciliation.sql)), all passing:
- Nation counts sum to 150,000 = `CUSTOMER` rows; `C_CUSTKEY` unique.
- No NULL or unmatched `C_NATIONKEY`; `N_NATIONKEY` and `N_NAME` unique, so the join cannot fan out.
- 25 output rows = 25 `NATION` rows.
- Rounded shares sum to 100.03 (within the 0.125 rounding bound for 25 rows); unrounded shares sum to exactly 100.
- CSV re-read: 25 data rows, header row 1, ASCII only.
