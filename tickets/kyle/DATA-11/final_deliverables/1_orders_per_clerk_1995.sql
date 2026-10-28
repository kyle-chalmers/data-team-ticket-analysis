-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-11: number of orders handled by each clerk in 1995 (by O_ORDERDATE), top N.
-- Grain: one row per clerk. Tied clerks share a rank; there is no tie at the cut-off.
WITH params AS (
    SELECT '1995-01-01'::DATE AS window_start, '1996-01-01'::DATE AS window_end, 20 AS top_n
),
per_clerk AS (
    SELECT o.O_CLERK AS clerk, COUNT(*) AS order_count
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS o
    CROSS JOIN params p
    WHERE o.O_ORDERDATE >= p.window_start
      AND o.O_ORDERDATE < p.window_end
    GROUP BY o.O_CLERK
),
ranked AS (
    SELECT RANK() OVER (ORDER BY pc.order_count DESC) AS rank, pc.clerk, pc.order_count
    FROM per_clerk pc
)
SELECT r.rank, r.clerk, r.order_count
FROM ranked r
CROSS JOIN params p
WHERE r.rank <= p.top_n
ORDER BY r.order_count DESC, r.clerk;
