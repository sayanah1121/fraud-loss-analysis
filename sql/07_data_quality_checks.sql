-- ============================================================
-- 07_data_quality_checks.sql
-- Purpose:
--   Final QA checks on the analytical SQLite layer.
--   These checks validate the cleaned star-schema data before
--   the final rule-result layer.
-- ============================================================


-- ============================================================
-- QUERY 1: Analytical table row counts
-- ============================================================

SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count
FROM dim_customer

UNION ALL

SELECT 'dim_card', COUNT(*)
FROM dim_card

UNION ALL

SELECT 'dim_merchant', COUNT(*)
FROM dim_merchant

UNION ALL

SELECT 'dim_device', COUNT(*)
FROM dim_device

UNION ALL

SELECT 'fact_transaction', COUNT(*)
FROM fact_transaction

UNION ALL

SELECT 'fact_chargeback', COUNT(*)
FROM fact_chargeback;


-- ============================================================
-- QUERY 2: Duplicate transaction IDs
-- Expected: 0
-- ============================================================

SELECT
    COUNT(*) AS duplicate_txn_id_groups,
    COALESCE(SUM(duplicate_count - 1), 0) AS duplicate_transaction_rows
FROM (
    SELECT
        txn_id,
        COUNT(*) AS duplicate_count
    FROM fact_transaction
    GROUP BY txn_id
    HAVING COUNT(*) > 1
);


-- ============================================================
-- QUERY 3: Invalid transaction values
-- Expected: 0
-- ============================================================

SELECT
    COUNT(*) AS invalid_amount_rows,
    COALESCE(SUM(amount), 0) AS invalid_amount_value
FROM fact_transaction
WHERE amount <= 0
   OR amount IS NULL;


-- ============================================================
-- QUERY 4: Nulls in critical transaction fields
-- Expected: 0
-- ============================================================

SELECT
    SUM(CASE WHEN txn_id IS NULL THEN 1 ELSE 0 END) AS null_txn_id,
    SUM(CASE WHEN card_id IS NULL THEN 1 ELSE 0 END) AS null_card_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN merchant_id IS NULL THEN 1 ELSE 0 END) AS null_merchant_id,
    SUM(CASE WHEN device_id IS NULL THEN 1 ELSE 0 END) AS null_device_id,
    SUM(CASE WHEN txn_ts IS NULL THEN 1 ELSE 0 END) AS null_txn_ts,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS null_amount,
    SUM(CASE WHEN channel IS NULL THEN 1 ELSE 0 END) AS null_channel,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS null_category
FROM fact_transaction;


-- ============================================================
-- QUERY 5: Foreign-key integrity checks
-- Expected: all counts = 0
-- ============================================================

SELECT
    'customer' AS relationship,
    COUNT(*) AS orphan_rows
FROM fact_transaction t
LEFT JOIN dim_customer c
    ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT
    'card',
    COUNT(*)
FROM fact_transaction t
LEFT JOIN dim_card c
    ON t.card_id = c.card_id
WHERE c.card_id IS NULL

UNION ALL

SELECT
    'merchant',
    COUNT(*)
FROM fact_transaction t
LEFT JOIN dim_merchant m
    ON t.merchant_id = m.merchant_id
WHERE m.merchant_id IS NULL

UNION ALL

SELECT
    'device',
    COUNT(*)
FROM fact_transaction t
LEFT JOIN dim_device d
    ON t.device_id = d.device_id
WHERE d.device_id IS NULL;


-- ============================================================
-- QUERY 6: Chargeback quality checks
-- Expected:
--   duplicate chargebacks = 0
--   invalid financial records = 0
-- ============================================================

SELECT
    COUNT(*) AS total_chargebacks,
    COUNT(DISTINCT txn_id) AS distinct_chargeback_txns,
    COUNT(*) - COUNT(DISTINCT txn_id) AS duplicate_chargeback_rows,
    SUM(
        CASE
            WHEN loss_amount <= 0
              OR recovered_amount < 0
              OR recovered_amount > loss_amount
            THEN 1
            ELSE 0
        END
    ) AS invalid_financial_rows
