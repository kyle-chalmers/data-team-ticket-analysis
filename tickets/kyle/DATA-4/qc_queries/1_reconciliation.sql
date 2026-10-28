-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-4 QC: layers 2-3 (join, dedup, ranking). Every row should read pass = TRUE.
WITH per_customer AS (
    SELECT O_CUSTKEY, SUM(O_TOTALPRICE) AS revenue
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS GROUP BY O_CUSTKEY
),
ordered AS (
    SELECT O_CUSTKEY, revenue, ROW_NUMBER() OVER (ORDER BY revenue DESC, O_CUSTKEY) AS rn FROM per_customer
),
cust AS (SELECT COUNT(*) AS n, COUNT(DISTINCT C_CUSTKEY) AS d FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER),
joined AS (
    SELECT COUNT(*) AS n_joined, SUM(o.O_TOTALPRICE) AS joined_rev, COUNT_IF(c.C_CUSTKEY IS NULL) AS orphans
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS o LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER c ON o.O_CUSTKEY = c.C_CUSTKEY
),
src AS (SELECT COUNT(*) AS n_orders, SUM(O_TOTALPRICE) AS total_rev FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS)
SELECT 'C_CUSTKEY unique (join cannot fan out)' AS check_name, c.n AS expected, c.d AS actual, c.n = c.d AS pass FROM cust c
UNION ALL SELECT 'no orders without a customer', 0, j.orphans, j.orphans = 0 FROM joined j
UNION ALL SELECT 'joined revenue = ORDERS revenue (to the cent)', ROUND(s.total_rev, 2), ROUND(j.joined_rev, 2), ROUND(s.total_rev, 2) = ROUND(j.joined_rev, 2) FROM src s, joined j
UNION ALL SELECT 'no tie at the cut-off (rank 10 > rank 11)', ROUND((SELECT revenue FROM ordered WHERE rn = 10), 2), ROUND((SELECT revenue FROM ordered WHERE rn = 11), 2), (SELECT revenue FROM ordered WHERE rn = 10) > (SELECT revenue FROM ordered WHERE rn = 11) FROM src s
UNION ALL SELECT 'info: top-10 revenue from independent per-customer sums (compare to the CSV total)', ROUND((SELECT SUM(revenue) FROM ordered WHERE rn <= 10), 2), NULL, TRUE FROM src s
ORDER BY check_name;
