"""Trusted controller collector, never a model tool. No Git, hooks, shells or lock release."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import stat
import sys

MAX_FILES = 1024
MAX_FILE = 1048576
MAX_BYTES = 16777216


def require(value):
    if not value:
        raise ValueError("management boundary refused")


def encoded(value):
    return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(",", ":")).encode()


def digest(body):
    return hashlib.sha256(body).hexdigest()


def fingerprint(info):
    return (info.st_dev, info.st_ino, info.st_size, info.st_mode, info.st_mtime_ns, info.st_ctime_ns)


def private_dir(path):
    require(str(Path(path).resolve()) == str(path))
    info = os.lstat(path)
    require(stat.S_ISDIR(info.st_mode) and info.st_uid == os.getuid() and not info.st_mode & 0o077)


def sync_dir(path):
    fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def exclusive(path, body):
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    try:
        with os.fdopen(fd, "wb", closefd=False) as output:
            output.write(body)
            output.flush()
        os.fchmod(fd, 0o400)
        os.fsync(fd)
    finally:
        os.close(fd)
    sync_dir(Path(path).parent)


def scan(root, blobs=None):
    """Bounded fd-relative regular-file export; optimistic stability, not a filesystem snapshot."""
    rootfd = os.open(root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    device = os.fstat(rootfd).st_dev
    files, stamps, directories = [], {}, {}
    total, nodes, path_bytes = 0, 0, 0

    def walk(fd, prefix, depth):
        nonlocal total, nodes, path_bytes
        require(depth <= 32)
        start = os.fstat(fd)
        names = sorted(os.listdir(fd))
        require(len(names) <= MAX_FILES)
        directories[prefix] = fingerprint(start)
        for name in names:
            require(name not in {".git", ".", ".."} and "\\" not in name)
            relative = prefix + name
            nodes += 1
            path_bytes += len(relative.encode("utf-8"))
            require(nodes <= 2048 and path_bytes <= 131072 and len(relative.encode("utf-8")) <= 4096)
            info = os.stat(name, dir_fd=fd, follow_symlinks=False)
            require(info.st_dev == device and info.st_uid == os.getuid())
            if stat.S_ISDIR(info.st_mode):
                child = os.open(name, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd)
                try:
                    require(fingerprint(os.fstat(child)) == fingerprint(info))
                    walk(child, relative + "/", depth + 1)
                finally:
                    os.close(child)
            else:
                require(stat.S_ISREG(info.st_mode) and info.st_nlink == 1 and not info.st_mode & 0o7000)
                require(info.st_size <= MAX_FILE and len(files) < MAX_FILES and total + info.st_size <= MAX_BYTES)
                file = os.open(name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=fd)
                try:
                    require(fingerprint(os.fstat(file)) == fingerprint(info))
                    with os.fdopen(file, "rb", closefd=False) as stream:
                        body = stream.read(MAX_FILE + 1)
                    require(len(body) == info.st_size and fingerprint(os.fstat(file)) == fingerprint(info))
                finally:
                    os.close(file)
                hashed = digest(body)
                files.append({"path": relative, "sha256": hashed, "bytes": len(body), "mode": stat.S_IMODE(info.st_mode)})
                stamps[relative] = fingerprint(info)
                total += len(body)
                if blobs is not None:
                    target = Path(blobs) / hashed
                    if target.exists():
                        require(target.is_file() and not target.is_symlink() and digest(target.read_bytes()) == hashed)
                    else:
                        exclusive(target, body)
        require(names == sorted(os.listdir(fd)) and fingerprint(os.fstat(fd)) == fingerprint(start))
    try:
        walk(rootfd, "", 0)
    finally:
        os.close(rootfd)
    files.sort(key=lambda item: item["path"])
    return {"treeDigest": digest(encoded(files)), "files": files, "bytes": total}, (stamps, directories)


def inspect(root, blobs=None):
    tree, stamps = scan(root, blobs)
    again, restamps = scan(root)
    require(tree == again and stamps == restamps)
    return tree


def manage(policy, request, workspace_check):
    require(set(request) == {"version", "action", "runId", "approvalId", "tasks"})
    require(request["version"] == "pi-batch-management/v1" and request["action"] in {"inventory", "preflight", "before", "after"})
    for key in ("runId", "approvalId"):
        require(isinstance(request[key], str) and re.fullmatch(r"[A-Za-z0-9_-]{8,96}", request[key]))
    tasks = request["tasks"]
    require(isinstance(tasks, list) and 1 <= len(tasks) <= 2)
    require(all(set(task) == {"id", "base", "initialTree"} for task in tasks))
    require(len({task["id"] for task in tasks}) == len(tasks) and {task["id"] for task in tasks} == set(policy["workspaces"]))
    for task in tasks:
        require(re.fullmatch(r"[A-Za-z0-9_-]{8,96}", task["id"]) and re.fullmatch(r"[a-f0-9]{40}", task["base"]) and re.fullmatch(r"[a-f0-9]{64}", task["initialTree"]))
    workspaces = workspace_check(policy["workspaces"])
    journal = Path(policy["journalRoot"])
    private_dir(journal)
    bundle = None
    if request["action"] not in {"inventory", "preflight"}:
        owner = json.loads((journal / "owner.json").read_text())
        require(owner["runId"] == request["runId"] and owner["approvalId"] == request["approvalId"])
        run = journal / ("run-" + request["runId"])
        private_dir(run)
        bundle = run / ("artifacts-" + request["action"])
        bundle.mkdir(mode=0o700)  # Exclusive: no replacement or partial-capture retry.
        (bundle / "blobs").mkdir(mode=0o700)
        sync_dir(run)
    results = []
    for task in tasks:
        tree = inspect(workspaces[task["id"]], None if bundle is None else bundle / "blobs")
        if request["action"] in {"preflight", "before"}:
            require(tree["treeDigest"] == task["initialTree"])
        result = {"taskId": task["id"], "base": task["base"], "treeDigest": tree["treeDigest"], "files": len(tree["files"]), "bytes": tree["bytes"]}
        if bundle is not None:
            body = encoded({"version": "pi-workspace-tree/v1", **result, "entries": tree["files"]})
            exclusive(bundle / (task["id"] + ".json"), body)
            result["manifestDigest"] = digest(body)
        results.append(result)
    result = {"version": "pi-batch-management-result/v1", "policyDigest": digest(encoded(policy)), "tasks": results}
    if bundle is not None:
        body = encoded(result)
        exclusive(bundle / "bundle.json", body)
        sync_dir(bundle)
        result["bundleDigest"] = digest(body)
    return result


def main():
    require(len(sys.argv) == 2 and str(Path(sys.argv[1]).resolve()) == sys.argv[1] and sys.argv[1].startswith("/nix/store/"))
    policy = json.loads(Path(sys.argv[1]).read_text())
    require(policy["journalRoot"] == "/var/lib/pi-coordinator/journal")
    module = importlib.util.spec_from_file_location("pi_tool_worker", policy["worker"])
    worker = importlib.util.module_from_spec(module)
    module.loader.exec_module(worker)
    raw = sys.stdin.buffer.read(65537)
    require(len(raw) <= 65536)
    result = manage(policy, json.loads(raw), worker.checked_workspaces)
    print(json.dumps({"version": "pi-tool-result/v1", "code": 0, "text": json.dumps(result), "truncated": False}))


if __name__ == "__main__":
    try:
        main()
    except BaseException:
        print("Management boundary held; preserve owner and partial artifacts. No retry.", file=sys.stderr)
        sys.exit(1)
