"""App-closed, client-encrypted restic backups to Nextcloud. No automatic init."""

import argparse
import configparser
import fcntl
import json
import os
import shutil
import sqlite3
import subprocess
import sys
import time
from contextlib import closing
from pathlib import Path
from urllib.parse import quote

CONFIG_PATHS = (
    ".config/GIMP",
    ".local/share/krita",
    ".config/kritarc",
    ".config/kritadisplayrc",
    ".config/BeeRef/BeeRef.ini",
    ".config/ardour8",
    ".config/ardour9",
    ".config/falkTX",
    ".config/fcitx5",
    ".config/millennium/quick.css",
)
SQLITE_PATHS = (
    ".local/share/krita/resourcecache.sqlite",
    ".local/share/zathura/bookmarks.sqlite",
)
MINECRAFT_DIRECTORIES = (
    "saves",
    "config",
    "scripts",
    "kubejs",
    "screenshots",
    "mods",
    "resourcepacks",
    "shaderpacks",
    "datapacks",
)
# Steam's own preferences are read as JSON; Steam needn't be stopped for these.
BUSY_APPS = ".*(gimp|krita|beeref|ardour|prismlauncher|java).*"
PROFILE_PATHS = {
    "legcord": (".config/legcord",),
    "terraria": (
        ".local/share/Terraria",
        ".var/app/com.valvesoftware.Steam/data/Terraria",
    ),
    "anki": (".local/share/Anki2", ".config/Anki", ".config/Anki2"),
    "firefox": (".config/mozilla/firefox", ".mozilla/firefox"),
}
GROUP_BUSY_APPS = {
    "state": BUSY_APPS,
    "legcord": ".*[Ll]egcord.*",
    "terraria": "Terraria.*|tModLoader.*|dotnet|steam.*",
    "anki": ".*[Aa]nki.*|aqt.*",
    "firefox": ".*firefox.*",
}
PROFILE_CACHE_NAMES = {
    "legcord": {
        "Cache",
        "Code Cache",
        "GPUCache",
        "Crashpad",
        "DawnGraphiteCache",
        "DawnWebGPUCache",
        "logs",
        "VideoDecodeStats",
        "WebrtcVideoStats",
    },
    "anki": {"logs"},
    "firefox": {
        "cache2",
        "startupCache",
        "shader-cache",
        "thumbnails",
        "minidumps",
        "crashes",
        "Crash Reports",
        "Pending Pings",
        "firefox-mpris",
    },
    "terraria": set(),
}


