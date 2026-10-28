-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-6 QC: layers 2-3 (counts, dedup, reconciliation). Every row should read pass = TRUE.
WITH out AS (
    SELECT O_ORDERPRIORITY AS order_priority, COUNT(*) AS order_count,
           ROUND(SUM(O_TOTALPRICE), 2) AS total_revenue, ROUND(AVG(O_TOTALPRICE), 2) AS avg_order_value
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS GROUP BY O_ORDERPRIORITY
),
src AS (
    SELECT COUNT(*) AS n, ROUND(SUM(O_TOTALPRICE), 2) AS total_rev, COUNT(DISTINCT O_ORDERPRIORITY) AS n_pri,
           COUNT_IF(O_ORDERPRIORITY IS NULL) AS n_null
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
)
SELECT 'sum of priority counts = ORDERS rows' AS check_name, s.n AS expected, (SELECT SUM(order_count) FROM out) AS actual, s.n = (SELECT SUM(order_count) FROM out) AS pass FROM src s
UNION ALL SELECT 'sum of priority revenue = ORDERS revenue (to the cent)', s.total_rev, (SELECT SUM(total_revenue) FROM out), s.total_rev = (SELECT SUM(total_revenue) FROM out) FROM src s
UNION ALL SELECT 'every average = revenue / count within 0.01', 0, (SELECT COUNT_IF(ABS(avg_order_value - total_revenue / order_count) > 0.01) FROM out), (SELECT COUNT_IF(ABS(avg_order_value - total_revenue / order_count) > 0.01) FROM out) = 0 FROM src s
UNION ALL SELECT 'output rows = distinct priorities (no duplicates)', s.n_pri, (SELECT COUNT(*) FROM out), s.n_pri = (SELECT COUNT(*) FROM out) FROM src s
UNION ALL SELECT 'no NULL priority', 0, s.n_null, s.n_null = 0 FROM src s
ORDER BY check_name;
