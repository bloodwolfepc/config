"""Angel's SSH client for the pinned, migration-gated music workbench."""

import argparse
import getpass
import json
import os
from pathlib import Path, PurePosixPath
import re
import shlex
import stat
import subprocess
import sys
import tarfile
import tempfile
from urllib.parse import urlsplit
import uuid

TARGET = "bloodwolfe@srv-vm.srvctl.ts.net"
SSH_OPTIONS = []
HOST_COMMANDS = {
    "version", "check", "acquire", "receive", "extract", "import", "albums",
    "review", "status", "publish", "unpublish", "resume", "purge", "cache-clean",
}
RECOVERY = {"status", "unpublish", "purge"}
MAX_FILES = 10000
MAX_BYTES = 20 * 1024**3
MIGRATION = (
    "Deploy the compatible srv music workbench first: stop/migrate the legacy "
    "auto-sharing publisher to its approved-only read-only share, then recreate "
    "only the pinned music-editor. Do not import into the legacy workflow."
)


class Failure(Exception):
    pass


class Parser(argparse.ArgumentParser):
    def error(self, message):
        # argparse's default error can echo a signed URL from an invalid invocation.
        raise Failure("Invalid arguments; use edit-music --help (input values omitted).")


def remote(arguments, *, tty=False, source=None, batch=True):
    options = ["-t"] if tty else ["-T", "-o", "BatchMode=yes" if batch else "BatchMode=no"]
    command = ["ssh", *SSH_OPTIONS, *options, "--", TARGET, shlex.join(arguments)]
    if tty:
        if not sys.stdin.isatty() or not sys.stdout.isatty():
            raise Failure("This operation needs an existing terminal; uploads use a separate noninteractive SSH session.")
        result = subprocess.run(command, check=False)
    else:
        result = subprocess.run(
            command, stdin=source if source is not None else subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False,
        )
    if result.returncode:
        # Never echo remote argv/stderr: download errors may contain credentials/URLs.
        raise Failure("Remote operation failed (details omitted). Check SSH authentication and backend readiness; inspect edit-music --status before retrying a publication. " + MIGRATION)
    return None if tty else result.stdout.decode("utf-8")


def backend(*arguments, **kwargs):
    return remote(["srv-music-workbench", *arguments], **kwargs)


def compatibility(action, *, batch=True):
    try:
        version = json.loads(backend("version", batch=batch))
        if (type(version.get("version")) is not int or version["version"] != 1
                or version.get("backend") != "srv-music-workbench"
                or not HOST_COMMANDS <= set(version.get("commands", []))):
            raise ValueError("incompatible protocol")
        if action not in RECOVERY:
            check = json.loads(backend("check", batch=batch))
            if (type(check.get("version")) is not int or check["version"] != 1
                    or check.get("protocol") != "music-workbench"):
                raise ValueError("incompatible running editor")
    except (ValueError, TypeError, AttributeError, Failure):
        raise Failure("Backend missing, incompatible, stale, or migration not ready. " + MIGRATION) from None


def pretty(document):
    def redact(value):
        if isinstance(value, dict):
            return {key: "[redacted]" if key.lower() in {"url", "password", "token", "basis"}
                    else redact(item) for key, item in value.items()}
        if isinstance(value, list):
            return [redact(item) for item in value]
        if isinstance(value, str):
            return re.sub(r"https?://[^\s<>]+", "[URL redacted]", value)
        return value
    print(json.dumps(redact(json.loads(document)), ensure_ascii=False, indent=2))


def staging_path(value):
    path = PurePosixPath(value)
    if (not value.startswith("/workspace/staging/") or ".." in path.parts
            or any(ord(char) < 32 or ord(char) == 127 for char in value)):
        raise Failure("Expected the absolute /workspace/staging/... path returned by the backend.")
    return value


