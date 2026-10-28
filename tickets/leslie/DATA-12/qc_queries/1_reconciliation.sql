-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-12 QC: layers 2-3 (counts, dedup, reconciliation). Every row should read pass = TRUE.
WITH params AS (
    SELECT 'EUROPE' AS region_name, 397934639557.59 AS data1_europe_total
),
eu AS (
    SELECT ps.PS_PARTKEY, ps.PS_SUPPKEY, ps.PS_AVAILQTY * ps.PS_SUPPLYCOST AS v
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP ps
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER s ON ps.PS_SUPPKEY = s.S_SUPPKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION n ON s.S_NATIONKEY = n.N_NATIONKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.REGION r ON n.N_REGIONKEY = r.R_REGIONKEY
    CROSS JOIN params
    WHERE r.R_NAME = params.region_name AND ps.PS_AVAILQTY > 0
),
eu_typed AS (
    SELECT eu.*, p.P_TYPE FROM eu JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PART p ON eu.PS_PARTKEY = p.P_PARTKEY
),
by_type AS (SELECT P_TYPE, SUM(v) AS v FROM eu_typed GROUP BY P_TYPE)
SELECT 'Europe rows = 158,960 (scoping count)' AS check_name, 158960 AS expected, (SELECT COUNT(*) FROM eu) AS actual, expected = actual AS pass
UNION ALL SELECT 'PART join drops no rows', (SELECT COUNT(*) FROM eu), (SELECT COUNT(*) FROM eu_typed), (SELECT COUNT(*) FROM eu) = (SELECT COUNT(*) FROM eu_typed)
UNION ALL SELECT 'zero-qty filter is a no-op (all PARTSUPP qty > 0)', (SELECT COUNT(*) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP), (SELECT COUNT_IF(PS_AVAILQTY > 0) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP), (SELECT COUNT(*) = COUNT_IF(PS_AVAILQTY > 0) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP)
UNION ALL SELECT 'grain unique (part, supplier)', (SELECT COUNT(*) FROM eu), (SELECT COUNT(DISTINCT PS_PARTKEY, PS_SUPPKEY) FROM eu), (SELECT COUNT(*) FROM eu) = (SELECT COUNT(DISTINCT PS_PARTKEY, PS_SUPPKEY) FROM eu)
UNION ALL SELECT 'part types = 150, one row each', 150, (SELECT COUNT(*) FROM by_type), (SELECT COUNT(*) = 150 AND COUNT(*) = COUNT(DISTINCT P_TYPE) FROM by_type)
UNION ALL SELECT 'sum over types = Europe total (to the cent)', (SELECT ROUND(SUM(v), 2) FROM eu), (SELECT ROUND(SUM(v), 2) FROM by_type), (SELECT ROUND(SUM(v), 2) FROM eu) = (SELECT ROUND(SUM(v), 2) FROM by_type)
UNION ALL SELECT 'Europe total = kyle/DATA-1 EUROPE value', (SELECT data1_europe_total FROM params), (SELECT ROUND(SUM(v), 2) FROM eu), (SELECT data1_europe_total FROM params) = (SELECT ROUND(SUM(v), 2) FROM eu)
UNION ALL SELECT 'no tie straddles the top-15 cut (#15 value <> #16 value)', 1, (SELECT IFF(MAX(IFF(rn = 15, v, NULL)) <> MAX(IFF(rn = 16, v, NULL)), 1, 0) FROM (SELECT v, ROW_NUMBER() OVER (ORDER BY v DESC, P_TYPE) rn FROM by_type)), (SELECT MAX(IFF(rn = 15, v, NULL)) <> MAX(IFF(rn = 16, v, NULL)) FROM (SELECT v, ROW_NUMBER() OVER (ORDER BY v DESC, P_TYPE) rn FROM by_type));
