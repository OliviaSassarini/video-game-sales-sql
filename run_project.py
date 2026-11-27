"""
Builds the video game sales database and runs every analysis query.

Usage:
    python run_project.py

Needs only the Python standard library (no installs).
Expects the dataset at data/vgsales.csv (see README for where to get it).

Creates:
    video_games.db          the SQLite database
    outputs/<query>.csv     the result of each query in sql/03_analysis.sql
"""

import csv
import re
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CSV_PATH = ROOT / "data" / "vgsales.csv"
DB_PATH = ROOT / "video_games.db"
SQL_DIR = ROOT / "sql"
OUTPUT_DIR = ROOT / "outputs"

EXPECTED_COLUMNS = [
    "Rank", "Name", "Platform", "Year", "Genre", "Publisher",
    "NA_Sales", "EU_Sales", "JP_Sales", "Other_Sales", "Global_Sales",
]


def load_raw_csv(conn: sqlite3.Connection) -> int:
    """Load the CSV as-is into a staging table called raw_sales."""
    with open(CSV_PATH, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)
        missing = [c for c in EXPECTED_COLUMNS if c not in header]
        if missing:
            sys.exit(f"The CSV is missing these columns: {missing}")
        rows = [row for row in reader if row]

    conn.execute("DROP TABLE IF EXISTS raw_sales")
    columns = ", ".join(f'"{c}" TEXT' for c in header)
    conn.execute(f"CREATE TABLE raw_sales ({columns})")
    placeholders = ", ".join("?" for _ in header)
    conn.executemany(f"INSERT INTO raw_sales VALUES ({placeholders})", rows)
    return len(rows)


def run_sql_file(conn: sqlite3.Connection, filename: str) -> None:
    conn.executescript((SQL_DIR / filename).read_text(encoding="utf-8"))


def run_analysis(conn: sqlite3.Connection) -> None:
    """Run each '-- name:' query in 03_analysis.sql and save it as a CSV."""
    text = (SQL_DIR / "03_analysis.sql").read_text(encoding="utf-8")
    blocks = re.split(r"^-- name:\s*", text, flags=re.MULTILINE)[1:]
    OUTPUT_DIR.mkdir(exist_ok=True)

    for block in blocks:
        name, query = block.split("\n", 1)
        name = name.strip()
        cursor = conn.execute(query)
        headers = [d[0] for d in cursor.description]
        rows = cursor.fetchall()

        with open(OUTPUT_DIR / f"{name}.csv", "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(headers)
            writer.writerows(rows)

        print(f"\n=== {name} ({len(rows)} rows) ===")
        print(" | ".join(headers))
        for row in rows[:10]:
            print(" | ".join(str(v) for v in row))
        if len(rows) > 10:
            print(f"... {len(rows) - 10} more rows in outputs/{name}.csv")


def main() -> None:
    if not CSV_PATH.exists():
        sys.exit(f"Dataset not found. Download vgsales.csv and put it here: {CSV_PATH}")

    if DB_PATH.exists():
        DB_PATH.unlink()

    with sqlite3.connect(DB_PATH) as conn:
        n = load_raw_csv(conn)
        print(f"Loaded {n:,} raw rows from {CSV_PATH.name}")
        run_sql_file(conn, "01_schema.sql")
        run_sql_file(conn, "02_clean_and_load.sql")
        games = conn.execute("SELECT COUNT(*) FROM games").fetchone()[0]
        print(f"Cleaned and loaded {games:,} games into {DB_PATH.name}")
        run_analysis(conn)

    print(f"\nDone. Results saved in {OUTPUT_DIR.name}/")


if __name__ == "__main__":
    main()
