-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-7: share of line items received after their commit date, by ship mode.
-- Grain: one row per L_SHIPMODE. Late = L_RECEIPTDATE strictly after L_COMMITDATE.
SELECT
    l.L_SHIPMODE AS ship_mode,
    COUNT(*) AS line_items,
    COUNT_IF(l.L_RECEIPTDATE > l.L_COMMITDATE) AS late_line_items,
    ROUND(100 * COUNT_IF(l.L_RECEIPTDATE > l.L_COMMITDATE) / COUNT(*), 2) AS pct_late
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM l
GROUP BY l.L_SHIPMODE
ORDER BY pct_late DESC, ship_mode;
