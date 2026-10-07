-- ============================================================
-- 02_fraud_concentration.sql
-- Query 1: Fraud Concentration by Channel
-- ============================================================

SELECT
    channel,

    COUNT(*) AS transactions,

    ROUND(
        SUM(amount),
        2
    ) AS transaction_value,

    SUM(is_fraud) AS fraud_transactions,

    ROUND(
        SUM(
            CASE
                WHEN is_fraud = 1
                THEN amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value,

    ROUND(
        100.0 * SUM(is_fraud) / COUNT(*),
        2
    ) AS fraud_rate_pct,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN is_fraud = 1
                THEN amount
                ELSE 0
            END
        )
        / SUM(amount),
        2
    ) AS fraud_value_pct

FROM fact_transaction

GROUP BY channel

ORDER BY fraud_value DESC;



-- ============================================================
-- Query 2: Fraud Concentration by Category
-- ============================================================

SELECT
    category,

    COUNT(*) AS transactions,

    ROUND(
        SUM(amount),
        2
    ) AS transaction_value,

    SUM(is_fraud) AS fraud_transactions,

    ROUND(
        SUM(
            CASE
                WHEN is_fraud = 1
                THEN amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value,

    ROUND(
        100.0 * SUM(is_fraud) / COUNT(*),
        2
    ) AS fraud_rate_pct,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN is_fraud = 1
                THEN amount
                ELSE 0
            END
        )
        / SUM(amount),
        2
    ) AS fraud_value_pct

FROM fact_transaction

GROUP BY category

ORDER BY fraud_value DESC;


-- ============================================================
-- Query 3: Fraud Concentration by Transaction Amount
-- ============================================================

SELECT
    CASE
        WHEN amount < 500 THEN '0-500'
        WHEN amount < 1000 THEN '500-1K'
        WHEN amount < 5000 THEN '1K-5K'
        WHEN amount < 10000 THEN '5K-10K'
        WHEN amount < 25000 THEN '10K-25K'
        WHEN amount < 50000 THEN '25K-50K'
        WHEN amount < 100000 THEN '50K-100K'
        ELSE '100K+'
    END AS amount_band,

    COUNT(*) AS transactions,

    SUM(is_fraud) AS fraud_transactions,

    ROUND(
        SUM(amount),
        2
    ) AS transaction_value,

    ROUND(
        SUM(
            CASE
                WHEN is_fraud = 1
                THEN amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value,

    ROUND(
        100.0 * SUM(is_fraud) / COUNT(*),
        2
    ) AS fraud_rate_pct,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN is_fraud = 1
                THEN amount
                ELSE 0
            END
        )
        /
        (
            SELECT SUM(amount)
            FROM fact_transaction
            WHERE is_fraud = 1
        ),
        2
    ) AS fraud_value_share_pct

FROM fact_transaction

GROUP BY amount_band

ORDER BY
    CASE amount_band
        WHEN '0-500' THEN 1
        WHEN '500-1K' THEN 2
        WHEN '1K-5K' THEN 3
        WHEN '5K-10K' THEN 4
        WHEN '10K-25K' THEN 5
        WHEN '25K-50K' THEN 6
        WHEN '50K-100K' THEN 7
        WHEN '100K+' THEN 8
    END;




    -- ============================================================
-- QUERY 4: Fraud Concentration by Channel and Category
-- ============================================================

SELECT
    channel,
    category,

    COUNT(*) AS transactions,

    ROUND(
        SUM(amount),
        2
    ) AS transaction_value,

    SUM(is_fraud) AS fraud_transactions,

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
        2
    ) AS fraud_rate_pct,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN is_fraud = 1 THEN amount
                ELSE 0
            END
        )
        /
        (
            SELECT SUM(amount)
            FROM fact_transaction
            WHERE is_fraud = 1
        ),
        2
    ) AS fraud_value_share_pct

FROM fact_transaction

GROUP BY
    channel,
    category

ORDER BY
    fraud_value DESC;

-- ============================================================
-- QUERY 5: High-Value E-Commerce Risk Pattern
-- ============================================================

SELECT
    CASE
        WHEN amount >= 10000 THEN '10K+'
        ELSE '<10K'
    END AS amount_segment,

    COUNT(*) AS transactions,

    SUM(is_fraud) AS fraud_transactions,

    ROUND(
        SUM(amount),
        2
    ) AS transaction_value,

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
        2
    ) AS fraud_rate_pct,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN is_fraud = 1 THEN amount
                ELSE 0
            END
        )
        /
        (
            SELECT SUM(amount)
            FROM fact_transaction
            WHERE is_fraud = 1
        ),
        2
    ) AS fraud_value_share_pct

FROM fact_transaction

WHERE
    channel = 'E_COMMERCE'
    AND category IN ('Electronics', 'Gift Cards')

GROUP BY
    amount_segment

ORDER BY
    CASE
        WHEN amount_segment = '10K+' THEN 1
        ELSE 2
    END;    


-- ============================================================
-- QUERY 6: Fraud Rule Threshold Sweep
-- Pattern:
-- E_COMMERCE + Electronics/Gift Cards
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

)

SELECT
    t.threshold,

    COUNT(f.txn_id) AS alert_volume,

    SUM(f.is_fraud) AS fraud_transactions,

    COUNT(f.txn_id) - SUM(f.is_fraud) AS legitimate_transactions,

    ROUND(
        100.0 * SUM(f.is_fraud) / COUNT(f.txn_id),
        2
    ) AS precision_pct,

    ROUND(
        100.0 *
        (COUNT(f.txn_id) - SUM(f.is_fraud))
        / COUNT(f.txn_id),
        2
    ) AS false_positive_pct,

    ROUND(
        SUM(
            CASE
                WHEN f.is_fraud = 1 THEN f.amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value_caught,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN f.is_fraud = 1 THEN f.amount
                ELSE 0
            END
        )
        /
        (
            SELECT SUM(amount)
            FROM fact_transaction
            WHERE is_fraud = 1
        ),
        2
    ) AS fraud_value_coverage_pct

FROM thresholds t

LEFT JOIN fact_transaction f
    ON f.channel = 'E_COMMERCE'
    AND f.category IN ('Electronics', 'Gift Cards')
    AND f.amount >= t.threshold

GROUP BY
    t.threshold

ORDER BY
    t.threshold;

-- ============================================================
-- QUERY 7: Development vs Validation Threshold Performance
-- Development: Jan-Aug 2025
-- Validation: Sep-Dec 2025
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

base AS (

    SELECT
        txn_id,
        amount,
        is_fraud,
        CASE
            WHEN strftime('%m', txn_ts) BETWEEN '01' AND '08'
                THEN 'DEVELOPMENT'
            ELSE 'VALIDATION'
        END AS dataset_split

    FROM fact_transaction

    WHERE
        channel = 'E_COMMERCE'
        AND category IN ('Electronics', 'Gift Cards')
)

SELECT
    t.threshold,
    b.dataset_split,

    COUNT(b.txn_id) AS alert_volume,

    SUM(b.is_fraud) AS fraud_transactions,

    COUNT(b.txn_id) - SUM(b.is_fraud)
        AS legitimate_transactions,

    ROUND(
        100.0 * SUM(b.is_fraud) / COUNT(b.txn_id),
        2
    ) AS precision_pct,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN b.is_fraud = 1 THEN b.amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value_caught

FROM thresholds t

JOIN base b
    ON b.amount >= t.threshold

GROUP BY
    t.threshold,
    b.dataset_split

ORDER BY
    t.threshold,
    b.dataset_split;    