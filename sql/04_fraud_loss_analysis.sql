-- ============================================================
-- 04_fraud_loss_analysis.sql
-- Credit Card Fraud Pattern and Loss Analysis
--
-- Purpose:
-- Analyze the financial impact of confirmed fraud.
--
-- Business questions:
--   1. What is the gross fraud loss?
--   2. How much is recovered?
--   3. What is the net loss?
--   4. How does loss change over time?
--   5. Which channels/categories drive the loss?
--
-- Important:
-- The hidden simulation ground truth is NOT used here.
-- This SQL layer uses confirmed chargeback information.
-- ============================================================


-- ============================================================
-- QUERY 1
-- Overall confirmed fraud / chargeback loss baseline
--
-- Uses the complete chargeback table, including the 12
-- chargebacks that do not have a matching cleaned transaction.
-- ============================================================

SELECT
    COUNT(DISTINCT cb.txn_id) AS confirmed_fraud_chargebacks,

    ROUND(
        SUM(cb.loss_amount),
        2
    ) AS gross_chargeback_loss,

    ROUND(
        SUM(cb.recovered_amount),
        2
    ) AS recovered_amount,

    ROUND(
        SUM(cb.loss_amount - cb.recovered_amount),
        2
    ) AS net_loss,

    ROUND(
        100.0 * SUM(cb.recovered_amount)
        / NULLIF(SUM(cb.loss_amount), 0),
        2
    ) AS recovery_rate_pct

FROM fact_chargeback cb

WHERE cb.confirmed_fraud_flag = 1;

-- ============================================================
-- QUERY 2
-- Monthly fraud loss
--
-- IMPORTANT:
-- Month is based on transaction date, NOT chargeback report
-- date. This avoids incorrectly attributing delayed chargebacks
-- to the month in which they were reported.
-- ============================================================

SELECT
    strftime('%Y-%m', t.txn_ts) AS transaction_month,

    COUNT(DISTINCT cb.txn_id) AS fraud_transactions,

    ROUND(
        SUM(t.amount),
        2
    ) AS gross_fraud_value,

    ROUND(
        SUM(cb.recovered_amount),
        2
    ) AS recovered_amount,

    ROUND(
        SUM(cb.loss_amount - cb.recovered_amount),
        2
    ) AS net_loss,

    ROUND(
        100.0 * SUM(cb.recovered_amount)
        / NULLIF(SUM(t.amount), 0),
        2
    ) AS recovery_vs_fraud_value_pct

FROM fact_chargeback cb

JOIN fact_transaction t
    ON cb.txn_id = t.txn_id

WHERE cb.confirmed_fraud_flag = 1

GROUP BY
    strftime('%Y-%m', t.txn_ts)

ORDER BY
    transaction_month;


-- ============================================================
-- QUERY 3
-- Fraud loss by channel
-- ============================================================

SELECT
    t.channel,

    COUNT(DISTINCT cb.txn_id) AS fraud_transactions,

    ROUND(
        SUM(t.amount),
        2
    ) AS gross_fraud_value,

    ROUND(
        SUM(cb.recovered_amount),
        2
    ) AS recovered_amount,

    ROUND(
        SUM(cb.loss_amount - cb.recovered_amount),
        2
    ) AS net_loss,

    ROUND(
        100.0 * SUM(cb.loss_amount - cb.recovered_amount)
        / NULLIF(
            SUM(SUM(cb.loss_amount - cb.recovered_amount))
            OVER (),
            0
        ),
        2
    ) AS net_loss_share_pct

FROM fact_chargeback cb

JOIN fact_transaction t
    ON cb.txn_id = t.txn_id

WHERE cb.confirmed_fraud_flag = 1

GROUP BY
    t.channel

ORDER BY
    net_loss DESC;


-- ============================================================
-- QUERY 4
-- Fraud loss by transaction category
-- ============================================================

SELECT
    t.category,

    COUNT(DISTINCT cb.txn_id) AS fraud_transactions,

    ROUND(
        SUM(t.amount),
        2
    ) AS gross_fraud_value,

    ROUND(
        SUM(cb.recovered_amount),
        2
    ) AS recovered_amount,

    ROUND(
        SUM(cb.loss_amount - cb.recovered_amount),
        2
    ) AS net_loss,

    ROUND(
        100.0 * SUM(cb.loss_amount - cb.recovered_amount)
        / NULLIF(
            SUM(SUM(cb.loss_amount - cb.recovered_amount))
            OVER (),
            0
        ),
        2
    ) AS net_loss_share_pct

FROM fact_chargeback cb

JOIN fact_transaction t
    ON cb.txn_id = t.txn_id

WHERE cb.confirmed_fraud_flag = 1

GROUP BY
    t.category

ORDER BY
    net_loss DESC;


-- ============================================================
-- QUERY 5
-- High-value fraud loss concentration
-- ============================================================

WITH thresholds AS (
    SELECT 10000 AS threshold
    UNION ALL
    SELECT 20000
    UNION ALL
    SELECT 25000
    UNION ALL
    SELECT 50000
),

fraud_base AS (
    SELECT
        t.txn_id,
        t.amount,
        cb.loss_amount,
        cb.recovered_amount
    FROM fact_transaction t

    JOIN fact_chargeback cb
        ON t.txn_id = cb.txn_id

    WHERE cb.confirmed_fraud_flag = 1
)

SELECT
    th.threshold,

    COUNT(
        CASE
            WHEN fb.amount >= th.threshold
            THEN fb.txn_id
        END
    ) AS fraud_transactions,

    ROUND(
        SUM(
            CASE
                WHEN fb.amount >= th.threshold
                THEN fb.amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value,

    ROUND(
        SUM(
            CASE
                WHEN fb.amount >= th.threshold
                THEN (fb.loss_amount - fb.recovered_amount)
                ELSE 0
            END
        ),
        2
    ) AS net_loss,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN fb.amount >= th.threshold
                THEN (fb.loss_amount - fb.recovered_amount)
                ELSE 0
            END
        )
        / NULLIF(
            SUM(fb.loss_amount - fb.recovered_amount),
            0
        ),
        2
    ) AS net_loss_coverage_pct

FROM thresholds th

CROSS JOIN fraud_base fb

GROUP BY
    th.threshold

ORDER BY
    th.threshold;


-- ============================================================
-- QUERY 6
-- E-commerce high-risk category loss concentration
--
-- Focus:
--   E_COMMERCE
--   Electronics
--   Gift Cards
-- ============================================================

SELECT
    t.channel,

    t.category,

    COUNT(DISTINCT cb.txn_id) AS fraud_transactions,

    ROUND(
        SUM(t.amount),
        2
    ) AS gross_fraud_value,

    ROUND(
        SUM(cb.loss_amount - cb.recovered_amount),
        2
    ) AS net_loss,

    ROUND(
        100.0 * SUM(cb.loss_amount - cb.recovered_amount)
        / NULLIF(
            (
                SELECT SUM(cb2.loss_amount)
                FROM fact_chargeback cb2
                WHERE cb2.confirmed_fraud_flag = 1
            ),
            0
        ),
        2
    ) AS total_net_loss_share_pct

FROM fact_chargeback cb

JOIN fact_transaction t
    ON cb.txn_id = t.txn_id

WHERE cb.confirmed_fraud_flag = 1
  AND t.channel = 'E_COMMERCE'
  AND t.category IN ('Electronics', 'Gift Cards')

GROUP BY
    t.channel,
    t.category

ORDER BY
    net_loss DESC;