FROM fact_chargeback;


-- ============================================================
-- QUERY 7: Chargebacks without a matching transaction
--
-- These are retained intentionally because they were present
-- in the original chargeback dataset but their transactions
-- were removed during transaction cleaning.
-- ============================================================

SELECT
    COUNT(*) AS orphan_chargebacks,
    ROUND(COALESCE(SUM(cb.loss_amount), 2), 2) AS orphan_gross_loss,
    ROUND(COALESCE(SUM(cb.recovered_amount), 2), 2) AS orphan_recovered,
    ROUND(
        COALESCE(
            SUM(cb.loss_amount - cb.recovered_amount),
            0
        ),
        2
    ) AS orphan_net_loss
FROM fact_chargeback cb
LEFT JOIN fact_transaction t
    ON cb.txn_id = t.txn_id
WHERE t.txn_id IS NULL;


-- ============================================================
-- QUERY 8: Remaining city spelling variants
--
-- Expected after transaction cleaning:
--   fact_transaction should have no Bangalore / BLR values.
--
-- This is a diagnostic query rather than a pass/fail rule.
-- ============================================================

SELECT
    merchant_city,
    COUNT(*) AS transaction_count
FROM fact_transaction
WHERE merchant_city IN ('Bangalore', 'BLR')
GROUP BY merchant_city
ORDER BY transaction_count DESC;


-- ============================================================
-- QUERY 9: Transaction date range
-- ============================================================

SELECT
    MIN(txn_ts) AS min_transaction_timestamp,
    MAX(txn_ts) AS max_transaction_timestamp,
    COUNT(*) AS transaction_count
FROM fact_transaction;


-- ============================================================
-- QUERY 10: Unknown device member validation
--
-- Device ID -1 is the intentional UNKNOWN device member
-- created during dimension cleaning.
-- ============================================================

SELECT
    COUNT(*) AS unknown_device_transactions
FROM fact_transaction
WHERE device_id = -1;


-- ============================================================
-- QUERY 11: Transaction amount sanity summary
-- ============================================================

SELECT
    ROUND(MIN(amount), 2) AS minimum_amount,
    ROUND(AVG(amount), 2) AS average_amount,
    ROUND(
        (SELECT amount
         FROM fact_transaction
         ORDER BY amount
         LIMIT 1
         OFFSET (
             SELECT CAST((COUNT(*) - 1) * 0.5 AS INTEGER)
             FROM fact_transaction
         )),
        2
    ) AS approximate_median_amount,
    ROUND(MAX(amount), 2) AS maximum_amount
FROM fact_transaction;


-- ============================================================
-- QUERY 12: Final QA status summary
--
-- This provides a compact executive-style QA view.
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM fact_transaction) AS transaction_rows,

    (
        SELECT COUNT(*)
        FROM fact_transaction t
        LEFT JOIN dim_customer c
            ON t.customer_id = c.customer_id
        WHERE c.customer_id IS NULL
    ) AS orphan_customer_rows,

    (
        SELECT COUNT(*)
        FROM fact_transaction t
        LEFT JOIN dim_card c
            ON t.card_id = c.card_id
        WHERE c.card_id IS NULL
    ) AS orphan_card_rows,

    (
        SELECT COUNT(*)
        FROM fact_transaction t
        LEFT JOIN dim_merchant m
            ON t.merchant_id = m.merchant_id
        WHERE m.merchant_id IS NULL
    ) AS orphan_merchant_rows,

    (
        SELECT COUNT(*)
        FROM fact_transaction t
        LEFT JOIN dim_device d
            ON t.device_id = d.device_id
        WHERE d.device_id IS NULL
    ) AS orphan_device_rows,

    (
        SELECT COUNT(*)
        FROM fact_transaction
        WHERE amount <= 0 OR amount IS NULL
    ) AS invalid_amount_rows,

    (
        SELECT COUNT(*)
        FROM (
            SELECT txn_id
            FROM fact_transaction
            GROUP BY txn_id
            HAVING COUNT(*) > 1
        )
    ) AS duplicate_txn_id_groups;