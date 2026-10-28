-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-2: order count by order status, with each status's share of all orders.
-- Grain: one row per O_ORDERSTATUS. Labels follow the TPC-H definition of the status codes.
SELECT
    o.O_ORDERSTATUS AS order_status,
    CASE o.O_ORDERSTATUS
        WHEN 'F' THEN 'Fulfilled'
        WHEN 'O' THEN 'Open'
        WHEN 'P' THEN 'Partially shipped'
        ELSE 'Unknown'
    END AS status_meaning,
    COUNT(*) AS order_count,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS o
GROUP BY o.O_ORDERSTATUS
ORDER BY order_count DESC, order_status;
