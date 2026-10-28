-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-10 QC: layers 2-3 (counts, dedup, reconciliation). Every row should read pass = TRUE.
WITH yr AS (
    SELECT L_ORDERKEY, L_LINENUMBER, L_EXTENDEDPRICE, L_DISCOUNT, L_SHIPDATE FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM
    WHERE YEAR(L_SHIPDATE) = 1996  -- independent of the deliverable's params window
),
t AS (
    SELECT COUNT(*) AS n, COUNT(DISTINCT L_ORDERKEY || '-' || L_LINENUMBER) AS d,
           ROUND(SUM(L_EXTENDEDPRICE), 2) AS gross, ROUND(SUM(L_EXTENDEDPRICE * L_DISCOUNT), 2) AS disc,
           ROUND(SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)), 2) AS net,
           ROUND(SUM(L_EXTENDEDPRICE) - SUM(L_EXTENDEDPRICE * L_DISCOUNT), 2) AS net_alt,
           COUNT_IF(L_EXTENDEDPRICE IS NULL OR L_DISCOUNT IS NULL) AS n_null,
           COUNT_IF(L_DISCOUNT < 0 OR L_DISCOUNT > 0.10) AS n_out_of_range,
           MIN(L_SHIPDATE) AS first_ship, MAX(L_SHIPDATE) AS last_ship
    FROM yr
)
SELECT 'gross - discount = discounted (to the cent)' AS check_name, t.net AS expected, t.gross - t.disc AS actual, t.gross - t.disc = t.net AS pass FROM t
UNION ALL SELECT 'discounted = gross sum minus discount sum (within 0.01)', t.net, t.net_alt, ABS(t.net - t.net_alt) <= 0.01 FROM t
UNION ALL SELECT 'line-item grain unique in 1996', t.n, t.d, t.n = t.d FROM t
UNION ALL SELECT 'no NULL price or discount', 0, t.n_null, t.n_null = 0 FROM t
UNION ALL SELECT 'discounts within 0 to 0.10', 0, t.n_out_of_range, t.n_out_of_range = 0 FROM t
UNION ALL SELECT 'window covers 1996-01-01 to 1996-12-31', 0, DATEDIFF('day', '1996-01-01'::DATE, t.first_ship) + DATEDIFF('day', t.last_ship, '1996-12-31'::DATE), t.first_ship = '1996-01-01'::DATE AND t.last_ship = '1996-12-31'::DATE FROM t
UNION ALL SELECT 'info: line items in 1996 by order date instead', NULL, (SELECT COUNT(*) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM l JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS o ON o.O_ORDERKEY = l.L_ORDERKEY WHERE YEAR(o.O_ORDERDATE) = 1996), NULL FROM t
UNION ALL SELECT 'info: order-date gross minus ship-date gross (net shift)', NULL, (SELECT ROUND(SUM(l.L_EXTENDEDPRICE), 2) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM l JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS o ON o.O_ORDERKEY = l.L_ORDERKEY WHERE YEAR(o.O_ORDERDATE) = 1996) - t.gross, NULL FROM t
ORDER BY check_name;
