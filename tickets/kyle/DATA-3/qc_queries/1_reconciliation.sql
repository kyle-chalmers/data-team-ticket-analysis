-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-3 QC: layers 2-3 (counts, dedup, reconciliation). Every row should read pass = TRUE.
WITH params AS (
    SELECT '1997-01-01'::DATE AS window_start, '1998-01-01'::DATE AS window_end
),
out AS (
    SELECT TO_CHAR(DATE_TRUNC('month', o.O_ORDERDATE), 'YYYY-MM') AS order_month,
           COUNT(*) AS order_count, ROUND(SUM(o.O_TOTALPRICE), 2) AS order_revenue
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS o CROSS JOIN params p
    WHERE o.O_ORDERDATE >= p.window_start AND o.O_ORDERDATE < p.window_end
    GROUP BY order_month
),
src AS (
    SELECT COUNT(*) AS n_orders, COUNT(DISTINCT o.O_ORDERKEY) AS n_keys, ROUND(SUM(o.O_TOTALPRICE), 2) AS total_revenue,
           COUNT_IF(o.O_TOTALPRICE IS NULL OR o.O_TOTALPRICE <= 0) AS n_bad_price
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS o
    WHERE YEAR(o.O_ORDERDATE) = 1997  -- independent of the params window
)
SELECT 'sum of monthly counts = 1997 ORDERS rows' AS check_name, s.n_orders AS expected, (SELECT SUM(order_count) FROM out) AS actual, s.n_orders = (SELECT SUM(order_count) FROM out) AS pass FROM src s
UNION ALL SELECT 'sum of monthly revenue = whole-year revenue (to the cent)', s.total_revenue, (SELECT SUM(order_revenue) FROM out), s.total_revenue = (SELECT SUM(order_revenue) FROM out) FROM src s
UNION ALL SELECT 'O_ORDERKEY unique in 1997 (row = order)', s.n_orders, s.n_keys, s.n_orders = s.n_keys FROM src s
UNION ALL SELECT '12 output months, no duplicates', 12, (SELECT COUNT(DISTINCT order_month) FROM out), (SELECT COUNT(DISTINCT order_month) FROM out) = 12 AND (SELECT COUNT(*) FROM out) = 12 FROM src s
UNION ALL SELECT 'no NULL or non-positive O_TOTALPRICE', 0, s.n_bad_price, s.n_bad_price = 0 FROM src s
ORDER BY check_name;
