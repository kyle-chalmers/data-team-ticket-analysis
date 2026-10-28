-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-10: gross vs discounted line-item revenue for line items shipped in 1996 (before tax).
-- Grain: one row for the ship year. Window is start inclusive, end exclusive.
WITH params AS (
    SELECT '1996-01-01'::DATE AS window_start, '1997-01-01'::DATE AS window_end
),
totals AS (
    SELECT
        COUNT(*) AS line_items,
        SUM(l.L_EXTENDEDPRICE) AS gross,
        SUM(l.L_EXTENDEDPRICE * l.L_DISCOUNT) AS discount,
        SUM(l.L_EXTENDEDPRICE * (1 - l.L_DISCOUNT)) AS net
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM l
    CROSS JOIN params p
    WHERE l.L_SHIPDATE >= p.window_start
      AND l.L_SHIPDATE < p.window_end
)
SELECT
    YEAR(p.window_start) AS ship_year,
    t.line_items,
    ROUND(t.gross, 2) AS gross_revenue,
    ROUND(t.discount, 2) AS discount_amount,
    ROUND(t.net, 2) AS discounted_revenue,
    ROUND(100 * t.discount / NULLIF(t.gross, 0), 2) AS discount_pct_of_gross
FROM totals t
CROSS JOIN params p
ORDER BY ship_year;
