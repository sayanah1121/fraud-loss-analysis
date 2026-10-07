-- ============================================================
-- 06_temporal_cohort_analysis.sql
-- Credit Card Fraud Pattern and Loss Analysis
--
-- Purpose:
-- Analyze fraud behavior over time and across card-age cohorts.
--
-- Analyses:
--   1. Monthly transaction/fraud trend
--   2. Monthly channel fraud trend
--   3. Card-age cohort analysis
--   4. Card-age cohort by fraud value
--   5. Monthly R001 candidate stability
--
-- IMPORTANT:
-- Hidden sim_ground_truth is NOT used here.
-- Confirmed chargebacks are the fraud reference.
-- ============================================================


-- ============================================================
-- QUERY 1
-- Monthly transaction and fraud trend
-- ============================================================

SELECT
    strftime('%Y-%m', t.txn_ts) AS transaction_month,

    COUNT(*) AS transactions,

    ROUND(
        SUM(t.amount),
        2
    ) AS transaction_value,

    SUM(
        CASE
            WHEN cb.confirmed_fraud_flag = 1
            THEN 1
            ELSE 0
        END
    ) AS fraud_transactions,

    ROUND(
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1
                THEN t.amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS fraud_rate_pct,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1
                THEN t.amount
                ELSE 0
            END
        )
        / NULLIF(SUM(t.amount), 0),
        2
    ) AS fraud_value_share_pct

FROM fact_transaction t

LEFT JOIN fact_chargeback cb
    ON t.txn_id = cb.txn_id

GROUP BY
    strftime('%Y-%m', t.txn_ts)

ORDER BY
    transaction_month;


-- ============================================================
-- QUERY 2
-- Monthly fraud trend by channel
-- ============================================================

SELECT
    strftime('%Y-%m', t.txn_ts) AS transaction_month,

    t.channel,

    COUNT(*) AS transactions,

    SUM(
        CASE
            WHEN cb.confirmed_fraud_flag = 1
            THEN 1
            ELSE 0
        END
    ) AS fraud_transactions,

    ROUND(
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1
                THEN t.amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS fraud_rate_pct

FROM fact_transaction t

LEFT JOIN fact_chargeback cb
    ON t.txn_id = cb.txn_id

GROUP BY
    strftime('%Y-%m', t.txn_ts),
    t.channel

ORDER BY
    transaction_month,
    fraud_value DESC;


-- ============================================================
-- QUERY 3
-- Card-age cohort analysis
--
-- Card age is calculated relative to the beginning of the
-- analytical transaction period.
-- ============================================================

WITH card_age AS (
    SELECT
        card_id,

        CASE
            WHEN julianday('2025-01-01') - julianday(issue_date) <= 30
                THEN '0-30 days'

            WHEN julianday('2025-01-01') - julianday(issue_date) <= 90
                THEN '31-90 days'

            WHEN julianday('2025-01-01') - julianday(issue_date) <= 180
                THEN '91-180 days'

            WHEN julianday('2025-01-01') - julianday(issue_date) <= 365
                THEN '181-365 days'

            WHEN julianday('2025-01-01') - julianday(issue_date) <= 730
                THEN '1-2 years'

            ELSE '2+ years'
        END AS card_age_band

    FROM dim_card
)

SELECT
    ca.card_age_band,

    COUNT(*) AS transactions,

    SUM(
        CASE
            WHEN cb.confirmed_fraud_flag = 1
            THEN 1
            ELSE 0
        END
    ) AS fraud_transactions,

    ROUND(
        SUM(t.amount),
        2
    ) AS transaction_value,

    ROUND(
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1
                THEN t.amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS fraud_rate_pct

FROM fact_transaction t

JOIN card_age ca
    ON t.card_id = ca.card_id

LEFT JOIN fact_chargeback cb
    ON t.txn_id = cb.txn_id

GROUP BY
    ca.card_age_band

ORDER BY
    CASE ca.card_age_band
        WHEN '0-30 days' THEN 1
        WHEN '31-90 days' THEN 2
        WHEN '91-180 days' THEN 3
        WHEN '181-365 days' THEN 4
        WHEN '1-2 years' THEN 5
        WHEN '2+ years' THEN 6
    END;


-- ============================================================
-- QUERY 4
-- Card-age cohort by channel
--
-- Helps determine whether young-card behavior becomes more
-- meaningful when combined with transaction channel.
-- ============================================================

WITH card_age AS (
    SELECT
        card_id,

        CASE
            WHEN julianday('2025-01-01') - julianday(issue_date) <= 30
                THEN '0-30 days'

            WHEN julianday('2025-01-01') - julianday(issue_date) <= 90
                THEN '31-90 days'

            WHEN julianday('2025-01-01') - julianday(issue_date) <= 180
                THEN '91-180 days'

            WHEN julianday('2025-01-01') - julianday(issue_date) <= 365
                THEN '181-365 days'

            WHEN julianday('2025-01-01') - julianday(issue_date) <= 730
                THEN '1-2 years'

            ELSE '2+ years'
        END AS card_age_band

    FROM dim_card
)

SELECT
    ca.card_age_band,

    t.channel,

    COUNT(*) AS transactions,

    SUM(
        CASE
            WHEN cb.confirmed_fraud_flag = 1
            THEN 1
            ELSE 0
        END
    ) AS fraud_transactions,

    ROUND(
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1
                THEN t.amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS fraud_rate_pct

FROM fact_transaction t

JOIN card_age ca
    ON t.card_id = ca.card_id

LEFT JOIN fact_chargeback cb
    ON t.txn_id = cb.txn_id

GROUP BY
    ca.card_age_band,
    t.channel

ORDER BY
    ca.card_age_band,
    fraud_value DESC;


-- ============================================================
-- QUERY 5
-- Monthly stability of the selected R001 candidate
--
-- R001:
-- E_COMMERCE
-- AND Electronics/Gift Cards
-- AND amount >= ₹20,000
-- ============================================================

SELECT
    strftime('%Y-%m', t.txn_ts) AS transaction_month,

    COUNT(*) AS alert_volume,

    SUM(
        CASE
            WHEN cb.confirmed_fraud_flag = 1
            THEN 1
            ELSE 0
        END
    ) AS fraud_transactions,

    SUM(
        CASE
            WHEN cb.confirmed_fraud_flag = 1
            THEN t.amount
            ELSE 0
        END
    ) AS fraud_value_caught,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS precision_pct

FROM fact_transaction t

LEFT JOIN fact_chargeback cb
    ON t.txn_id = cb.txn_id

WHERE t.channel = 'E_COMMERCE'
  AND t.category IN ('Electronics', 'Gift Cards')
  AND t.amount >= 20000

GROUP BY
    strftime('%Y-%m', t.txn_ts)

ORDER BY
    transaction_month;