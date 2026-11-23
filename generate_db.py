#!/usr/bin/env python3

import argparse
import sqlite3
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_SQL = SCRIPT_DIR / "doomlauncher.sql"
DEFAULT_DB = SCRIPT_DIR / "doomlauncher.db"


def generate_db(sql_path: Path, db_path: Path) -> None:
    sql = sql_path.read_text(encoding="utf-8")

    if db_path.exists():
        db_path.unlink()

    con = sqlite3.connect(db_path)
    try:
        con.executescript(sql)
        con.commit()
    finally:
        con.close()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate a SQLite database from a SQL schema file."
    )
    parser.add_argument(
        "sql",
        nargs="?",
        type=Path,
        default=DEFAULT_SQL,
        help=f"input SQL file (default: {DEFAULT_SQL.name})",
    )
    parser.add_argument(
        "db",
        nargs="?",
        type=Path,
        default=DEFAULT_DB,
        help=f"output SQLite database (default: {DEFAULT_DB.name})",
    )
    args = parser.parse_args()

    if not args.sql.is_file():
        sys.exit(f"error: SQL file not found: {args.sql}")

    generate_db(args.sql, args.db)

    con = sqlite3.connect(args.db)
    con.execute("PRAGMA foreign_keys = ON")
    tables = [
        row[0]
        for row in con.execute(
            "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
        )
    ]
    fk_check = con.execute("PRAGMA foreign_key_check").fetchall()
    con.close()

    if fk_check:
        sys.exit("error: foreign key check failed")

    print(f"{args.db} generated from {args.sql}")
    print(f"tables: {', '.join(tables)}")


if __name__ == "__main__":
    main()
