-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-9: customer count by nation, with each nation's share of all customers.
-- Grain: one row per nation. NATION is the left side, so a nation with no customers would show 0.
SELECT
    n.N_NAME AS nation_name,
    COUNT(c.C_CUSTKEY) AS customer_count,
    ROUND(100 * COUNT(c.C_CUSTKEY) / NULLIF(SUM(COUNT(c.C_CUSTKEY)) OVER (), 0), 2) AS pct_of_customers
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION n
LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER c ON c.C_NATIONKEY = n.N_NATIONKEY
GROUP BY n.N_NAME
ORDER BY customer_count DESC, nation_name;
