"""
Credit Card Fraud Pattern and Loss Analysis
--------------------------------------------

Synthetic data generator for the project.

Business purpose:
1. Understand fraud losses.
2. Discover fraud patterns.
3. Test fraud detection rules.

This script generates:
- Customers
- Cards
- Merchants
- Devices
- Transactions
- Fraud ground truth
- Chargebacks

Important:
sim_ground_truth.csv is kept separate from analytical data.
"""

from pathlib import Path

import numpy as np
import pandas as pd


# ============================================================
# CONFIGURATION
# ============================================================

RANDOM_SEED = 42

START_DATE = "2025-01-01"
END_DATE = "2025-12-31"

N_CUSTOMERS = 20_000
N_CARDS = 30_000
N_MERCHANTS = 2_000
N_DEVICES = 35_000
N_TRANSACTIONS = 1_500_000

TARGET_FRAUD_RATE = 0.007


# ============================================================
# REFERENCE DATA
# ============================================================

CITIES = [
    "Mumbai",
    "Delhi",
    "Bengaluru",
    "Bangalore",
    "Hyderabad",
    "Chennai",
    "Kolkata",
    "Pune",
    "Ahmedabad",
    "Jaipur",
    "Lucknow",
    "Chandigarh",
    "Surat",
    "Indore",
    "Nagpur",
]

CATEGORIES = [
    "Grocery",
    "Fuel",
    "Dining",
    "Travel",
    "Electronics",
    "Clothing",
    "Healthcare",
    "Entertainment",
    "Jewelry",
    "Gift Cards",
    "Online Services",
]

CHANNELS = [
    "POS",
    "E_COMMERCE",
    "CONTACTLESS",
    "ATM",
]

CARD_TYPES = [
    "CREDIT",
    "PREMIUM",
    "CORPORATE",
]

SEGMENTS = [
    "Mass",
    "Affluent",
    "Premium",
]

RISK_TIERS = [
    "LOW",
    "MEDIUM",
    "HIGH",
]


# ============================================================
# RANDOM NUMBER GENERATOR
# ============================================================

rng = np.random.default_rng(RANDOM_SEED)


# ============================================================
# CUSTOMER GENERATION
# ============================================================

def generate_customers():

    print("Generating customers...")

    customer_id = np.arange(
        1,
        N_CUSTOMERS + 1
    )

    age = rng.integers(
        21,
        70,
        N_CUSTOMERS
    )

    income = np.exp(
        rng.normal(
            np.log(700_000),
            0.55,
            N_CUSTOMERS
        )
    )

    home_city = rng.choice(
        CITIES,
        N_CUSTOMERS
    )

    segment = np.select(
        [
            income < 500_000,
            income < 1_200_000
        ],
        [
            "Mass",
            "Affluent"
        ],
        default="Premium"
    )

    age_band = pd.cut(
        age,
        bins=[20, 30, 40, 50, 60, 100],
        labels=[
            "21-30",
            "31-40",
            "41-50",
            "51-60",
            "61+"
        ]
    ).astype(str)

    income_band = pd.cut(
        income,
        bins=[
            0,
            400_000,
            800_000,
            1_500_000,
            np.inf
        ],
        labels=[
            "<4L",
            "4L-8L",
            "8L-15L",
            "15L+"
        ]
    ).astype(str)

    customers = pd.DataFrame({

        "customer_id": customer_id,

        "home_city": home_city,

        "age_band": age_band,

        "income_band": income_band,

        "tenure_months": rng.integers(
            1,
            121,
            N_CUSTOMERS
        ),

        "segment": segment,

        "typical_monthly_spend": np.round(
            np.maximum(
                2_000,
                income / rng.uniform(
                    18,
                    35,
                    N_CUSTOMERS
                )
            ),
            2
        ),

        "preferred_category": rng.choice(
            CATEGORIES[:5],
            N_CUSTOMERS
        ),

        "active_start_hour": rng.integers(
            6,
            11,
            N_CUSTOMERS
        ),

        "active_end_hour": rng.integers(
            20,
            24,
            N_CUSTOMERS
        )
    })

    return customers


# ============================================================
# CARD GENERATION
# ============================================================

