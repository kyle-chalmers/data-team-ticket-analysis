-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-1 QC: layers 2-3 (counts, dedup, reconciliation). Every row should read pass = TRUE.
WITH base AS (
    SELECT COUNT(*) AS n_filtered, SUM(PS_AVAILQTY * PS_SUPPLYCOST) AS total_value,
           COUNT(DISTINCT PS_PARTKEY || '-' || PS_SUPPKEY) AS n_distinct_grain
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP WHERE PS_AVAILQTY > 0
),
joined AS (
    SELECT COUNT(*) AS n_joined, SUM(ps.PS_AVAILQTY * ps.PS_SUPPLYCOST) AS joined_value
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP ps
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER s ON ps.PS_SUPPKEY = s.S_SUPPKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION n ON s.S_NATIONKEY = n.N_NATIONKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.REGION r ON n.N_REGIONKEY = r.R_REGIONKEY
    WHERE ps.PS_AVAILQTY > 0
),
region AS (SELECT COUNT(*) AS n_regions FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.REGION)
SELECT 'joined rows = filtered PARTSUPP rows' AS check_name, b.n_filtered AS expected, j.n_joined AS actual, b.n_filtered = j.n_joined AS pass FROM base b, joined j
UNION ALL SELECT 'filtered rows = all PARTSUPP rows (zero-qty filter is a no-op)', (SELECT COUNT(*) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP), b.n_filtered, (SELECT COUNT(*) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP) = b.n_filtered FROM base b
UNION ALL SELECT 'PARTSUPP grain unique (part,supplier)', b.n_filtered, b.n_distinct_grain, b.n_filtered = b.n_distinct_grain FROM base b
UNION ALL SELECT 'region sum = whole-table sum (to the cent)', ROUND(b.total_value, 2), ROUND(j.joined_value, 2), ROUND(b.total_value, 2) = ROUND(j.joined_value, 2) FROM base b, joined j
UNION ALL SELECT 'output regions = REGION rows', rg.n_regions, 5, rg.n_regions = 5 FROM region rg;
