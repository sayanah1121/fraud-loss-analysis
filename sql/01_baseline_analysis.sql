-- ============================================================
-- 01_baseline_analysis.sql
-- Credit Card Fraud Pattern and Loss Analysis
-- ============================================================


-- ============================================================
-- QUERY 1: Overall Transaction & Fraud Baseline
-- ============================================================

SELECT
    COUNT(*) AS total_transactions,

    ROUND(SUM(amount), 2) AS total_transaction_value,

    ROUND(AVG(amount), 2) AS average_transaction_value,

    ROUND(
        SUM(is_fraud),
        0
    ) AS fraud_transactions,

    ROUND(
        SUM(
            CASE
                WHEN is_fraud = 1 THEN amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value,

    ROUND(
        100.0 * SUM(is_fraud) / COUNT(*),
        4
    ) AS fraud_rate_pct,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN is_fraud = 1 THEN amount
                ELSE 0
            END
        ) / SUM(amount),
        2
    ) AS fraud_value_pct

FROM fact_transaction;


-- ============================================================
-- QUERY 2: Chargeback Loss Baseline
-- ============================================================

SELECT
    COUNT(*) AS total_chargebacks,

    ROUND(
        SUM(loss_amount),
        2
    ) AS gross_chargeback_loss,

    ROUND(
        SUM(recovered_amount),
        2
    ) AS recovered_amount,

    ROUND(
        SUM(loss_amount - recovered_amount),
        2
    ) AS net_chargeback_loss,

    ROUND(
        100.0 *
        SUM(recovered_amount)
        / SUM(loss_amount),
        2
    ) AS recovery_rate_pct

FROM fact_chargeback;


-- ============================================================
-- QUERY 3: Monthly Fraud Trend
-- ============================================================

SELECT
    d.year,
    d.month,
    d.month_name,

    COUNT(ft.txn_id) AS total_transactions,

    SUM(ft.is_fraud) AS fraud_transactions,

    ROUND(
        SUM(ft.amount),
        2
    ) AS transaction_value,

    ROUND(
        SUM(
            CASE
                WHEN ft.is_fraud = 1
                THEN ft.amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value,

    ROUND(
        100.0 *
        SUM(ft.is_fraud)
        / COUNT(ft.txn_id),
        2
    ) AS fraud_rate_pct

FROM fact_transaction ft

JOIN dim_date d
    ON ft.date_key = d.date_key

GROUP BY
    d.year,
    d.month,
    d.month_name

ORDER BY
    d.year,
    d.month;