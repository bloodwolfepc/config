"""Translate explicitly submitted raw saves into a native Ludusavi restore.

No save-path database, transport, or filesystem restore implementation lives here.
"""

import datetime
import hashlib
import io
import json
import os
import re
from pathlib import Path, PurePosixPath
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import zipfile


def sync_directory(path):
    fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


class Refused(Exception):
    pass


def require(value, message):
    if not value:
        raise Refused(message)


def steam_running(proc=Path("/proc")):
    ancestors = {os.getpid()}
    pid = os.getppid()
    while pid > 1 and pid not in ancestors:
        ancestors.add(pid)
        try:
            pid = int(
                (proc / str(pid) / "stat").read_text().rsplit(")", 1)[1].split()[1]
            )
        except (OSError, ValueError, IndexError):
            break
    for item in proc.iterdir():
        if not item.name.isdigit() or int(item.name) in ancestors:
            continue
        try:
            if item.stat().st_uid != os.getuid():
                continue
            with (item / "environ").open("rb") as stream:
                values = stream.read(1024 * 1024).split(b"\0")
            if any(
                v.startswith((b"SteamAppId=", b"SteamGameId="))
                and v.split(b"=", 1)[1] not in (b"", b"0")
                for v in values
            ):
                return True
        except (FileNotFoundError, ProcessLookupError):
            continue
        except OSError:
            try:
                name = (item / "comm").read_text().strip()
                group = (item / "cgroup").read_text()
                # Known nondumpable session daemons cannot be game processes.
                if (
                    name in ("systemd", "(sd-pam)")
                    and group.rstrip().endswith("/init.scope")
                ) or (
                    name == "gamemoded"
                    and group.rstrip().endswith("/gamemoded.service")
                ):
                    continue
            except OSError:
                pass
            raise Refused(
                "Cannot inspect a same-user process; import/launch deferred"
            ) from None
    return False


