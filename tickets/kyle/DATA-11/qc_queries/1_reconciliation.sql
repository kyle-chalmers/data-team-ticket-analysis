-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-11 QC: layers 2-3 (counts, dedup, ranking). Every row should read pass = TRUE.
WITH yr AS (
    SELECT O_ORDERKEY, O_CLERK FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
    WHERE YEAR(O_ORDERDATE) = 1995  -- independent of the deliverable's params window
),
per_clerk AS (SELECT O_CLERK, COUNT(*) AS n FROM yr GROUP BY O_CLERK),
ordered AS (SELECT O_CLERK, n, ROW_NUMBER() OVER (ORDER BY n DESC, O_CLERK) AS rn FROM per_clerk),
src AS (SELECT COUNT(*) AS n, COUNT(DISTINCT O_ORDERKEY) AS d, COUNT_IF(O_CLERK IS NULL) AS n_null FROM yr)
SELECT 'per-clerk counts sum to 1995 ORDERS rows' AS check_name, s.n AS expected, (SELECT SUM(n) FROM per_clerk) AS actual, s.n = (SELECT SUM(n) FROM per_clerk) AS pass FROM src s
UNION ALL SELECT 'O_ORDERKEY unique in 1995 (row = order)', s.n, s.d, s.n = s.d FROM src s
UNION ALL SELECT 'no NULL clerk', 0, s.n_null, s.n_null = 0 FROM src s
UNION ALL SELECT 'no tie at the cut-off (20th > 21st)', (SELECT n FROM ordered WHERE rn = 20), (SELECT n FROM ordered WHERE rn = 21), (SELECT n FROM ordered WHERE rn = 20) > (SELECT n FROM ordered WHERE rn = 21) FROM src s
UNION ALL SELECT 'info: orders handled by the top 20', NULL, (SELECT SUM(n) FROM ordered WHERE rn <= 20), NULL FROM src s
UNION ALL SELECT 'info: clerks with 1995 orders', NULL, (SELECT COUNT(*) FROM per_clerk), NULL FROM src s
ORDER BY check_name;
