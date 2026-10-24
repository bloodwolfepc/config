#!/usr/bin/env python3
import csv
import re
import sys
from pathlib import Path

PACKAGE = re.compile(r"[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z0-9_]+)+")


def read_manifest(path: Path) -> set[str]:
    return {
        line
        for raw in path.read_text(encoding="utf-8").splitlines()
        if (line := raw.strip()) and not line.startswith("#")
    }


def read_export(path: Path) -> set[str]:
    with path.open(encoding="utf-8-sig", newline="") as source:
        rows = csv.reader(source)
        next(rows, None)
        packages = {row[1].strip() for row in rows if len(row) > 1 and PACKAGE.fullmatch(row[1].strip())}
    if not packages:
        raise ValueError("no package IDs found in column 2; export CSV with Package included")
    return packages


def print_group(title: str, packages: set[str]) -> None:
    print(f"{title} ({len(packages)}):")
    print("\n".join(f"  {package}" for package in sorted(packages)) or "  none")


def main() -> int:
    if len(sys.argv) != 3:
        print(f"usage: {Path(sys.argv[0]).name} MANIFEST APPLISTBACKUP.csv", file=sys.stderr)
        return 2
    try:
        declared = read_manifest(Path(sys.argv[1]))
        installed = read_export(Path(sys.argv[2]))
    except (OSError, UnicodeError, csv.Error, ValueError) as error:
        print(f"phone-app-audit: {error}", file=sys.stderr)
        return 2

    print_group("Declared and installed", declared & installed)
    print_group("Declared but missing", declared - installed)
    print_group("Installed but undeclared", installed - declared)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
