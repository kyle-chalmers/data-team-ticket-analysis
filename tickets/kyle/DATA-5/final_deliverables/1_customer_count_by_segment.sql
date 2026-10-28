-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-5: customer count by market segment, with each segment's share of all customers.
-- Grain: one row per C_MKTSEGMENT. Every customer record counts, with or without orders.
SELECT
    c.C_MKTSEGMENT AS market_segment,
    COUNT(*) AS customer_count,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER c
GROUP BY c.C_MKTSEGMENT
ORDER BY customer_count DESC, market_segment;
