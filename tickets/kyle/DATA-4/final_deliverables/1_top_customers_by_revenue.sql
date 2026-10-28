-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-4: top N customers by total order revenue (SUM of O_TOTALPRICE, all orders), with market segment.
-- Grain: one row per customer. Ties would share a rank; none occur at the cut-off.
WITH params AS (
    SELECT 10 AS top_n
),
per_customer AS (
    SELECT o.O_CUSTKEY AS customer_key, COUNT(*) AS order_count, SUM(o.O_TOTALPRICE) AS revenue
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS o
    GROUP BY o.O_CUSTKEY
),
ranked AS (
    SELECT RANK() OVER (ORDER BY pc.revenue DESC) AS rank,
           pc.customer_key, c.C_NAME AS customer_name, c.C_MKTSEGMENT AS market_segment,
           pc.order_count, ROUND(pc.revenue, 2) AS order_revenue
    FROM per_customer pc
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER c ON pc.customer_key = c.C_CUSTKEY
)
SELECT r.rank, r.customer_key, r.customer_name, r.market_segment, r.order_count, r.order_revenue
FROM ranked r
CROSS JOIN params p
WHERE r.rank <= p.top_n
ORDER BY r.order_revenue DESC, r.customer_key;
