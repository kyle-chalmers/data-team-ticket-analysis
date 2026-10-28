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
*What this ticket needs, the data sources/objects in play, and the closest prior ticket to mirror.*

## Assumptions Made
*Document every assumption (policy reduce_assumptions). One block each. Common categories:
Business Definition · Status/Population Filter · Data Interpretation (which field means what) ·
Scope/Time Window (as-of dates, ranges) · Methodology · Source Selection · Output Format.*
1. **[Category]**: [assumption]
   - **Reasoning**: [why]
   - **Context**: [what supported it]
   - **Impact**: [how it affects the analysis]

## Deliverables
*Numbered in review order; filenames carry record counts. Note each deliverable's warehouse target —
a `.sql` carries its own `-- warehouse-target:` header, but a CSV cannot (its header must be row 1).
Skip the target notes in a repo with no warehouse seam.*

## Quality Control
*The `/review` verdict + pyramid results (counts/dedup, reconciliation, anti-patterns) — from
`qc_queries/<n>_review_verdict.md`. If the ticket shipped unreviewed, this section says so: the
verdict on file is `SKIPPED`, and it names who chose that and when.*
