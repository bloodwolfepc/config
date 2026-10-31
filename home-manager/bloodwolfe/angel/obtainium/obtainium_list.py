"""List installed apps from the newest Obtainium export in Nextcloud."""

import argparse
import base64
import json
import os
import posixpath
import sys
import tempfile
import unicodedata
import xml.etree.ElementTree as ET
from email.utils import parsedate_to_datetime
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import quote, unquote, urljoin, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

SERVER = "https://cloud.tinywolfe.net"
DAV = "{DAV:}"
PROPERTIES = b"""<d:propfind xmlns:d="DAV:"><d:prop>
<d:getlastmodified/><d:resourcetype/>
</d:prop></d:propfind>"""


class NoRedirects(HTTPRedirectHandler):
    # Never forward an authenticated request to a login page or another host.
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class Nextcloud:
    def __init__(self, username, password):
        self.root = (
            f"{SERVER}/remote.php/dav/files/{quote(username, safe='')}/droid-sync/"
        )
        self.authorization = (
            "Basic " + base64.b64encode(f"{username}:{password}".encode()).decode()
        )
        self.opener = build_opener(NoRedirects())

    def checked_url(self, href):
        url = urljoin(self.root, href)
        parts = urlsplit(url)
        root = urlsplit(self.root)
        path = posixpath.normpath(unquote(parts.path)) + "/"
        if (
            (parts.scheme, parts.netloc) != (root.scheme, root.netloc)
            or not path.startswith(posixpath.normpath(unquote(root.path)) + "/")
            or parts.query
            or parts.fragment
        ):
            raise ValueError("Nextcloud returned a path outside droid-sync")
        return url

    def request(self, url, *, listing=False):
        headers = {"Authorization": self.authorization}
        if listing:
            headers.update({"Depth": "1", "Content-Type": "application/xml"})
        request = Request(
            self.checked_url(url),
            headers=headers,
            data=PROPERTIES if listing else None,
            method="PROPFIND" if listing else "GET",
        )
        with self.opener.open(request, timeout=30) as response:
            return response.read()

    def exports(self):
        pending = [self.root]
        visited = set()
        exports = []
        while pending:
            directory = pending.pop()
            identity = posixpath.normpath(unquote(urlsplit(directory).path))
            if identity in visited:
                continue
            visited.add(identity)
            tree = ET.fromstring(self.request(directory, listing=True))
            for entry in tree.findall(f"{DAV}response"):
                href = entry.findtext(f"{DAV}href")
                if not href:
                    raise ValueError("Nextcloud directory entry has no path")
                url = self.checked_url(href)
                properties = None
                for propstat in entry.findall(f"{DAV}propstat"):
                    status = propstat.findtext(f"{DAV}status", "").split()
                    if len(status) > 1 and status[1] == "200":
                        properties = propstat.find(f"{DAV}prop")
                        break
                if properties is None:
                    raise ValueError("Could not read Nextcloud directory properties")
                if properties.find(f"{DAV}resourcetype/{DAV}collection") is not None:
                    pending.append(url.rstrip("/") + "/")
                elif unquote(urlsplit(url).path).lower().endswith(".json"):
                    modified = properties.findtext(f"{DAV}getlastmodified")
                    if not modified:
                        raise ValueError("Nextcloud export has no modification time")
                    exports.append((parsedate_to_datetime(modified).timestamp(), url))
        return sorted(exports, reverse=True)

    def latest(self):
        for _, url in self.exports():
            raw = self.request(url)
            data = json.loads(raw)
            apps = data.get("apps") if isinstance(data, dict) else data
            if not isinstance(apps, list):
                continue  # Other apps may also back up JSON to droid-sync.
            rows = installed_apps(apps)
            return unquote(urlsplit(url).path.rsplit("/", 1)[-1]), raw, rows
        raise ValueError("No Obtainium JSON exports found in Nextcloud droid-sync")


