-- ============================================================
-- 05_rule_simulation.sql
-- Credit Card Fraud Pattern and Loss Analysis
--
-- Purpose:
-- Simulate candidate fraud rules using confirmed fraud labels.
--
-- This SQL layer evaluates:
--   1. High-value thresholds
--   2. E-commerce + high-risk category combinations
--   3. R001 candidate rule
--
-- IMPORTANT:
-- Hidden sim_ground_truth is NOT used here.
-- Final validation happens separately in Python.
-- ============================================================


-- ============================================================
-- QUERY 1
-- High-value threshold sweep
--
-- This evaluates how fraud concentration changes as the
-- transaction-value threshold increases.
-- ============================================================

WITH thresholds AS (
    SELECT 10000 AS threshold
    UNION ALL
    SELECT 12500
    UNION ALL
    SELECT 15000
    UNION ALL
    SELECT 17500
    UNION ALL
    SELECT 20000
    UNION ALL
    SELECT 22500
    UNION ALL
    SELECT 25000
    UNION ALL
    SELECT 30000
    UNION ALL
    SELECT 40000
    UNION ALL
    SELECT 50000
),

transaction_base AS (
    SELECT
        t.txn_id,
        t.amount,

        CASE
            WHEN cb.confirmed_fraud_flag = 1
            THEN 1
            ELSE 0
        END AS is_fraud

    FROM fact_transaction t

    LEFT JOIN fact_chargeback cb
        ON t.txn_id = cb.txn_id
)

SELECT
    th.threshold,

    COUNT(
        CASE
            WHEN tb.amount >= th.threshold
            THEN tb.txn_id
        END
    ) AS alert_volume,

    SUM(
        CASE
            WHEN tb.amount >= th.threshold
             AND tb.is_fraud = 1
            THEN 1
            ELSE 0
        END
    ) AS fraud_transactions,

    SUM(
        CASE
            WHEN tb.amount >= th.threshold
             AND tb.is_fraud = 0
            THEN 1
            ELSE 0
        END
    ) AS legitimate_transactions,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN tb.amount >= th.threshold
                 AND tb.is_fraud = 1
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(
            COUNT(
                CASE
                    WHEN tb.amount >= th.threshold
                    THEN tb.txn_id
                END
            ),
            0
        ),
        2
    ) AS precision_pct,

    ROUND(
        SUM(
            CASE
                WHEN tb.amount >= th.threshold
                 AND tb.is_fraud = 1
                THEN tb.amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value_caught,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN tb.amount >= th.threshold
                 AND tb.is_fraud = 1
                THEN tb.amount
                ELSE 0
            END
        )
        / NULLIF(
            SUM(
                CASE
                    WHEN tb.is_fraud = 1
                    THEN tb.amount
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS fraud_value_coverage_pct

FROM thresholds th

CROSS JOIN transaction_base tb

GROUP BY
    th.threshold

ORDER BY
    th.threshold;


-- ============================================================
-- QUERY 2
-- E-commerce + high-risk category concentration
--
-- High-risk categories:
--   Electronics
--   Gift Cards
-- ============================================================

SELECT
    t.channel,

    CASE
        WHEN t.category IN ('Electronics', 'Gift Cards')
        THEN 'High-risk category'
        ELSE 'Other category'
    END AS category_group,

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
        )
        / COUNT(*),
        2
    ) AS fraud_rate_pct

FROM fact_transaction t

LEFT JOIN fact_chargeback cb
    ON t.txn_id = cb.txn_id

GROUP BY
    t.channel,
    category_group

ORDER BY
    fraud_value DESC;


-- ============================================================
-- QUERY 3
-- E-commerce + high-risk category + amount threshold
--
-- This evaluates the core R001 pattern at multiple thresholds.
-- ============================================================

WITH thresholds AS (
    SELECT 10000 AS threshold
    UNION ALL
    SELECT 12500
    UNION ALL
    SELECT 15000
    UNION ALL
    SELECT 17500
    UNION ALL
    SELECT 20000
    UNION ALL
    SELECT 22500
    UNION ALL
    SELECT 25000
    UNION ALL
    SELECT 30000
    UNION ALL
    SELECT 40000
    UNION ALL
    SELECT 50000
),

pattern_base AS (
    SELECT
        t.txn_id,
        t.amount,

        CASE
            WHEN cb.confirmed_fraud_flag = 1
            THEN 1
            ELSE 0
        END AS is_fraud

    FROM fact_transaction t

    LEFT JOIN fact_chargeback cb
        ON t.txn_id = cb.txn_id

    WHERE t.channel = 'E_COMMERCE'
      AND t.category IN ('Electronics', 'Gift Cards')
)

SELECT
    th.threshold,

    COUNT(
        CASE
            WHEN pb.amount >= th.threshold
            THEN pb.txn_id
        END
    ) AS alert_volume,

    SUM(
        CASE
            WHEN pb.amount >= th.threshold
             AND pb.is_fraud = 1
            THEN 1
            ELSE 0
        END
    ) AS fraud_transactions,

    SUM(
        CASE
            WHEN pb.amount >= th.threshold
             AND pb.is_fraud = 0
            THEN 1
            ELSE 0
        END
    ) AS legitimate_transactions,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN pb.amount >= th.threshold
                 AND pb.is_fraud = 1
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(
            COUNT(
                CASE
                    WHEN pb.amount >= th.threshold
                    THEN pb.txn_id
                END
            ),
            0
        ),
        2
    ) AS precision_pct,

    ROUND(
        SUM(
            CASE
                WHEN pb.amount >= th.threshold
                 AND pb.is_fraud = 1
                THEN pb.amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value_caught,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN pb.amount >= th.threshold
                 AND pb.is_fraud = 1
                THEN pb.amount
                ELSE 0
            END
        )
        / NULLIF(
            SUM(
                CASE
                    WHEN pb.is_fraud = 1
                    THEN pb.amount
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS pattern_fraud_value_coverage_pct

FROM thresholds th

CROSS JOIN pattern_base pb

GROUP BY
    th.threshold

ORDER BY
    th.threshold;


-- ============================================================
-- QUERY 4
-- Final R001 candidate rule
--
-- E_COMMERCE
-- AND (Electronics OR Gift Cards)
-- AND amount >= ₹20,000
-- ============================================================

WITH rule_base AS (
    SELECT
        t.txn_id,
        t.amount,

        CASE
            WHEN cb.confirmed_fraud_flag = 1
            THEN 1
            ELSE 0
        END AS is_fraud

    FROM fact_transaction t

    LEFT JOIN fact_chargeback cb
        ON t.txn_id = cb.txn_id

    WHERE t.channel = 'E_COMMERCE'
      AND t.category IN ('Electronics', 'Gift Cards')
      AND t.amount >= 20000
)

SELECT
    COUNT(*) AS alert_volume,

    SUM(
        CASE
            WHEN is_fraud = 1
            THEN 1
            ELSE 0
        END
    ) AS fraud_transactions,

    SUM(
        CASE
            WHEN is_fraud = 0
            THEN 1
            ELSE 0
        END
    ) AS legitimate_transactions,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN is_fraud = 1
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS precision_pct,

    ROUND(
        SUM(
            CASE
                WHEN is_fraud = 1
                THEN amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value_caught

FROM rule_base;


-- ============================================================
-- QUERY 5
-- R001 rule by month
--
-- Useful for understanding whether the candidate rule behaves
-- consistently across the year.
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