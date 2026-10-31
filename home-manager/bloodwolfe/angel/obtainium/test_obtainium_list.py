import contextlib
import io
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from urllib.error import HTTPError
from xml.sax.saxutils import escape

import obtainium_list as tool

APP = {
    "id": "net.example.app",
    "name": "Example",
    "url": "https://example.net/app",
    "installedVersion": "1.0",
    "additionalSettings": '{"appName": "Custom name"}',
}


def listing(*entries):
    responses = []
    for href, modified, directory in entries:
        responses.append(f"""<d:response><d:href>{escape(href)}</d:href>
<d:propstat><d:prop><d:resourcetype>{"<d:collection/>" if directory else ""}</d:resourcetype>
<d:getlastmodified>{modified}</d:getlastmodified></d:prop>
<d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>""")
    return (
        '<d:multistatus xmlns:d="DAV:">' + "".join(responses) + "</d:multistatus>"
    ).encode()


class Terminal(io.StringIO):
    def isatty(self):
        return True


class ObtainiumTests(unittest.TestCase):
    def setUp(self):
        self.cloud = tool.Nextcloud("internal-id", "not-a-real-password")
        self.root = self.cloud.root
        self.old = "Fri, 30 Oct 2026 08:00:00 GMT"
        self.new = "Fri, 30 Oct 2026 09:00:00 GMT"

    def test_recursive_latest_uses_modified_time_not_filename(self):
        newest = self.root + "obtainium/a%20backup.json"
        other = self.root + "other.json"
        older = self.root + "z-old.json"
        raw = json.dumps({"schemaVersion": 1, "apps": [APP]}).encode()
        responses = {
            self.root: listing(
                (self.root, self.old, True),
                (older, self.old, False),
                (self.root + "obtainium/", self.new, True),
                (other, "Fri, 30 Oct 2026 10:00:00 GMT", False),
            ),
            self.root + "obtainium/": listing(
                (self.root + "obtainium/", self.new, True), (newest, self.new, False)
            ),
            newest: raw,
            other: b'{"unrelated": true}',
        }
        with patch.object(
            self.cloud, "request", side_effect=lambda url, **kw: responses[url]
        ) as request:
            filename, received, rows = self.cloud.latest()
        self.assertEqual(filename, "a backup.json")
        self.assertEqual(received, raw)
        self.assertEqual(rows, [("Custom name", APP["id"], APP["url"])])
        self.assertEqual(request.call_count, 4)

    def test_legacy_list_and_uninstalled_filter(self):
        raw = json.dumps([APP, {**APP, "installedVersion": None}]).encode()
        with (
            patch.object(
                self.cloud, "exports", return_value=[(1, self.root + "legacy.json")]
            ),
            patch.object(self.cloud, "request", return_value=raw),
        ):
            self.assertEqual(len(self.cloud.latest()[2]), 1)

    def test_empty_directory_and_malformed_latest_fail(self):
        with patch.object(self.cloud, "exports", return_value=[]):
            with self.assertRaisesRegex(ValueError, "No Obtainium"):
                self.cloud.latest()
        with (
            patch.object(
                self.cloud, "exports", return_value=[(1, self.root + "bad.json")]
            ),
            patch.object(self.cloud, "request", return_value=b"{broken"),
        ):
            with self.assertRaises(ValueError):
                self.cloud.latest()
        with self.assertRaisesRegex(ValueError, "Invalid Obtainium app"):
            tool.installed_apps([{"id": "incomplete"}])

    def test_no_credential_forwarding_outside_root(self):
        for href in (
            "https://attacker.invalid/file.json",
            "/remote.php/dav/files/other/file.json",
            self.root + "../file.json",
            self.root + "%2e%2e/file.json",
            self.root + "file.json?redirect=elsewhere",
        ):
            with self.subTest(href=href), self.assertRaises(ValueError):
                self.cloud.checked_url(href)
        self.assertIsNone(
            tool.NoRedirects().redirect_request(
                None, None, 302, "", {}, "https://attacker.invalid"
            )
        )

    def test_private_export_preserves_bytes_and_never_overwrites(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "export.json"
            raw = b'{"apps": []}\n'
            tool.export_latest(path, raw)
            self.assertEqual(path.read_bytes(), raw)
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            with self.assertRaises(FileExistsError):
                tool.export_latest(path, b"replacement")
            self.assertEqual(path.read_bytes(), raw)
            symlink = Path(directory) / "link.json"
            symlink.symlink_to(path)
            with self.assertRaises(FileExistsError):
                tool.export_latest(symlink, b"replacement")
            self.assertEqual(
                sorted(p.name for p in Path(directory).iterdir()),
                ["export.json", "link.json"],
            )

    def test_aligned_columns_terminal_colours_and_no_color(self):
        rows = [
            ("应用", "com.short", "https://example.net/a"),
            ("Long app", "com.longer", "https://example.net/b"),
        ]
        plain = io.StringIO()
        tool.show_table("backup.json", rows, plain)
        lines = plain.getvalue().splitlines()
        self.assertNotIn("\033", plain.getvalue())
        self.assertIn("PACKAGE NAME", lines[1])
        self.assertEqual(
            tool.width(lines[1].split("PACKAGE NAME")[0]),
            tool.width(lines[2].split("com.short")[0]),
        )
        with patch.dict(os.environ, {}, clear=True):
            terminal = Terminal()
            tool.show_table("backup.json", rows, terminal)
            self.assertIn("\033[38;2;255;255;255mNAME", terminal.getvalue())
            self.assertIn("\033[38;2;160;112;160m应用", terminal.getvalue())
        with patch.dict(os.environ, {"NO_COLOR": ""}):
            terminal = Terminal()
            tool.show_table("backup.json", rows, terminal)
            self.assertNotIn("\033", terminal.getvalue())
        self.assertNotIn("\033", tool.printable("evil\033[31m\nname"))

    def test_help_requires_no_credentials(self):
        with (
            patch.dict(os.environ, {}, clear=True),
            contextlib.redirect_stdout(io.StringIO()) as out,
        ):
            with self.assertRaises(SystemExit) as result:
                tool.main(["--help"])
        self.assertEqual(result.exception.code, 0)
        self.assertIn("--export-latest PATH", out.getvalue())

    def test_cli_urls_only_and_export_can_be_combined(self):
        with tempfile.TemporaryDirectory() as directory:
            username = Path(directory) / "username"
            password = Path(directory) / "password"
            username.write_text("internal-id\n")
            password.write_text("app-password\n")
            target = Path(directory) / "export.json"
            env = {
                "DROID_OBTAINIUM_USERNAME_FILE": str(username),
                "DROID_OBTAINIUM_PASSWORD_FILE": str(password),
            }
            result = (
                "backup.json",
                b'{"apps": []}',
                [(APP["name"], APP["id"], APP["url"])] * 2,
            )
            with (
                patch.dict(os.environ, env),
                patch.object(tool.Nextcloud, "latest", return_value=result),
                contextlib.redirect_stdout(io.StringIO()) as out,
                contextlib.redirect_stderr(io.StringIO()) as err,
            ):
                status = tool.main(
                    ["--import-from-url-format", "--export-latest", str(target)]
                )
            self.assertEqual(status, 0)
            self.assertEqual(out.getvalue(), APP["url"] + "\n")
            self.assertIn("Saved backup.json", err.getvalue())
            self.assertEqual(target.read_bytes(), result[1])
            with (
                patch.dict(os.environ, env),
                patch.object(tool.Nextcloud, "latest") as latest,
                contextlib.redirect_stderr(io.StringIO()),
            ):
                self.assertEqual(tool.main(["--export-latest", str(target)]), 1)
                latest.assert_not_called()

    def test_http_error_is_actionable(self):
        with tempfile.TemporaryDirectory() as directory:
            secret = Path(directory) / "secret"
            secret.write_text("fake-value")
            env = {
                "DROID_OBTAINIUM_USERNAME_FILE": str(secret),
                "DROID_OBTAINIUM_PASSWORD_FILE": str(secret),
            }
            error = HTTPError(self.root, 401, "Unauthorized", {}, None)
            with (
                patch.dict(os.environ, env),
                patch.object(tool.Nextcloud, "latest", side_effect=error),
                contextlib.redirect_stderr(io.StringIO()) as err,
            ):
                self.assertEqual(tool.main([]), 1)
            self.assertIn("HTTP 401", err.getvalue())
            self.assertNotIn("fake-value", err.getvalue())


if __name__ == "__main__":
    unittest.main()
