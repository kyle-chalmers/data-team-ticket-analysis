-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-12: Europe supplier inventory value (PS_AVAILQTY * PS_SUPPLYCOST) by part type (PART.P_TYPE), top 15.
-- Grain: one row per part type. Ties share a rank; exactly 15 rows, tie-broken by part type name.
-- Zero-quantity rows are excluded, matching kyle/DATA-1 (none exist today).
WITH params AS (
    SELECT 'EUROPE' AS region_name, 15 AS top_n
),
by_type AS (
    SELECT
        p.P_TYPE AS part_type,
        SUM(ps.PS_AVAILQTY * ps.PS_SUPPLYCOST) AS inventory_value
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP ps
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PART p ON ps.PS_PARTKEY = p.P_PARTKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER s ON ps.PS_SUPPKEY = s.S_SUPPKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION n ON s.S_NATIONKEY = n.N_NATIONKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.REGION r ON n.N_REGIONKEY = r.R_REGIONKEY
    CROSS JOIN params
    WHERE r.R_NAME = params.region_name
      AND ps.PS_AVAILQTY > 0
    GROUP BY p.P_TYPE
)
SELECT
    RANK() OVER (ORDER BY inventory_value DESC) AS rank,
    part_type,
    ROUND(inventory_value, 2) AS inventory_value
FROM by_type
CROSS JOIN params
QUALIFY ROW_NUMBER() OVER (ORDER BY inventory_value DESC, part_type) <= params.top_n
ORDER BY inventory_value DESC, part_type;
