-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-2 QC: layers 2-3 (counts, dedup, reconciliation). Every row should read pass = TRUE.
WITH out AS (
    SELECT O_ORDERSTATUS AS order_status, COUNT(*) AS order_count,
           ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
    GROUP BY O_ORDERSTATUS
),
src AS (
    SELECT COUNT(*) AS n_orders, COUNT(DISTINCT O_ORDERKEY) AS n_keys,
           COUNT(DISTINCT O_ORDERSTATUS) AS n_status, COUNT_IF(O_ORDERSTATUS IS NULL) AS n_null
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
)
SELECT 'sum of status counts = ORDERS rows' AS check_name, s.n_orders AS expected, (SELECT SUM(order_count) FROM out) AS actual, s.n_orders = (SELECT SUM(order_count) FROM out) AS pass FROM src s
UNION ALL SELECT 'O_ORDERKEY unique (row = order)', s.n_orders, s.n_keys, s.n_orders = s.n_keys FROM src s
UNION ALL SELECT 'output rows = distinct statuses (no duplicates)', s.n_status, (SELECT COUNT(*) FROM out), s.n_status = (SELECT COUNT(*) FROM out) FROM src s
UNION ALL SELECT 'no NULL status', 0, s.n_null, s.n_null = 0 FROM src s
UNION ALL SELECT 'shares sum to 100 within 0.01', 100, (SELECT SUM(pct_of_orders) FROM out), ABS((SELECT SUM(pct_of_orders) FROM out) - 100) <= 0.01 FROM src s
ORDER BY check_name;