class Receiver:
    def __init__(self, state, inbox, backups, native="ludusavi"):
        self.state, self.inbox, self.backups = map(Path, (state, inbox, backups))
        self.config = self.state / "native"
        self.native = native
        self.pending = self.state / "import-pending.json"

    def call(self, config, *args, api=True):
        # 0.31 backup IDs have one-second resolution, including locked versions.
        if args[0] == "backup" and "--force" in args:
            time.sleep(1.05)
        with tempfile.TemporaryFile() as out, tempfile.TemporaryFile() as err:
            result = subprocess.run(
                [self.native, "--config", str(config), "--no-manifest-update", *args],
                stdin=subprocess.DEVNULL,
                stdout=out,
                stderr=err,
                timeout=300,
                check=False,
            )
            require(
                result.returncode == 0,
                "Native Ludusavi failed; inspect its private log",
            )
            out.seek(0)
            raw = out.read(16 * 1024 * 1024 + 1)
        require(len(raw) <= 16 * 1024 * 1024, "Native response exceeds limit")
        if not api:
            return None
        data = json.loads(raw)
        require(
            isinstance(data, dict) and not data.get("errors"),
            "Native operation reported errors",
        )
        return data

    def game(self, data, title):
        games = data.get("games", {})
        require(set(games) == {title}, "Game title is unknown or ambiguous")
        game = games[title]
        require(game.get("decision") == "Processed", "Native scan was not processed")
        require(not game.get("registry"), "Registry imports are unsupported")
        require(
            not any(
                v.get("failed") or v.get("ignored")
                for v in game.get("files", {}).values()
            ),
            "Native operation was incomplete",
        )
        return game

    def receipt(self, digest):
        done = self.state / "received"
        done.mkdir(mode=0o700, exist_ok=True)
        return done / digest

    def identity(self, archive):
        title, separator, event = archive.stem.rpartition("--")
        require(
            separator
            and title
            and not any(ord(c) < 32 for c in title)
            and re.fullmatch(r"[A-Za-z0-9_-]{1,80}", event),
            "Use <exact native title>--<unique handoff ID>.zip",
        )
        return title, hashlib.sha256(archive.name.encode()).hexdigest()

    def apply(self, archive):
        title, event = self.identity(archive)
        with archive.open("rb") as stream:
            before = os.fstat(stream.fileno())
            raw = stream.read(256 * 1024 * 1024 + 1)
            after = os.fstat(stream.fileno())
        require(
            (before.st_ino, before.st_size, before.st_mtime_ns)
            == (after.st_ino, after.st_size, after.st_mtime_ns),
            "Archive is still changing",
        )
        require(len(raw) <= 256 * 1024 * 1024, "Archive exceeds 256 MiB")
        digest = hashlib.sha256(raw).hexdigest()
        if self.receipt(event).exists():
            require(
                self.receipt(event).read_text().strip() == digest,
                "A processed handoff ID was changed; submit a new unique filename",
            )
            return "already applied"
        # An explicit CLI title bypasses native cloud filtering; discover normally.
        discovery = self.call(
            self.config, "backup", "--preview", "--api", "--no-cloud-sync"
        )
        require(
            title in discovery.get("games", {}),
            "Game is not eligible for native automatic backup",
        )
        scan = self.game({"games": {title: discovery["games"][title]}}, title)
        targets = {}
        for name in scan.get("files", {}):
            path = Path(name)
            require(
                path.is_absolute() and path.resolve(strict=True) == path,
                "Non-canonical native destination",
            )
            info = path.lstat()
            require(
                stat.S_ISREG(info.st_mode) and info.st_uid == os.getuid(),
                "Destination is not an owned regular file",
            )
            require(
                path.name.lower() not in ("user.reg", "system.reg", "userdef.reg"),
                "Wine registry imports are unsupported",
            )
            targets.setdefault(path.name, []).append(path)
        require(
            targets,
            "No existing native save destinations; initialize the PC game first",
        )
        with tempfile.TemporaryDirectory(
            prefix="phone-import-", dir=self.state
        ) as temp:
            work = Path(temp)
            payload = work / "payload"
            payload.mkdir()
            redirects, sources, expected = [], [], set()
            with zipfile.ZipFile(io.BytesIO(raw)) as zipped:
                entries = [item for item in zipped.infolist() if not item.is_dir()]
                require(
                    0 < len(entries) <= 10000
                    and sum(item.file_size for item in entries) <= 512 * 1024 * 1024,
                    "Empty or oversized payload",
                )
                for index, item in enumerate(entries):
                    name = item.filename
                    mode = item.external_attr >> 16
                    require(
                        not name.startswith("/")
                        and "\\" not in name
                        and all(part not in ("", ".", "..") for part in name.split("/"))
                        and not any(ord(c) < 32 for c in name)
                        and (not stat.S_IFMT(mode) or stat.S_ISREG(mode)),
                        "Unsafe archive entry",
                    )
                    matches = targets.get(PurePosixPath(name).name, [])
                    require(
                        len(matches) == 1,
                        "Unrecognized or ambiguous filename; no guessing or numbered-export normalization",
                    )
                    target = str(matches[0])
                    require(target not in expected, "Duplicate destination in archive")
                    expected.add(target)
                    source = payload / str(index)
                    with zipped.open(item) as incoming, source.open("wb") as output:
                        shutil.copyfileobj(incoming, output)
                    sources.append(str(source))
                    redirects.append(
                        {"kind": "backup", "source": str(source), "target": target}
                    )
            # Ludusavi builds a disposable native backup with the approved PC paths.
            config = {
                "manifest": {"enable": False},
                "roots": [],
                "cloud": {"synchronize": False},
                "release": {"check": False},
                "customGames": [{"name": title, "files": sources}],
                "redirects": redirects,
            }
            (work / "config.yaml").write_text(json.dumps(config))
            candidate = work / "backup"
            self.game(
                self.call(
                    work,
                    "backup",
                    "--force",
                    "--api",
                    "--no-cloud-sync",
                    "--path",
                    str(candidate),
                    "--",
                    title,
                ),
                title,
            )
            preview = self.game(
                self.call(
                    work,
                    "restore",
                    "--preview",
                    "--api",
                    "--no-cloud-sync",
                    "--path",
                    str(candidate),
                    "--",
                    title,
                ),
                title,
            )
            require(
                set(preview.get("files", {})) == expected,
                "Native restore destination differs from approved discovery",
            )
            if not all(
                info.get("change") == "Same" for info in preview["files"].values()
            ):
                self.game(
                    self.call(
                        self.config,
                        "backup",
                        "--force",
                        "--api",
                        "--no-cloud-sync",
                        "--path",
                        str(self.backups),
                        "--",
                        title,
                    ),
                    title,
                )
                listing = self.call(
                    self.config,
                    "backups",
                    "--api",
                    "--path",
                    str(self.backups),
                    "--",
                    title,
                )
                versions = listing["games"][title]["backups"]
                require(versions, "No native recovery backup exists")
                # Pinned native API returns mapping order; latest is last, not max timestamp.
                recovery = versions[-1]["name"]
                self.call(
                    self.config,
                    "backups",
                    "edit",
                    "--path",
                    str(self.backups),
                    "--backup",
                    recovery,
                    "--lock",
                    "--",
                    title,
                    api=False,
                )
                locked = self.call(
                    self.config,
                    "backups",
                    "--api",
                    "--path",
                    str(self.backups),
                    "--",
                    title,
                )
                require(
                    any(
                        entry["name"] == recovery and entry["locked"]
                        for entry in locked["games"][title]["backups"]
                    ),
                    "Native recovery backup was not locked",
                )
                original = self.game(
                    self.call(
                        self.config,
                        "restore",
                        "--preview",
                        "--api",
                        "--no-cloud-sync",
                        "--path",
                        str(self.backups),
                        "--backup",
                        recovery,
                        "--",
                        title,
                    ),
                    title,
                )
                require(
                    set(original.get("files", {})) == set(scan["files"])
                    and all(
                        entry.get("change") == "Same"
                        for entry in original["files"].values()
                    ),
                    "Recovery backup does not match current PC state; import refused",
                )
                require(
                    not steam_running(), "A game started during staging; import refused"
                )
                with self.pending.open("x") as stream:
                    json.dump(
                        {
                            "game": title,
                            "archive": archive.name,
                            "sha256": digest,
                            "backup": recovery,
                            "recovery": "This native backup is locked; inspect native restore before clearing this marker",
                        },
                        stream,
                    )
                    stream.flush()
                    os.fsync(stream.fileno())
                sync_directory(self.state)
                restored = self.game(
                    self.call(
                        work,
                        "restore",
                        "--force",
                        "--api",
                        "--no-cloud-sync",
                        "--path",
                        str(candidate),
                        "--",
                        title,
                    ),
                    title,
                )
                require(
                    set(restored.get("files", {})) == expected,
                    "Native restore did not report every intended file",
                )
                verified = self.game(
                    self.call(
                        work,
                        "restore",
                        "--preview",
                        "--api",
                        "--no-cloud-sync",
                        "--path",
                        str(candidate),
                        "--",
                        title,
                    ),
                    title,
                )
                require(
                    set(verified.get("files", {})) == expected
                    and all(
                        entry.get("change") == "Same"
                        for entry in verified["files"].values()
                    ),
                    "Native restore verification failed; recovery checkpoint retained",
                )
                self.game(
                    self.call(
                        self.config,
                        "backup",
                        "--force",
                        "--api",
                        "--no-cloud-sync",
                        "--path",
                        str(self.backups),
                        "--",
                        title,
                    ),
                    title,
                )
            receipt = self.receipt(event)
            with receipt.open("w") as stream:
                stream.write(digest + "\n")
                stream.flush()
                os.fsync(stream.fileno())
            sync_directory(receipt.parent)
            self.pending.unlink(missing_ok=True)
            sync_directory(self.state)
        return "applied"

    def run(self, before_launch=False):
        require(
            not self.pending.exists(),
            "Interrupted import: inspect import-pending.json and native recovery before retrying",
        )
        if steam_running():
            require(not before_launch, "A Steam game is active; launch/import deferred")
            return {"state": "deferred: Steam game is running"}
        results = {}
        if self.inbox.exists():
            archives = sorted(self.inbox.glob("*.zip"))
            waiting = set()
            for archive in archives:
                require(
                    archive.is_file() and not archive.is_symlink(), "Unsafe inbox entry"
                )
                title, event = self.identity(archive)
                if not self.receipt(event).exists():
                    require(
                        title not in waiting,
                        "Multiple new handoffs for one game; choose one on Android",
                    )
                    waiting.add(title)
            for archive in archives:
                results[archive.name] = self.apply(archive)
        return results


def main():
    receiver = Receiver(
        os.environ["GAME_SAVES_STATE"],
        os.environ["GAME_SAVES_INBOX"],
        os.environ["GAME_SAVES_BACKUPS"],
        os.environ.get("GAME_SAVES_NATIVE", "ludusavi"),
    )
    try:
        result = receiver.run(before_launch="--before-launch" in sys.argv[1:])
        status = {"ok": True, "results": result}
        code = 0
    except (
        Refused,
        OSError,
        ValueError,
        KeyError,
        TypeError,
        subprocess.SubprocessError,
        zipfile.BadZipFile,
        RuntimeError,
    ) as error:
        status = {
            "ok": False,
            "error": str(error)
            if isinstance(error, Refused)
            else "Archive/native operation failed; inspect private state",
        }
        code = 1
    status["updated"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    directory = Path(os.environ["GAME_SAVES_STATUS"])
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    temporary = directory / ".angel.json.tmp"
    temporary.write_text(json.dumps(status, indent=2) + "\n")
    os.replace(temporary, directory / "angel.json")
    print(json.dumps(status))
    return code


if __name__ == "__main__":
    sys.exit(main())