def run(args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def copy_path(source, destination):
    if not source.exists() and not source.is_symlink():
        return False
    destination.parent.mkdir(parents=True, exist_ok=True)
    run(
        [
            "cp",
            "--archive",
            "--reflink=auto",
            "--no-dereference",
            "--",
            str(source),
            str(destination),
        ]
    )
    return True


def backup_sqlite(source, destination):
    if not source.is_file() or source.is_symlink():
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.parent.resolve() != destination.parent.absolute():
        raise ValueError(f"Refusing SQLite export through a symlink: {destination}")
    destination.unlink(missing_ok=True)
    for suffix in ("-wal", "-shm"):
        Path(str(destination) + suffix).unlink(missing_ok=True)
    with closing(
        sqlite3.connect(source.resolve().as_uri() + "?mode=ro", uri=True, timeout=30)
    ) as original:
        with closing(sqlite3.connect(destination)) as copied:
            original.backup(copied)
            if copied.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
                raise ValueError(f"SQLite backup failed integrity check: {source}")


def copy_profile(source, destination, group):
    if not source.exists():
        return
    source = source.resolve()
    if source.is_file():
        copy_path(source, destination)
        return

    def ignored(directory, names):
        current = Path(directory)
        runtime_level = current == source or (
            group == "firefox" and current.parent == source
        )
        return [
            name
            for name in names
            if (current / name).is_socket()
            or (
                runtime_level
                and (
                    name in PROFILE_CACHE_NAMES[group]
                    or name
                    in {
                        "SingletonCookie",
                        "SingletonLock",
                        "SingletonSocket",
                        ".parentlock",
                        "parent.lock",
                        "lock",
                    }
                    or name.startswith(".org.chromium.Chromium.")
                )
            )
        ]

    def copy_file(src, dst):
        copy_path(Path(src), Path(dst))
        return dst

    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(
        source,
        destination,
        symlinks=True,
        ignore=ignored,
        copy_function=copy_file,
    )


def validate_firefox_profiles(root):
    index = root / "profiles.ini"
    if not index.is_file():
        return
    profiles = configparser.ConfigParser(interpolation=None)
    profiles.read(index)
    for section in profiles.sections():
        if not section.startswith("Profile") or not profiles.has_option(
            section, "Path"
        ):
            continue
        path = Path(profiles.get(section, "Path"))
        path = (
            root / path
            if profiles.getboolean(section, "IsRelative", fallback=True)
            else path
        )
        if not path.resolve().is_relative_to(root.resolve()):
            raise ValueError(
                f"Firefox profile outside its backed-up root needs explicit inclusion: {path}"
            )


def prepare_profile_export(home, export, group):
    copied = False
    for relative in PROFILE_PATHS[group]:
        source = home / relative
        if not source.exists():
            continue
        if not source.resolve().is_relative_to(home.resolve()):
            raise ValueError(f"Profile outside home needs explicit inclusion: {source}")
        if group == "firefox":
            validate_firefox_profiles(source)
        if group == "anki" and source.is_dir():
            for profile in source.iterdir():
                if (profile / "collection.media").is_symlink() or (
                    profile.is_symlink() and (profile / "collection.anki2").exists()
                ):
                    raise ValueError(
                        f"Linked Anki profile/media needs explicit inclusion: {profile}"
                    )
        copy_profile(source, export / "home" / relative, group)
        copied = True
    if group == "terraria":
        # Steam-cloud saves can live in app userdata rather than the native save directory.
        for relative in (
            ".local/share/Steam",
            ".local/share/steamgames",
            ".var/app/com.valvesoftware.Steam/data/Steam",
        ):
            steam = home / relative
            userdata = steam / "userdata"
            if userdata.is_dir():
                for account in userdata.iterdir():
                    if not account.is_dir() or account.is_symlink():
                        continue
                    for app_id in ("105600", "1281930"):
                        source = account / app_id / "remote"
                        copied = (
                            copy_path(
                                source, export / "home" / source.relative_to(home)
                            )
                            or copied
                        )
            for app_id in ("105600", "1281930"):
                source = (
                    steam
                    / "steamapps/compatdata"
                    / app_id
                    / "pfx/drive_c/users/steamuser/Documents/My Games/Terraria"
                )
                copied = (
                    copy_path(source, export / "home" / source.relative_to(home))
                    or copied
                )
    if not copied:
        raise ValueError(
            f"No {group} profile/save data found; review configured source paths"
        )
    (export / "README.txt").write_text(
        f"Recovery group: {group}. Restore the home/ tree selectively with the application CLOSED.\n"
        "FULL PROFILES: passwords, cookies, tokens and private history may be present. Keep this restore private.\n"
        "Regenerable caches, diagnostics and runtime locks are excluded; SQLite databases and WAL files are preserved together.\n"
        "Symlinks are preserved, not dereferenced; external targets require their own backup.\n"
        "Authentication sessions may be device-bound or expired; signing in again may still be necessary.\n"
    )


def prepare_export(home, export, group="state"):
    export.mkdir(mode=0o700)
    if group != "state":
        prepare_profile_export(home, export, group)
        return
    for relative in CONFIG_PATHS:
        copy_path(home / relative, export / "home" / relative)
    for relative in SQLITE_PATHS:
        backup_sqlite(home / relative, export / "home" / relative)
    millennium = home / ".config/millennium/config.json"
    if millennium.is_file() and not millennium.is_symlink():
        data = json.loads(millennium.read_text())
        if not isinstance(data, dict):
            raise ValueError("Invalid Millennium configuration")
        # No proxy URL, username or password; no account/session caches.
        selected = {
            key: data[key]
            for key in ("general", "themes", "notifications", "plugins", "misc")
            if key in data
        }
        target = export / "home/.config/millennium/config.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(selected, indent=2) + "\n")
    copy_path(home / "projects/art", export / "home/projects/art")
    instances = home / ".local/share/PrismLauncher/instances"
    if instances.is_dir() and not instances.is_symlink():
        for instance in sorted(instances.iterdir()):
            if (
                not instance.is_dir()
                or instance.is_symlink()
                or instance.name.startswith(".")
            ):
                continue
            destination = (
                export / "home/.local/share/PrismLauncher/instances" / instance.name
            )
            for name in ("instance.cfg", "mmc-pack.json"):
                copy_path(instance / name, destination / name)
            for minecraft in (".minecraft", "minecraft"):
                root = instance / minecraft
                if root.is_symlink():
                    raise ValueError(
                        f"Minecraft directory is symlinked; backup its real location explicitly: {root}"
                    )
                for name in MINECRAFT_DIRECTORIES:
                    copy_path(root / name, destination / minecraft / name)
    (export / "README.txt").write_text(
        "Restore the home/ tree selectively with the corresponding apps closed.\n"
        "Millennium config.json is a sanitized subset: merge it, do not blindly replace a newer full config.\n"
        "Symlinks are preserved, not dereferenced; external targets require their own backup.\n"
        "Minecraft accounts, caches, libraries and downloaded game binaries are deliberately excluded.\n"
    )


def apps_busy(group="state"):
    result = subprocess.run(
        ["pgrep", "-i", "-u", str(os.getuid()), "-x", GROUP_BUSY_APPS[group]],
        capture_output=True,
        text=True,
    )
    if result.returncode not in (0, 1):
        raise ValueError("Could not check application activity")
    if result.returncode == 0:
        return True
    # Python/Electron launchers can retain the interpreter's process name.
    command_pattern = {
        "anki": r"(^|/)(\.?anki[^/ ]*)(\s|$)|(^|\s)-m\s+aqt(\s|$)",
        "legcord": r"/[^ ]*[Ll]egcord[^ ]*(\s|$)",
    }.get(group)
    if command_pattern:
        result = subprocess.run(
            ["pgrep", "-i", "-u", str(os.getuid()), "-f", command_pattern],
            capture_output=True,
            text=True,
        )
        if result.returncode not in (0, 1):
            raise ValueError(f"Could not check {group} activity")
        return result.returncode == 0
    return False


def configure_remote():
    username = Path(os.environ["ANGEL_BACKUP_USERNAME_FILE"]).read_text().rstrip("\r\n")
    password = (
        Path(os.environ["ANGEL_BACKUP_CLOUD_PASSWORD_FILE"]).read_text().rstrip("\r\n")
    )
    if (
        not username
        or ":" in username
        or not password
        or any(c in username + password for c in "\r\n")
    ):
        raise ValueError("Invalid Nextcloud credentials")
    obscured = run(
        ["rclone", "obscure", "-"],
        input=password + "\n",
        text=True,
        capture_output=True,
    ).stdout.strip()
    os.environ.update(
        {
            "RCLONE_CONFIG": "/dev/null",
            "RCLONE_CONFIG_ANGEL_TYPE": "webdav",
            "RCLONE_CONFIG_ANGEL_VENDOR": "nextcloud",
            "RCLONE_CONFIG_ANGEL_URL": "https://cloud.tinywolfe.net/remote.php/dav/files/"
            + quote(username, safe="")
            + "/",
            "RCLONE_CONFIG_ANGEL_USER": username,
            "RCLONE_CONFIG_ANGEL_PASS": obscured,
            "RESTIC_REPOSITORY": "rclone:angel:Backups/angel-state",
        }
    )
    if not Path(os.environ["RESTIC_PASSWORD_FILE"]).is_file():
        raise ValueError(
            "Restic SOPS secret is not available; complete enrollment first"
        )


def restic(*arguments, **kwargs):
    return run(["restic", *arguments], **kwargs)


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="angel-state-backup",
        description="Encrypted versioned Nextcloud backup of artwork, GUI state, Minecraft and selected full application profiles.",
        epilog="init is explicit and requires the SOPS password plus an independent recovery copy. Taskwarrior and dedicated credential stores remain excluded. Full-profile groups include login state.",
    )
    parser.add_argument(
        "--group",
        choices=tuple(GROUP_BUSY_APPS),
        default="state",
        help="independently scheduled and retained recovery group (default: state)",
    )
    parser.add_argument(
        "command",
        choices=("init", "backup", "scheduled", "snapshots", "check", "restore"),
    )
    parser.add_argument("restore_args", nargs="*", metavar="RESTORE_ARGUMENT")
    args = parser.parse_args(argv)
    if args.command == "restore":
        if len(args.restore_args) != 2:
            parser.error("restore requires SNAPSHOT NEW_DIRECTORY")
    elif args.restore_args:
        parser.error("extra arguments are only accepted by restore")
    tag = f"angel-{args.group}"
    os.umask(0o077)
    try:
        home = Path(os.environ["ANGEL_BACKUP_HOME"])
        base_state = Path(os.environ["ANGEL_BACKUP_STATE"])
        state = (
            base_state
            if args.group == "state"
            else base_state / "profiles" / args.group
        )
        if state.resolve() != state.absolute():
            raise ValueError("Backup state must not have symlinked ancestors")
        state.mkdir(parents=True, exist_ok=True, mode=0o700)
        os.chmod(base_state, 0o700)
        os.chmod(state, 0o700)
        with (base_state / "lock").open("a") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                print("Another Angel backup operation is running", file=sys.stderr)
                return 75
            export = state / "export"
            successful = state / "last-success"
            if args.command in ("backup", "scheduled"):
                if (
                    args.command == "scheduled"
                    and successful.exists()
                    and time.time() - successful.stat().st_mtime < 86400
                ):
                    print("A successful backup is less than 24 hours old")
                    return 0
                if apps_busy(args.group):
                    print(
                        f"Backup deferred for {args.group}: close its applications; other groups can still run",
                        file=sys.stderr,
                    )
                    return 75
            configure_remote()
            if args.command == "init":
                if not sys.stdin.isatty():
                    raise ValueError(
                        "Initialize from an interactive terminal after saving an independent recovery copy"
                    )
                if (
                    input(
                        "Type RECOVERY COPY SAVED to initialize the encrypted Nextcloud repository: "
                    )
                    != "RECOVERY COPY SAVED"
                ):
                    raise ValueError("Initialization cancelled")
                restic("init")
            elif args.command in ("snapshots", "check"):
                restic(
                    args.command,
                    *(
                        ["--host", "angel", "--tag", tag]
                        if args.command == "snapshots"
                        else []
                    ),
                )
            elif args.command == "restore":
                snapshot, destination_arg = args.restore_args
                if ":" in snapshot:
                    raise ValueError(
                        "Pass a snapshot ID or latest, not a snapshot subdirectory"
                    )
                destination = Path(destination_arg).absolute()
                if destination.exists() or destination.is_symlink():
                    raise ValueError("Restore destination must not already exist")
                restic(
                    "restore",
                    f"{snapshot}:{export}",
                    "--target",
                    str(destination),
                    "--host",
                    "angel",
                    "--tag",
                    tag,
                )
                print(
                    f"Restored to {destination}; inspect home/ before copying any files back"
                )
            else:
                if export.is_symlink():
                    raise ValueError("Backup export must not be a symlink")
                if export.exists():
                    shutil.rmtree(export)
                try:
                    prepare_export(home, export, args.group)
                    if apps_busy(args.group):
                        raise ValueError(
                            "An application opened during export; close it and retry"
                        )
                    restic("backup", "--host", "angel", "--tag", tag, str(export))
                    # Never prune after a partial backup or a failed integrity check.
                    restic("check")
                    restic(
                        "forget",
                        "--host",
                        "angel",
                        "--tag",
                        tag,
                        "--group-by",
                        "host,tags",
                        "--keep-daily",
                        "7",
                        "--keep-weekly",
                        "4",
                        "--keep-monthly",
                        "6",
                        "--prune",
                    )
                    restic("check")
                    successful.touch()
                finally:
                    if export.exists():
                        shutil.rmtree(export)
        return 0
    except (
        OSError,
        ValueError,
        KeyError,
        sqlite3.Error,
        configparser.Error,
        subprocess.CalledProcessError,
    ) as error:
        print(f"angel-state-backup: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
