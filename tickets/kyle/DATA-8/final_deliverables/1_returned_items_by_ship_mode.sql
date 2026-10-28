-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-8: count of returned line items (L_RETURNFLAG = 'R') by ship mode, with the share of the mode's items.
-- Grain: one row per L_SHIPMODE.
WITH params AS (
    SELECT 'R' AS returned_flag
)
SELECT
    l.L_SHIPMODE AS ship_mode,
    COUNT(*) AS line_items,
    COUNT_IF(l.L_RETURNFLAG = p.returned_flag) AS returned_line_items,
    ROUND(100 * COUNT_IF(l.L_RETURNFLAG = p.returned_flag) / COUNT(*), 2) AS pct_returned
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM l
CROSS JOIN params p
GROUP BY l.L_SHIPMODE
ORDER BY returned_line_items DESC, ship_mode;
