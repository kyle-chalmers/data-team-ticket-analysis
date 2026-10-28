-- warehouse-target: SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (read-only)
-- DATA-7 QC: layers 2-3 (counts, dedup, reconciliation). Every row should read pass = TRUE.
WITH out AS (
    SELECT L_SHIPMODE AS ship_mode, COUNT(*) AS line_items,
           COUNT_IF(L_RECEIPTDATE > L_COMMITDATE) AS late_line_items,
           ROUND(100 * COUNT_IF(L_RECEIPTDATE > L_COMMITDATE) / COUNT(*), 2) AS pct_late
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM GROUP BY L_SHIPMODE
),
src AS (
    SELECT COUNT(*) AS n, COUNT(DISTINCT L_ORDERKEY || '-' || L_LINENUMBER) AS d,
           SUM(IFF(L_RECEIPTDATE > L_COMMITDATE, 1, 0)) AS n_late, COUNT(DISTINCT L_SHIPMODE) AS n_mode,
           COUNT_IF(L_SHIPMODE IS NULL OR L_RECEIPTDATE IS NULL OR L_COMMITDATE IS NULL) AS n_null
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM
)
SELECT 'sum of mode counts = LINEITEM rows' AS check_name, s.n AS expected, (SELECT SUM(line_items) FROM out) AS actual, s.n = (SELECT SUM(line_items) FROM out) AS pass FROM src s
UNION ALL SELECT 'sum of late counts = whole-table late count', s.n_late, (SELECT SUM(late_line_items) FROM out), s.n_late = (SELECT SUM(late_line_items) FROM out) FROM src s
UNION ALL SELECT 'line-item grain unique (order, line number)', s.n, s.d, s.n = s.d FROM src s
UNION ALL SELECT 'output rows = distinct ship modes (no duplicates)', s.n_mode, (SELECT COUNT(*) FROM out), s.n_mode = (SELECT COUNT(*) FROM out) FROM src s
UNION ALL SELECT 'no NULL ship mode, receipt or commit date', 0, s.n_null, s.n_null = 0 FROM src s
UNION ALL SELECT 'every pct_late = late / items within 0.01', 0, (SELECT COUNT_IF(ABS(pct_late - 100 * late_line_items / line_items) > 0.01) FROM out), (SELECT COUNT_IF(ABS(pct_late - 100 * late_line_items / line_items) > 0.01) FROM out) = 0 FROM src s
ORDER BY check_name;
