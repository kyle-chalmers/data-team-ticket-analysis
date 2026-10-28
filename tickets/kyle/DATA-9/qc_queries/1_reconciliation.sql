-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-9 QC: layers 2-3 (join, dedup, reconciliation). Every row should read pass = TRUE.
WITH out AS (
    SELECT n.N_NAME AS nation_name, COUNT(c.C_CUSTKEY) AS customer_count,
           ROUND(100 * COUNT(c.C_CUSTKEY) / NULLIF(SUM(COUNT(c.C_CUSTKEY)) OVER (), 0), 2) AS pct_of_customers
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION n
    LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER c ON c.C_NATIONKEY = n.N_NATIONKEY
    GROUP BY n.N_NAME
),
cust AS (
    SELECT COUNT(*) AS n, COUNT(DISTINCT C_CUSTKEY) AS d, COUNT_IF(C_NATIONKEY IS NULL) AS n_null,
           COUNT_IF(C_NATIONKEY NOT IN (SELECT N_NATIONKEY FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION)) AS n_unmatched
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER
),
nat AS (SELECT COUNT(*) AS n, COUNT(DISTINCT N_NATIONKEY) AS d, COUNT(DISTINCT N_NAME) AS d_name FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION)
SELECT 'sum of nation counts = CUSTOMER rows' AS check_name, c.n AS expected, (SELECT SUM(customer_count) FROM out) AS actual, c.n = (SELECT SUM(customer_count) FROM out) AS pass FROM cust c
UNION ALL SELECT 'C_CUSTKEY unique (row = customer)', c.n, c.d, c.n = c.d FROM cust c
UNION ALL SELECT 'no NULL or unmatched C_NATIONKEY', 0, c.n_null + c.n_unmatched, c.n_null + c.n_unmatched = 0 FROM cust c
UNION ALL SELECT 'N_NATIONKEY and N_NAME unique (join cannot fan out)', n.n, LEAST(n.d, n.d_name), n.n = n.d AND n.n = n.d_name FROM nat n
UNION ALL SELECT 'output rows = NATION rows', n.n, (SELECT COUNT(*) FROM out), n.n = (SELECT COUNT(*) FROM out) FROM nat n
UNION ALL SELECT 'shares sum to 100 within rounding (0.005 per row)', 100, (SELECT SUM(pct_of_customers) FROM out), ABS((SELECT SUM(pct_of_customers) FROM out) - 100) <= 0.005 * (SELECT COUNT(*) FROM out) FROM nat n
UNION ALL SELECT 'unrounded shares sum to 100', 100, (SELECT ROUND(SUM(100 * customer_count / (SELECT SUM(customer_count) FROM out)), 6) FROM out), (SELECT ROUND(SUM(100 * customer_count / (SELECT SUM(customer_count) FROM out)), 6) FROM out) = 100 FROM nat n
ORDER BY check_name;
