-- ============================================================
-- 08_final_rule_results.sql
-- FINAL RULE PERFORMANCE
--
-- R001:
--   E-commerce
--   + Electronics / Gift Cards
--   + amount >= ₹20,000
--
-- R002:
--   E-commerce
--   + amount <= ₹50
--
-- IMPORTANT:
--   R002 is the low-value e-commerce card-testing candidate.
--   Velocity is analyzed separately as a supporting fraud signal.
--
-- Fraud label:
--   Confirmed chargebacks only.
--
-- Hidden simulation ground truth is NOT used here.
-- ============================================================


-- ============================================================
-- QUERY 1
-- R001 FULL-PERIOD PERFORMANCE
-- ============================================================

WITH rule_flags AS (

    SELECT
        t.txn_id,
        t.amount,

        CASE
            WHEN t.channel = 'E_COMMERCE'
             AND t.category IN ('Electronics', 'Gift Cards')
             AND t.amount >= 20000
            THEN 1
            ELSE 0
        END AS r001_alert,

        CASE
            WHEN cb.txn_id IS NOT NULL
            THEN 1
            ELSE 0
        END AS fraud_flag

    FROM fact_transaction t

    LEFT JOIN fact_chargeback cb
        ON t.txn_id = cb.txn_id
)

SELECT

    'R001' AS rule_id,

    'E-commerce + high-risk category + amount >= 20K'
        AS rule_name,

    SUM(r001_alert) AS alerts,

    SUM(
        CASE
            WHEN r001_alert = 1
             AND fraud_flag = 1
            THEN 1
            ELSE 0
        END
    ) AS fraud_caught,

    SUM(
        CASE
            WHEN r001_alert = 1
             AND fraud_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS legitimate_alerts,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN r001_alert = 1
                 AND fraud_flag = 1
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(SUM(r001_alert), 0),
        2
    ) AS precision_pct,

    ROUND(
        SUM(
            CASE
                WHEN r001_alert = 1
                 AND fraud_flag = 1
                THEN amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value_caught

FROM rule_flags;


-- ============================================================
-- QUERY 2
-- R002 FULL-PERIOD PERFORMANCE
--
-- Card-testing candidate:
-- E-commerce transactions with amount <= ₹50
-- ============================================================

WITH rule_flags AS (

    SELECT

        t.txn_id,
        t.amount,

        1 AS r002_alert,

        CASE
            WHEN cb.txn_id IS NOT NULL
            THEN 1
            ELSE 0
        END AS fraud_flag

    FROM fact_transaction t

    LEFT JOIN fact_chargeback cb
        ON t.txn_id = cb.txn_id

    WHERE t.channel = 'E_COMMERCE'
      AND t.amount <= 50
)

SELECT

    'R002' AS rule_id,

    'E-commerce card testing: amount <= ₹50'
        AS rule_name,

    SUM(r002_alert) AS alerts,

    SUM(
        CASE
            WHEN r002_alert = 1
             AND fraud_flag = 1
            THEN 1
            ELSE 0
        END
    ) AS fraud_caught,

    SUM(
        CASE
            WHEN r002_alert = 1
             AND fraud_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS legitimate_alerts,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN r002_alert = 1
                 AND fraud_flag = 1
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(SUM(r002_alert), 0),
        2
    ) AS precision_pct,

    ROUND(
        SUM(
            CASE
                WHEN r002_alert = 1
                 AND fraud_flag = 1
                THEN amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value_caught

FROM rule_flags;


-- ============================================================
-- QUERY 3
-- R001 MONTHLY STABILITY
-- ============================================================

WITH rule_flags AS (

    SELECT

        t.txn_id,
        t.txn_ts,
        t.amount,

        CASE
            WHEN t.channel = 'E_COMMERCE'
             AND t.category IN ('Electronics', 'Gift Cards')
             AND t.amount >= 20000
            THEN 1
            ELSE 0
        END AS r001_alert,

        CASE
            WHEN cb.txn_id IS NOT NULL
            THEN 1
            ELSE 0
        END AS fraud_flag

    FROM fact_transaction t

    LEFT JOIN fact_chargeback cb
        ON t.txn_id = cb.txn_id
)

SELECT

    strftime('%Y-%m', txn_ts) AS month,

    SUM(r001_alert) AS alerts,

    SUM(
        CASE
            WHEN r001_alert = 1
             AND fraud_flag = 1
            THEN 1
            ELSE 0
        END
    ) AS fraud_caught,

    SUM(
        CASE
            WHEN r001_alert = 1
             AND fraud_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS legitimate_alerts,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN r001_alert = 1
                 AND fraud_flag = 1
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(SUM(r001_alert), 0),
        2
    ) AS precision_pct,

    ROUND(
        SUM(
            CASE
                WHEN r001_alert = 1
                 AND fraud_flag = 1
                THEN amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value_caught

FROM rule_flags

GROUP BY strftime('%Y-%m', txn_ts)

ORDER BY month;


-- ============================================================
-- QUERY 4
-- R002 MONTHLY STABILITY
-- ============================================================

WITH rule_flags AS (

    SELECT

        t.txn_id,
        t.txn_ts,
        t.amount,

        1 AS r002_alert,

        CASE
            WHEN cb.txn_id IS NOT NULL
            THEN 1
            ELSE 0
        END AS fraud_flag

    FROM fact_transaction t

    LEFT JOIN fact_chargeback cb
        ON t.txn_id = cb.txn_id

    WHERE t.channel = 'E_COMMERCE'
      AND t.amount <= 50
)

SELECT

    strftime('%Y-%m', txn_ts) AS month,

    SUM(r002_alert) AS alerts,

    SUM(
        CASE
            WHEN r002_alert = 1
             AND fraud_flag = 1
            THEN 1
            ELSE 0
        END
    ) AS fraud_caught,

    SUM(
        CASE
            WHEN r002_alert = 1
             AND fraud_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS legitimate_alerts,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN r002_alert = 1
                 AND fraud_flag = 1
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(SUM(r002_alert), 0),
        2
    ) AS precision_pct,

    ROUND(
        SUM(
            CASE
                WHEN r002_alert = 1
                 AND fraud_flag = 1
                THEN amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_value_caught

FROM rule_flags

GROUP BY strftime('%Y-%m', txn_ts)

ORDER BY month;


-- ============================================================
-- QUERY 5
-- FINAL EXECUTIVE RULE COMPARISON
-- ============================================================

WITH r001 AS (

    SELECT

        COUNT(*) AS alerts,

        SUM(
            CASE
                WHEN cb.txn_id IS NOT NULL
                THEN 1
                ELSE 0
            END
        ) AS fraud_caught,

        SUM(
            CASE
                WHEN cb.txn_id IS NOT NULL
                THEN t.amount
                ELSE 0
            END
        ) AS fraud_value_caught

    FROM fact_transaction t

    LEFT JOIN fact_chargeback cb
        ON t.txn_id = cb.txn_id

    WHERE t.channel = 'E_COMMERCE'

      AND t.category IN (
          'Electronics',
          'Gift Cards'
      )

      AND t.amount >= 20000
),

r002 AS (

    SELECT

        COUNT(*) AS alerts,

        SUM(
            CASE
                WHEN cb.txn_id IS NOT NULL
                THEN 1
                ELSE 0
            END
        ) AS fraud_caught,

        SUM(
            CASE
                WHEN cb.txn_id IS NOT NULL
                THEN t.amount
                ELSE 0
            END
        ) AS fraud_value_caught

    FROM fact_transaction t

    LEFT JOIN fact_chargeback cb
        ON t.txn_id = cb.txn_id

    WHERE t.channel = 'E_COMMERCE'
      AND t.amount <= 50
)

SELECT

    'R001' AS rule_id,

    'High-risk e-commerce >= ₹20K'
        AS rule_name,

    alerts,

    fraud_caught,

    alerts - fraud_caught
        AS legitimate_alerts,

    ROUND(
        100.0 *
        fraud_caught
        / NULLIF(alerts, 0),
        2
    ) AS precision_pct,

    ROUND(
        fraud_value_caught,
        2
    ) AS fraud_value_caught

FROM r001

UNION ALL

SELECT

    'R002' AS rule_id,

    'Card testing: e-commerce <= ₹50'
        AS rule_name,

    alerts,

    fraud_caught,

    alerts - fraud_caught
        AS legitimate_alerts,

    ROUND(
        100.0 *
        fraud_caught
        / NULLIF(alerts, 0),
        2
    ) AS precision_pct,

    ROUND(
        fraud_value_caught,
        2
    ) AS fraud_value_caught

FROM r002;