def installed_apps(apps):
    rows = []
    for app in apps:
        if (
            not isinstance(app, dict)
            or not all(
                isinstance(app.get(key), str) and app[key].strip()
                for key in ("id", "name", "url")
            )
            or "installedVersion" not in app
        ):
            raise ValueError(
                "Invalid Obtainium app entry (expected id, name, url, installedVersion)"
            )
        if app["installedVersion"] is None:
            continue
        url = urlsplit(app["url"])
        if (
            url.scheme not in ("http", "https")
            or not url.netloc
            or any(
                char.isspace() or unicodedata.category(char).startswith("C")
                for char in app["url"]
            )
        ):
            raise ValueError("Invalid application source URL in Obtainium export")
        settings = app.get("additionalSettings", {})
        if isinstance(settings, str):
            settings = json.loads(settings)
        if not isinstance(settings, dict):
            raise ValueError("Invalid additionalSettings in Obtainium export")
        name = settings.get("appName") or app["name"]
        if not isinstance(name, str):
            raise ValueError("Invalid application name in Obtainium export")
        rows.append((name, app["id"], app["url"]))
    return sorted(rows, key=lambda row: (row[0].casefold(), row[1]))


def printable(text):
    return " ".join(
        "".join(c for c in text if not unicodedata.category(c).startswith("C")).split()
    )


def width(text):
    return sum(
        0
        if unicodedata.combining(c)
        else 2
        if unicodedata.east_asian_width(c) in "WF"
        else 1
        for c in text
    )


def show_table(filename, rows, stream):
    rows = [tuple(printable(value) for value in row) for row in rows]
    headings = ("NAME", "PACKAGE NAME", "URL")
    widths = [max(width(row[i]) for row in [headings, *rows]) for i in range(2)]
    color = stream.isatty() and "NO_COLOR" not in os.environ

    def line(row, shade):
        text = "  ".join(
            value + " " * (widths[i] - width(value)) if i < 2 else value
            for i, value in enumerate(row)
        )
        print(f"\033[38;2;{shade}m{text}\033[0m" if color else text, file=stream)

    print(f"Obtainium Installed apps from {printable(filename)}:", file=stream)
    line(headings, "255;255;255")
    for row in rows:
        line(row, "160;112;160")


def export_latest(path, raw):
    # Link a complete private temporary file: atomic, with no overwrites or symlink following.
    with tempfile.NamedTemporaryFile(
        dir=path.parent, prefix=".obtainium-"
    ) as temporary:
        temporary.write(raw)
        temporary.flush()
        os.link(temporary.name, path)


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="droid-obtainium-list",
        description="List installed apps from the newest Obtainium JSON export in Nextcloud droid-sync (including subfolders).",
        epilog="Newest means server modification time. Only apps with a non-null installedVersion are listed. URL lists omit per-app settings; use the JSON export for a full restore. Exported JSON may contain secrets. Colours are terminal-only; NO_COLOR disables them.",
    )
    parser.add_argument(
        "--import-from-url-format",
        action="store_true",
        help="print only source URLs, one per line, for Obtainium's Import from URL list",
    )
    parser.add_argument(
        "--export-latest",
        metavar="PATH",
        type=Path,
        help="also save the original latest JSON to PATH (parent must exist; never overwrite)",
    )
    args = parser.parse_args(argv)
    try:
        if args.export_latest is not None:
            if args.export_latest.exists() or args.export_latest.is_symlink():
                raise ValueError(f"Refusing to overwrite {args.export_latest}")
            if not args.export_latest.parent.is_dir():
                raise ValueError(
                    f"Destination directory does not exist: {args.export_latest.parent}"
                )
        credentials = []
        for key in ("USERNAME", "PASSWORD"):
            path = os.environ.get(f"DROID_OBTAINIUM_{key}_FILE")
            if not path:
                raise ValueError(f"DROID_OBTAINIUM_{key}_FILE is not configured")
            value = Path(path).read_text().rstrip("\r\n")
            if not value or "\n" in value or "\r" in value:
                raise ValueError(f"Invalid Nextcloud {key.lower()} file")
            credentials.append(value)
        filename, raw, rows = Nextcloud(*credentials).latest()
        if args.export_latest is not None:
            export_latest(args.export_latest, raw)
            print(f"Saved {filename} to {args.export_latest}", file=sys.stderr)
        if args.import_from_url_format:
            for url in dict.fromkeys(row[2] for row in rows):
                print(url)
        else:
            show_table(filename, rows, sys.stdout)
        return 0
    except HTTPError as error:
        print(
            f"droid-obtainium-list: Nextcloud HTTP {error.code}; check credentials, permissions, and WebDAV access",
            file=sys.stderr,
        )
    except (OSError, URLError, ValueError, ET.ParseError) as error:
        print(f"droid-obtainium-list: {error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