def generate_cards(customers):

    print("Generating cards...")

    customer_ids = rng.choice(
        customers["customer_id"].values,
        N_CARDS
    )

    issue_dates = (
        pd.Timestamp(START_DATE)
        -
        pd.to_timedelta(
            rng.integers(
                0,
                900,
                N_CARDS
            ),
            unit="D"
        )
    )

    cards = pd.DataFrame({

        "card_id": np.arange(
            1,
            N_CARDS + 1
        ),

        "customer_id": customer_ids,

        "card_type": rng.choice(
            CARD_TYPES,
            N_CARDS,
            p=[
                0.72,
                0.20,
                0.08
            ]
        ),

        "issue_date": issue_dates.date,

        "credit_limit": rng.choice(
            [
                50_000,
                100_000,
                200_000,
                500_000,
                1_000_000
            ],
            N_CARDS,
            p=[
                0.30,
                0.35,
                0.20,
                0.10,
                0.05
            ]
        ),

        "status": rng.choice(
            [
                "ACTIVE",
                "BLOCKED"
            ],
            N_CARDS,
            p=[
                0.97,
                0.03
            ]
        )
    })

    return cards


# ============================================================
# MERCHANT GENERATION
# ============================================================

def generate_merchants():

    print("Generating merchants...")

    merchant_id = np.arange(
        1,
        N_MERCHANTS + 1
    )

    merchants = pd.DataFrame({

        "merchant_id": merchant_id,

        "merchant_name": [
            f"Merchant_{i:05d}"
            for i in merchant_id
        ],

        "category": rng.choice(
            CATEGORIES,
            N_MERCHANTS
        ),

        "city": rng.choice(
            CITIES,
            N_MERCHANTS
        ),

        "country": rng.choice(
            [
                "India",
                "USA",
                "UK",
                "Singapore",
                "UAE"
            ],
            N_MERCHANTS,
            p=[
                0.88,
                0.04,
                0.03,
                0.025,
                0.025
            ]
        ),

        "risk_tier": rng.choice(
            RISK_TIERS,
            N_MERCHANTS,
            p=[
                0.62,
                0.28,
                0.10
            ]
        )
    })

    return merchants


# ============================================================
# DEVICE GENERATION
# ============================================================

def generate_devices():

    print("Generating devices...")

    first_seen = (
        pd.Timestamp(START_DATE)
        -
        pd.to_timedelta(
            rng.integers(
                0,
                1_000,
                N_DEVICES
            ),
            unit="D"
        )
    )

    devices = pd.DataFrame({

        "device_id": np.arange(
            1,
            N_DEVICES + 1
        ),

        "device_type": rng.choice(
            [
                "ANDROID",
                "IOS",
                "WEB",
                "POS_TERMINAL",
                "ATM"
            ],
            N_DEVICES,
            p=[
                0.32,
                0.28,
                0.18,
                0.17,
                0.05
            ]
        ),

        "first_seen_date": first_seen.date
    })

    return devices


# ============================================================
# TRANSACTION GENERATION
# ============================================================

