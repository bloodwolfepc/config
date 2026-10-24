#!/usr/bin/env python3
import csv
import importlib.util
import os
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = Path(os.environ.get("APP_AUDIT_PATH", Path(__file__).with_name("app-audit.py")))
SPEC = importlib.util.spec_from_file_location("app_audit", MODULE_PATH)
assert SPEC and SPEC.loader
APP_AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(APP_AUDIT)


class AppAuditTest(unittest.TestCase):
    def test_reads_manifest_and_csv_package_column(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = root / "apps.txt"
            export = root / "apps.csv"
            manifest.write_text("# comment\ncom.example.one\n\ncom.example.missing\n")
            with export.open("w", newline="") as output:
                csv.writer(output).writerows(
                    [
                        ["Name", "Package", "Installer"],
                        ["App, with comma", "com.example.one", "com.android.vending"],
                        ["Undeclared", "org.example.two", "org.fdroid.fdroid"],
                    ]
                )
            self.assertEqual(APP_AUDIT.read_manifest(manifest), {"com.example.one", "com.example.missing"})
            self.assertEqual(APP_AUDIT.read_export(export), {"com.example.one", "org.example.two"})

    def test_rejects_export_without_package_column(self):
        with tempfile.TemporaryDirectory() as directory:
            export = Path(directory) / "apps.csv"
            export.write_text('"Name","System"\n"Example","false"\n')
            with self.assertRaisesRegex(ValueError, "Package included"):
                APP_AUDIT.read_export(export)


if __name__ == "__main__":
    unittest.main()