def archive_input(value, output):
    """Spool a validated tar before SSH; dirfd traversal never follows input links."""
    source = Path(os.path.abspath(Path(value).expanduser()))
    if source.is_symlink():
        raise Failure("Local input links are not supported; select the original file/directory.")
    if not source.name:
        raise Failure("Refusing to transfer a filesystem root.")
    source = source.parent.resolve(strict=True) / source.name
    count = total = 0
    flags = os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK

    def add(archive, parent, name, member):
        nonlocal count, total
        if (name in {".", ".."} or "\\" in name
                or any(ord(char) < 32 or ord(char) == 127 for char in name)):
            raise Failure("Local input has an unsupported archive member name.")
        fd = os.open(name, flags, dir_fd=parent)
        try:
            metadata = os.fstat(fd)
            directory = stat.S_ISDIR(metadata.st_mode)
            if not directory and not stat.S_ISREG(metadata.st_mode):
                raise Failure("Local inputs must contain only regular files and directories, not links/special files.")
            count += 1
            total += 0 if directory else metadata.st_size
            if count > MAX_FILES or total > MAX_BYTES:
                raise Failure("Local input exceeds the backend's 10,000 entry / 20 GiB limit.")
            entry = tarfile.TarInfo(member)
            entry.mode = stat.S_IMODE(metadata.st_mode) & 0o777
            entry.mtime = int(metadata.st_mtime)
            entry.type = tarfile.DIRTYPE if directory else tarfile.REGTYPE
            entry.size = 0 if directory else metadata.st_size
            if directory:
                archive.addfile(entry)
                for child in sorted(os.listdir(fd)):
                    add(archive, fd, child, member + "/" + child)
            else:
                with os.fdopen(os.dup(fd), "rb") as data:
                    archive.addfile(entry, data)
        finally:
            os.close(fd)

    with tarfile.open(fileobj=output, mode="w|") as archive:
        parent = os.open(source.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            add(archive, parent, source.name, source.name)
        finally:
            os.close(parent)
    output.seek(0)


def parser():
    result = Parser(description="Private music staging and explicit approved publication. No arguments: normal Starship/zsh editor.")
    actions = result.add_mutually_exclusive_group()
    for name in ("dl", "extract", "import", "review", "publish", "unpublish", "resume", "purge"):
        actions.add_argument("--" + name, dest=name.replace("-", "_"), metavar="INPUT")
    for name in ("status", "albums", "cache-clean", "check"):
        actions.add_argument("--" + name, action="store_true")
    result.add_argument("--name", help="Destination basename for an HTTPS acquisition only")
    result.add_argument("--basis", help="Private permission/license basis (prefer the hidden interactive prompt)")
    result.add_argument("--attribution", help="Deliberately PUBLIC attribution text")
    result.add_argument("--replace", help="Explicit publication ID to replace")
    result.add_argument("--yes", action="store_true", help="Explicit noninteractive approval of this one --publish album")
    return result


def main(argv=None):
    args = parser().parse_args(argv)
    action = next((name for name in ("dl", "extract", "import", "review", "publish", "unpublish", "resume", "purge", "status", "albums", "cache_clean", "check")
                   if getattr(args, name) is not None and getattr(args, name) is not False), "shell").replace("_", "-")
    if action != "shell" and getattr(args, action.replace("-", "_")) == "":
        raise Failure("Operation input must not be empty.")
    if action != "publish" and any((args.basis is not None, args.attribution is not None, args.replace is not None, args.yes)):
        raise Failure("Publication options require an explicit --publish ALBUM_ID.")
    if args.name is not None and action != "dl":
        raise Failure("--name requires --dl with an HTTPS URL.")
    interactive = action in {"shell", "import"} or (action == "publish" and not args.yes)
    if not interactive:
        compatibility(action)
        operate(args, action)
        return
    if not sys.stdin.isatty() or not sys.stdout.isatty():
        raise Failure("This operation needs an existing terminal; transfers and prompts use separate SSH sessions.")
    # Authenticate on a data-free check, then reuse its private socket for BatchMode transfers.
    with tempfile.TemporaryDirectory(prefix="edit-music-ssh-", dir="/tmp") as directory:
        socket = directory + "/socket"
        SSH_OPTIONS[:] = ["-o", "ControlMaster=auto", "-o", "ControlPersist=60", "-S", socket]
        try:
            compatibility(action, batch=False)
            operate(args, action)
        finally:
            subprocess.run(["ssh", "-S", socket, "-O", "exit", "-o", "BatchMode=yes", "--", TARGET],
                           stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
            SSH_OPTIONS.clear()


def operate(args, action):
    if action == "shell":
        if not sys.stdin.isatty() or not sys.stdout.isatty():
            raise Failure("Open the normal editor in an existing terminal.")
        theme = Path(os.environ.get("STARSHIP_CONFIG", Path.home() / ".config/starship.toml"))
        if not theme.is_file():
            raise Failure("Missing Starship configuration; set STARSHIP_CONFIG or ~/.config/starship.toml. Backend operations do not need a theme.")
        with theme.open("rb") as stream:
            remote(["srv-compose", "--services-root", "/etc/srv/services/arr", "exec", "-T", "music-editor", "tee", "/config/starship.toml"], source=stream)
        remote(["srv-compose", "--services-root", "/etc/srv/services/arr", "exec", "music-editor", "zsh", "-l"], tty=True)
    elif action == "dl":
        value = args.dl
        parts = urlsplit(value)
        if "://" in value or value.startswith("//"):
            if parts.scheme != "https" or not parts.hostname or parts.username or parts.password or any(ord(c) < 32 for c in value):
                raise Failure("Use a direct HTTPS file URL without embedded credentials, or a local path.")
            command = ["acquire", value]
            if args.name is not None:
                command += ["--name=" + args.name]
            returned = backend(*command)
        else:
            if args.name is not None:
                raise Failure("Local uploads use a unique job name; --name is HTTPS-only.")
            with tempfile.TemporaryFile() as stream:
                archive_input(value, stream)
                returned = backend("receive", "--name", "angel-" + uuid.uuid4().hex, source=stream)
        print(staging_path(returned.removesuffix("\n")))
        print("Staged only; use --extract/--import separately. Nothing was published.", file=sys.stderr)
    elif action in {"extract", "import"}:
        path = staging_path(getattr(args, action))
        if action == "import":
            backend("import", path, tty=True)
        else:
            print(staging_path(backend("extract", path).removesuffix("\n")))
    elif action == "publish":
        if not args.publish.isdecimal() or int(args.publish) < 1:
            raise Failure("--publish needs one positive Beets album ID.")
        if args.yes:
            if not args.basis or not args.attribution:
                raise Failure("Noninteractive --yes requires --basis and --attribution for this one album.")
        else:
            if not sys.stdin.isatty() or not sys.stdout.isatty():
                raise Failure("Publication requires a terminal, or explicit --yes with basis and public attribution.")
            if args.basis is None:
                args.basis = getpass.getpass("Private permission/license basis (music AND artwork): ")
            if args.attribution is None:
                args.attribution = input("PUBLIC attribution: ")
        if not args.basis.strip() or not args.attribution.strip():
            raise Failure("Permission basis and public attribution must not be empty.")
        command = ["publish", args.publish, "--basis=" + args.basis, "--attribution=" + args.attribution]
        if args.replace is not None:
            command += ["--replace=" + args.replace]
        if args.yes:
            pretty(backend(*command, "--yes"))
        else:
            backend(*command, tty=True)
    elif action in {"review", "albums"}:
        command = [action]
        if action == "review":
            if not args.review.isdecimal() or int(args.review) < 1:
                raise Failure("--review needs one positive Beets album ID.")
            command.append(args.review)
        pretty(backend(*command, "--json"))
    elif action == "check":
        pretty(backend("check"))
    elif action in {"status", "unpublish", "resume", "purge"}:
        pretty(backend(action, *([] if action == "status" else [getattr(args, action)])))
    else:
        print(backend("cache-clean"), end="")


if __name__ == "__main__":
    os.umask(0o077)
    try:
        main()
    except Failure as error:
        print("edit-music: " + str(error), file=sys.stderr)
        sys.exit(1)
    except (OSError, ValueError, TypeError, tarfile.TarError):
        print("edit-music: operation failed (private input details omitted); check local input, temporary disk space, SSH and backend status.", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("edit-music: interrupted; inspect --status before retrying a publication.", file=sys.stderr)
        sys.exit(130)