def generate_transactions(
    customers,
    cards,
    merchants,
    devices
):

    print("Generating transactions...")
    print("This may take a little time...")

    card_lookup = cards.set_index(
        "card_id"
    )

    merchant_lookup = merchants.set_index(
        "merchant_id"
    )

    card_ids = rng.choice(
        cards["card_id"].values,
        N_TRANSACTIONS
    )

    customer_ids = card_lookup.loc[
        card_ids,
        "customer_id"
    ].values

    merchant_ids = rng.choice(
        merchants["merchant_id"].values,
        N_TRANSACTIONS
    )

    device_ids = rng.choice(
        devices["device_id"].values,
        N_TRANSACTIONS
    )

    # Generate timestamps
    start_timestamp = pd.Timestamp(
        START_DATE
    ).value // 10**9

    end_timestamp = (
        pd.Timestamp(END_DATE)
        + pd.Timedelta(days=1)
    ).value // 10**9

    timestamps = pd.to_datetime(
        rng.integers(
            start_timestamp,
            end_timestamp,
            N_TRANSACTIONS
        ),
        unit="s"
    )

    # --------------------------------------------------------
    # Transaction amount
    # --------------------------------------------------------

    amounts = np.exp(
        rng.normal(
            np.log(1_400),
            1.0,
            N_TRANSACTIONS
        )
    )

    # Weekend uplift
    weekend = timestamps.dayofweek >= 5

    amounts *= np.where(
        weekend,
        1.12,
        1.0
    )

    # Festival / sale period
    festival_period = timestamps.month.isin(
        [10, 11]
    )

    amounts *= np.where(
        festival_period,
        1.20,
        1.0
    )

    amounts = np.clip(
        amounts,
        20,
        150_000
    )

    # --------------------------------------------------------
    # Channels
    # --------------------------------------------------------

    channels = rng.choice(
        CHANNELS,
        N_TRANSACTIONS,
        p=[
            0.42,
            0.38,
            0.12,
            0.08
        ]
    )

    # --------------------------------------------------------
    # IP country
    # --------------------------------------------------------

    ip_country = rng.choice(
        [
            "India",
            "USA",
            "UK",
            "Singapore",
            "UAE"
        ],
        N_TRANSACTIONS,
        p=[
            0.95,
            0.015,
            0.012,
            0.011,
            0.012
        ]
    )

    # --------------------------------------------------------
    # Authorization result
    # --------------------------------------------------------

    auth_result = rng.choice(
        [
            "APPROVED",
            "DECLINED"
        ],
        N_TRANSACTIONS,
        p=[
            0.965,
            0.035
        ]
    )

    transactions = pd.DataFrame({

        "txn_id": np.arange(
            1,
            N_TRANSACTIONS + 1
        ),

        "card_id": card_ids,

        "customer_id": customer_ids,

        "merchant_id": merchant_ids,

        "device_id": device_ids,

        "txn_ts": timestamps,

        "amount": np.round(
            amounts,
            2
        ),

        "channel": channels,

        "category": merchant_lookup.loc[
            merchant_ids,
            "category"
        ].values,

        "merchant_city": merchant_lookup.loc[
            merchant_ids,
            "city"
        ].values,

        "merchant_country": merchant_lookup.loc[
            merchant_ids,
            "country"
        ].values,

        "ip_country": ip_country,

        "auth_result": auth_result,

        "customer_home_city": card_lookup.loc[
            card_ids,
            "customer_id"
        ].map(
            customers.set_index(
                "customer_id"
            )["home_city"]
        ).values
    })

    return transactions


# ============================================================
# FRAUD PATTERN INJECTION
# ============================================================

