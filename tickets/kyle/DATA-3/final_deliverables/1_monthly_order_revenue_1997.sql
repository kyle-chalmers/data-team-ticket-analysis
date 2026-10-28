-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-3: total order revenue (SUM of O_TOTALPRICE) by order month for 1997.
-- Grain: one row per calendar month of the window. Window is start inclusive, end exclusive.
WITH params AS (
    SELECT '1997-01-01'::DATE AS window_start, '1998-01-01'::DATE AS window_end
)
SELECT
    TO_CHAR(DATE_TRUNC('month', o.O_ORDERDATE), 'YYYY-MM') AS order_month,
    COUNT(*) AS order_count,
    ROUND(SUM(o.O_TOTALPRICE), 2) AS order_revenue
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS o
CROSS JOIN params p
WHERE o.O_ORDERDATE >= p.window_start
  AND o.O_ORDERDATE < p.window_end
GROUP BY order_month
ORDER BY order_month;
