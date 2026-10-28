-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-1: inventory value (PS_AVAILQTY * PS_SUPPLYCOST) rolled up by supplier region.
-- Grain: one row per region. Zero-quantity rows are excluded per the requester (none exist today).
SELECT
    RANK() OVER (ORDER BY SUM(ps.PS_AVAILQTY * ps.PS_SUPPLYCOST) DESC) AS rank,
    r.R_NAME AS region_name,
    ROUND(SUM(ps.PS_AVAILQTY * ps.PS_SUPPLYCOST), 2) AS inventory_value
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP ps
JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER s ON ps.PS_SUPPKEY = s.S_SUPPKEY
JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION n ON s.S_NATIONKEY = n.N_NATIONKEY
JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.REGION r ON n.N_REGIONKEY = r.R_REGIONKEY
WHERE ps.PS_AVAILQTY > 0
GROUP BY r.R_NAME
ORDER BY inventory_value DESC, region_name;