def inject_fraud_patterns(
    transactions,
    merchants
):

    print("Injecting fraud patterns...")

    transactions = transactions.copy()

    fraud_count = int(
        len(transactions)
        * TARGET_FRAUD_RATE
    )

    fraud_typologies = [
        "card_testing",
        "account_takeover",
        "cnp_high_risk_merchant",
        "impossible_travel",
        "compromised_terminal",
        "cross_border_spike"
    ]

    weights = np.array([
        0.20,
        0.20,
        0.18,
        0.14,
        0.14,
        0.14
    ])

    counts = rng.multinomial(
        fraud_count,
        weights
    )

    available_rows = np.arange(
        len(transactions)
    )

    rng.shuffle(
        available_rows
    )

    assignments = []

    start = 0

    for typology, count in zip(
        fraud_typologies,
        counts
    ):

        selected = available_rows[
            start:start + count
        ]

        assignments.append(
            pd.DataFrame({
                "row_index": selected,
                "typology": typology
            })
        )

        start += count

    ground_truth = pd.concat(
        assignments,
        ignore_index=True
    )

    # --------------------------------------------------------
    # Apply fraud signatures
    # --------------------------------------------------------

    for typology in fraud_typologies:

        rows = ground_truth.loc[
            ground_truth["typology"] == typology,
            "row_index"
        ].values

        if len(rows) == 0:
            continue

        # --------------------------------------------
        # Card testing
        # --------------------------------------------

        if typology == "card_testing":

            transactions.loc[
                rows,
                "amount"
            ] = np.round(
                rng.uniform(
                    1,
                    50,
                    len(rows)
                ),
                2
            )

            transactions.loc[
                rows,
                "channel"
            ] = "E_COMMERCE"

        # --------------------------------------------
        # Account takeover
        # --------------------------------------------

        elif typology == "account_takeover":

            transactions.loc[
                rows,
                "amount"
            ] = np.clip(
                np.round(
                    rng.lognormal(
                        np.log(25_000),
                        0.7,
                        len(rows)
                    ),
                    2
                ),
                5_000,
                250_000
            )

            transactions.loc[
                rows,
                "channel"
            ] = "E_COMMERCE"

            transactions.loc[
                rows,
                "category"
            ] = rng.choice(
                [
                    "Electronics",
                    "Gift Cards"
                ],
                len(rows)
            )

        # --------------------------------------------
        # CNP high-risk merchant
        # --------------------------------------------

        elif typology == "cnp_high_risk_merchant":

            transactions.loc[
                rows,
                "channel"
            ] = "E_COMMERCE"

            transactions.loc[
                rows,
                "ip_country"
            ] = rng.choice(
                [
                    "USA",
                    "UK",
                    "Singapore",
                    "UAE"
                ],
                len(rows)
            )

        # --------------------------------------------
        # Impossible travel
        # --------------------------------------------

        elif typology == "impossible_travel":

            transactions.loc[
                rows,
                "amount"
            ] = np.clip(
                np.round(
                    rng.lognormal(
                        np.log(6_000),
                        0.8,
                        len(rows)
                    ),
                    2
                ),
                500,
                80_000
            )

        # --------------------------------------------
        # Compromised terminal
        # --------------------------------------------

        elif typology == "compromised_terminal":

            transactions.loc[
                rows,
                "amount"
            ] = np.clip(
                np.round(
                    rng.lognormal(
                        np.log(3_500),
                        0.9,
                        len(rows)
                    ),
                    2
                ),
                200,
                80_000
            )

        # --------------------------------------------
        # Cross-border spike
        # --------------------------------------------

        elif typology == "cross_border_spike":

            foreign_countries = [
                "USA",
                "UK",
                "Singapore",
                "UAE"
            ]

            foreign = rng.choice(
                foreign_countries,
                len(rows)
            )

            transactions.loc[
                rows,
                "ip_country"
            ] = foreign

            transactions.loc[
                rows,
                "merchant_country"
            ] = foreign

    ground_truth["txn_id"] = transactions.loc[
        ground_truth["row_index"],
        "txn_id"
    ].values

    ground_truth = ground_truth[
        [
            "txn_id",
            "typology"
        ]
    ]

    return transactions, ground_truth


# ============================================================
# CHARGEBACK GENERATION
# ============================================================

def generate_chargebacks(
    transactions,
    ground_truth
):

    print("Generating delayed chargebacks...")

    fraud_transactions = transactions[
        transactions["txn_id"].isin(
            ground_truth["txn_id"]
        )
    ][
        [
            "txn_id",
            "txn_ts",
            "amount"
        ]
    ].copy()

    delay_days = rng.integers(
        7,
        46,
        len(fraud_transactions)
    )

    fraud_transactions[
        "reported_date"
    ] = (
        fraud_transactions["txn_ts"]
        +
        pd.to_timedelta(
            delay_days,
            unit="D"
        )
    )

    fraud_transactions[
        "confirmed_fraud_flag"
    ] = True

    fraud_transactions[
        "loss_amount"
    ] = fraud_transactions[
        "amount"
    ].round(2)

    recovery_rate = rng.uniform(
        0,
        0.55,
        len(fraud_transactions)
    )

    fraud_transactions[
        "recovered_amount"
    ] = (
        fraud_transactions["loss_amount"]
        * recovery_rate
    ).round(2)

    return fraud_transactions[
        [
            "txn_id",
            "reported_date",
            "confirmed_fraud_flag",
            "loss_amount",
            "recovered_amount"
        ]
    ]


# ============================================================
# DATA QUALITY INJECTION
# ============================================================

