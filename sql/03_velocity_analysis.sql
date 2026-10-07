-- ============================================================
-- 03_velocity_analysis.sql
-- Credit Card Fraud Pattern and Loss Analysis
--
-- Purpose:
-- Analyze transaction velocity at card level over:
--   1. 10-minute windows
--   2. 1-hour windows
--   3. 24-hour windows
--
-- Business objective:
-- Determine whether unusually frequent transactions are
-- associated with confirmed fraud and whether velocity
-- should be used as a standalone fraud rule.
-- ============================================================


-- ============================================================
-- QUERY 1
-- Transaction velocity distribution
-- ============================================================

WITH velocity AS (
    SELECT
        t1.txn_id,
        t1.card_id,
        t1.txn_ts,
        t1.amount,
        t1.channel,
        t1.category,

        COUNT(t2.txn_id) AS transactions_previous_10m

    FROM fact_transaction t1

    LEFT JOIN fact_transaction t2
        ON t1.card_id = t2.card_id
        AND t2.txn_ts BETWEEN datetime(t1.txn_ts, '-10 minutes')
                          AND t1.txn_ts

    GROUP BY
        t1.txn_id,
        t1.card_id,
        t1.txn_ts,
        t1.amount,
        t1.channel,
        t1.category
)

SELECT
    CASE
        WHEN transactions_previous_10m = 1 THEN '1 transaction'
        WHEN transactions_previous_10m = 2 THEN '2 transactions'
        WHEN transactions_previous_10m >= 3 THEN '3+ transactions'
    END AS velocity_band,

    COUNT(*) AS transactions,

    SUM(
        CASE
            WHEN cb.confirmed_fraud_flag = 1 THEN 1
            ELSE 0
        END
    ) AS fraud_transactions,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS fraud_rate_pct,

    ROUND(
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1
                THEN t.amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value

FROM velocity v

JOIN fact_transaction t
    ON v.txn_id = t.txn_id

LEFT JOIN fact_chargeback cb
    ON t.txn_id = cb.txn_id

GROUP BY
    velocity_band

ORDER BY
    velocity_band;


-- ============================================================
-- QUERY 2
-- 1-hour velocity
-- ============================================================

WITH velocity AS (
    SELECT
        t1.txn_id,
        t1.card_id,
        t1.txn_ts,

        COUNT(t2.txn_id) AS transactions_previous_1h

    FROM fact_transaction t1

    LEFT JOIN fact_transaction t2
        ON t1.card_id = t2.card_id
        AND t2.txn_ts BETWEEN datetime(t1.txn_ts, '-1 hour')
                          AND t1.txn_ts

    GROUP BY
        t1.txn_id,
        t1.card_id,
        t1.txn_ts
)

SELECT
    CASE
        WHEN transactions_previous_1h = 1 THEN '1 transaction'
        WHEN transactions_previous_1h = 2 THEN '2 transactions'
        WHEN transactions_previous_1h = 3 THEN '3 transactions'
        WHEN transactions_previous_1h >= 4 THEN '4+ transactions'
    END AS velocity_band,

    COUNT(*) AS transactions,

    SUM(
        CASE
            WHEN cb.confirmed_fraud_flag = 1 THEN 1
            ELSE 0
        END
    ) AS fraud_transactions,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS fraud_rate_pct,

    ROUND(
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1
                THEN t.amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value

FROM velocity v

JOIN fact_transaction t
    ON v.txn_id = t.txn_id

LEFT JOIN fact_chargeback cb
    ON t.txn_id = cb.txn_id

GROUP BY
    velocity_band

ORDER BY
    velocity_band;


-- ============================================================
-- QUERY 3
-- 24-hour velocity
-- ============================================================

WITH velocity AS (
    SELECT
        t1.txn_id,
        t1.card_id,
        t1.txn_ts,

        COUNT(t2.txn_id) AS transactions_previous_24h

    FROM fact_transaction t1

    LEFT JOIN fact_transaction t2
        ON t1.card_id = t2.card_id
        AND t2.txn_ts BETWEEN datetime(t1.txn_ts, '-24 hours')
                          AND t1.txn_ts

    GROUP BY
        t1.txn_id,
        t1.card_id,
        t1.txn_ts
)

SELECT
    CASE
        WHEN transactions_previous_24h = 1 THEN '1 transaction'
        WHEN transactions_previous_24h = 2 THEN '2 transactions'
        WHEN transactions_previous_24h = 3 THEN '3 transactions'
        WHEN transactions_previous_24h BETWEEN 4 AND 5 THEN '4-5 transactions'
        WHEN transactions_previous_24h >= 6 THEN '6+ transactions'
    END AS velocity_band,

    COUNT(*) AS transactions,

    SUM(
        CASE
            WHEN cb.confirmed_fraud_flag = 1 THEN 1
            ELSE 0
        END
    ) AS fraud_transactions,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS fraud_rate_pct,

    ROUND(
        SUM(
            CASE
                WHEN cb.confirmed_fraud_flag = 1
                THEN t.amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value

FROM velocity v

JOIN fact_transaction t
    ON v.txn_id = t.txn_id

LEFT JOIN fact_chargeback cb
    ON t.txn_id = cb.txn_id

GROUP BY
    velocity_band

ORDER BY
    velocity_band;