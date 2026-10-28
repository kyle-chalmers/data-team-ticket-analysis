-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-5 QC: layers 2-3 (counts, dedup, reconciliation). Every row should read pass = TRUE.
WITH out AS (
    SELECT C_MKTSEGMENT AS market_segment, COUNT(*) AS customer_count,
           ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER GROUP BY C_MKTSEGMENT
),
src AS (
    SELECT COUNT(*) AS n, COUNT(DISTINCT C_CUSTKEY) AS d, COUNT(DISTINCT C_MKTSEGMENT) AS n_seg,
           COUNT_IF(C_MKTSEGMENT IS NULL) AS n_null
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER
)
SELECT 'sum of segment counts = CUSTOMER rows' AS check_name, s.n AS expected, (SELECT SUM(customer_count) FROM out) AS actual, s.n = (SELECT SUM(customer_count) FROM out) AS pass FROM src s
UNION ALL SELECT 'C_CUSTKEY unique (row = customer)', s.n, s.d, s.n = s.d FROM src s
UNION ALL SELECT 'output rows = distinct segments (no duplicates)', s.n_seg, (SELECT COUNT(*) FROM out), s.n_seg = (SELECT COUNT(*) FROM out) FROM src s
UNION ALL SELECT 'no NULL segment', 0, s.n_null, s.n_null = 0 FROM src s
UNION ALL SELECT 'shares sum to 100 within 0.01', 100, (SELECT SUM(pct_of_customers) FROM out), ABS((SELECT SUM(pct_of_customers) FROM out) - 100) <= 0.01 FROM src s
UNION ALL SELECT 'info: customers with no orders', NULL, (SELECT COUNT(*) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER c WHERE NOT EXISTS (SELECT 1 FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS o WHERE o.O_CUSTKEY = c.C_CUSTKEY)), NULL FROM src s
ORDER BY check_name;
