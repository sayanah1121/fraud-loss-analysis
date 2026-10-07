import pandas as pd
from pathlib import Path


DATA_PATH = Path("data/raw")


def main():

    print("=" * 70)
    print("RAW DATA VALIDATION")
    print("=" * 70)

    files = [
        "customers.csv",
        "cards.csv",
        "merchants.csv",
        "devices.csv",
        "transactions.csv",
        "sim_ground_truth.csv",
        "chargebacks.csv",
    ]

    for file in files:

        path = DATA_PATH / file

        df = pd.read_csv(path)

        print(
            f"{file:<25} "
            f"rows = {len(df):>10,} "
            f"columns = {len(df.columns):>3}"
        )

    print("\n" + "=" * 70)
    print("TRANSACTION DATA QUALITY")
    print("=" * 70)

    tx = pd.read_csv(
        DATA_PATH / "transactions.csv"
    )

    print("\nMissing values:")

    missing = (
        tx.isnull()
        .sum()
        .sort_values(
            ascending=False
        )
    )

    print(
        missing[
            missing > 0
        ]
    )

    print("\nDuplicate rows:")

    print(
        tx.duplicated().sum()
    )

    print("\nInvalid amounts:")

    invalid_amounts = (
        tx["amount"] <= 0
    ).sum()

    print(
        invalid_amounts
    )

    print("\nOrphan merchant IDs:")

    merchants = pd.read_csv(
        DATA_PATH / "merchants.csv",
        usecols=["merchant_id"]
    )

    valid_merchants = set(
        merchants["merchant_id"]
    )

    orphan_count = (
        ~tx["merchant_id"]
        .isin(valid_merchants)
    ).sum()

    print(
        orphan_count
    )

    print("\n" + "=" * 70)
    print("GROUND TRUTH")
    print("=" * 70)

    ground_truth = pd.read_csv(
        DATA_PATH / "sim_ground_truth.csv"
    )

    print(
        ground_truth[
            "typology"
        ].value_counts()
    )

    print("\n" + "=" * 70)
    print("CHARGEBACK DELAY")
    print("=" * 70)

    chargebacks = pd.read_csv(
        DATA_PATH / "chargebacks.csv"
    )

    tx["txn_ts"] = pd.to_datetime(
        tx["txn_ts"],
        errors="coerce"
    )

    chargebacks["reported_date"] = pd.to_datetime(
        chargebacks["reported_date"],
        errors="coerce"
    )

    joined = chargebacks.merge(
        tx[
            [
                "txn_id",
                "txn_ts"
            ]
        ],
        on="txn_id",
        how="left"
    )

    joined["delay_days"] = (
        joined["reported_date"]
        - joined["txn_ts"]
    ).dt.days

    print(
        joined["delay_days"]
        .describe()
    )


if __name__ == "__main__":
    main()