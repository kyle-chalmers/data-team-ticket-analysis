# DATA-12: Europe inventory value by part type

## Ticket Information
- **Link:** https://kclabs.atlassian.net/browse/DATA-12
- **Type:** Task
- **Status:** To Do
- **Epic/Parent:** 
- **Assignee:** leslie
- **Warehouse target(s):** SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 <!-- omit this line when the stack has no warehouse seam -->

## Business Context
For suppliers in Europe, break supplier inventory value (available quantity times supply cost from SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP) out by part type (PART.P_TYPE). Top 15 part types.

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