def inject_data_quality_issues(
    transactions
):

    print("Injecting data-quality issues...")

    transactions = transactions.copy()

    # --------------------------------------------------------
    # Null device IDs
    # --------------------------------------------------------

    rows = rng.choice(
        transactions.index,
        size=int(
            len(transactions) * 0.002
        ),
        replace=False
    )

    transactions.loc[
        rows,
        "device_id"
    ] = np.nan

    # --------------------------------------------------------
    # Null IP country
    # --------------------------------------------------------

    rows = rng.choice(
        transactions.index,
        size=int(
            len(transactions) * 0.002
        ),
        replace=False
    )

    transactions.loc[
        rows,
        "ip_country"
    ] = np.nan

    # --------------------------------------------------------
    # Zero values
    # --------------------------------------------------------

    rows = rng.choice(
        transactions.index,
        size=int(
            len(transactions) * 0.0005
        ),
        replace=False
    )

    transactions.loc[
        rows,
        "amount"
    ] = 0

    # --------------------------------------------------------
    # Negative values
    # --------------------------------------------------------

    rows = rng.choice(
        transactions.index,
        size=int(
            len(transactions) * 0.0003
        ),
        replace=False
    )

    transactions.loc[
        rows,
        "amount"
    ] *= -1

    # --------------------------------------------------------
    # City spelling inconsistencies
    # --------------------------------------------------------

    rows = rng.choice(
        transactions.index,
        size=int(
            len(transactions) * 0.003
        ),
        replace=False
    )

    transactions.loc[
        rows,
        "customer_home_city"
    ] = transactions.loc[
        rows,
        "customer_home_city"
    ].replace({
        "Bengaluru": "Bangalore",
        "Bangalore": "BLR"
    })

    # --------------------------------------------------------
    # Duplicate transactions
    # --------------------------------------------------------

    duplicate_rows = rng.choice(
        transactions.index,
        size=int(
            len(transactions) * 0.001
        ),
        replace=False
    )

    duplicates = transactions.loc[
        duplicate_rows
    ].copy()

    transactions = pd.concat(
        [
            transactions,
            duplicates
        ],
        ignore_index=True
    )

    # --------------------------------------------------------
    # Orphan merchant IDs
    # --------------------------------------------------------

    rows = rng.choice(
        transactions.index,
        size=int(
            len(transactions) * 0.0003
        ),
        replace=False
    )

    transactions.loc[
        rows,
        "merchant_id"
    ] = 999_999

    return transactions


# ============================================================
# SAVE DATA
# ============================================================

def save_data(
    customers,
    cards,
    merchants,
    devices,
    transactions,
    ground_truth,
    chargebacks
):

    output_path = Path(
        "data/raw"
    )

    output_path.mkdir(
        parents=True,
        exist_ok=True
    )

    print("\nSaving files...")

    customers.to_csv(
        output_path / "customers.csv",
        index=False
    )

    cards.to_csv(
        output_path / "cards.csv",
        index=False
    )

    merchants.to_csv(
        output_path / "merchants.csv",
        index=False
    )

    devices.to_csv(
        output_path / "devices.csv",
        index=False
    )

    transactions.to_csv(
        output_path / "transactions.csv",
        index=False
    )

    ground_truth.to_csv(
        output_path / "sim_ground_truth.csv",
        index=False
    )

    chargebacks.to_csv(
        output_path / "chargebacks.csv",
        index=False
    )


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 60)
    print("CREDIT CARD FRAUD DATA GENERATOR")
    print("=" * 60)

    customers = generate_customers()

    cards = generate_cards(
        customers
    )

    merchants = generate_merchants()

    devices = generate_devices()

    transactions = generate_transactions(
        customers,
        cards,
        merchants,
        devices
    )

    transactions, ground_truth = (
        inject_fraud_patterns(
            transactions,
            merchants
        )
    )

    chargebacks = generate_chargebacks(
        transactions,
        ground_truth
    )

    transactions = inject_data_quality_issues(
        transactions
    )

    save_data(
        customers,
        cards,
        merchants,
        devices,
        transactions,
        ground_truth,
        chargebacks
    )

    print("\n" + "=" * 60)
    print("GENERATION COMPLETE")
    print("=" * 60)

    print(
        f"Customers       : {len(customers):,}"
    )

    print(
        f"Cards           : {len(cards):,}"
    )

    print(
        f"Merchants       : {len(merchants):,}"
    )

    print(
        f"Devices         : {len(devices):,}"
    )

    print(
        f"Transactions    : {len(transactions):,}"
    )

    print(
        f"Fraud records   : {len(ground_truth):,}"
    )

    print(
        f"Chargebacks     : {len(chargebacks):,}"
    )

    print(
        f"Fraud rate      : "
        f"{len(ground_truth) / len(transactions):.3%}"
    )

    print("\nFiles created in:")
    print("data/raw/")


if __name__ == "__main__":
    main()