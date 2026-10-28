-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-6: average order total (O_TOTALPRICE) by order priority, with order count and total revenue.
-- Grain: one row per O_ORDERPRIORITY. All orders, no date filter.
SELECT
    o.O_ORDERPRIORITY AS order_priority,
    COUNT(*) AS order_count,
    ROUND(SUM(o.O_TOTALPRICE), 2) AS total_revenue,
    ROUND(AVG(o.O_TOTALPRICE), 2) AS avg_order_value
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS o
GROUP BY o.O_ORDERPRIORITY
ORDER BY order_priority;
