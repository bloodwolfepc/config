"""Disabled local-boundary candidate. Parent plans bubblewrap; only --worker performs tool I/O."""
import json
import os
from pathlib import Path
import secrets
import stat
import subprocess
import sys

MAX_INPUT = 65536
MAX_OUTPUT = 65536


def require(value):
    if not value:
        raise ValueError("tool policy refused")


def request(raw):
    require(len(raw) <= MAX_INPUT)
    data = json.loads(raw)
    require(set(data) == {"version", "taskId", "operation", "args"})
    require(data["version"] == "pi-tool-operation/v1")
    require(isinstance(data["taskId"], str) and isinstance(data["args"], dict))
    schemas = {"read": ({"path"}, {"offset", "limit"}), "write": ({"path", "content"}, set()),
               "edit": ({"path", "oldText", "newText"}, set()), "bash": ({"command"}, set())}
    require(data["operation"] in schemas)
    mandatory, optional = schemas[data["operation"]]
    args = data["args"]
    require(mandatory <= args.keys() <= mandatory | optional)
    for key, value in args.items():
        if key in {"offset", "limit"}:
            require(type(value) is int and value > 0 and (key != "limit" or value <= 2000))
        else:
            require(isinstance(value, str) and len(value.encode("utf-8")) <= MAX_INPUT)
    return data


def parent_fd(root, name):
    require(isinstance(name, str) and not name.startswith("/") and "\\" not in name and "\0" not in name)
    pieces = name.split("/")
    require(all(p not in {"", ".", ".."} for p in pieces))
    fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        for part in pieces[:-1]:
            next_fd = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd)
            os.close(fd)
            fd = next_fd
        return fd, pieces[-1]
    except BaseException:
        os.close(fd)
        raise


def read_text(fd, name):
    file = os.open(name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=fd)
    try:
        info = os.fstat(file)
        require(stat.S_ISREG(info.st_mode) and info.st_nlink == 1 and info.st_size <= 1048576)
        with os.fdopen(file, "rb", closefd=False) as stream:
            body = stream.read(1048577)
        require(len(body) <= 1048576 and b"\0" not in body)
        return body.decode("utf-8")
    finally:
        os.close(file)


def write_text(fd, name, text):
    require("\0" not in text)
    try:
        info = os.stat(name, dir_fd=fd, follow_symlinks=False)
        require(stat.S_ISREG(info.st_mode) and info.st_nlink == 1)
        mode = stat.S_IMODE(info.st_mode) & 0o755
    except FileNotFoundError:
        mode = 0o600
    temporary = ".pi-write-" + secrets.token_hex(16)
    file = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600, dir_fd=fd)
    try:
        with os.fdopen(file, "wb", closefd=False) as stream:
            stream.write(text.encode("utf-8"))
            stream.flush()
        os.fchmod(file, mode)
        os.fsync(file)
        os.replace(temporary, name, src_dir_fd=fd, dst_dir_fd=fd)
        os.fsync(fd)
    finally:
        os.close(file)
        try:
            os.unlink(temporary, dir_fd=fd)
        except FileNotFoundError:
            pass


def operate(data, root, bash):
    args = data["args"]
    operation = data["operation"]
    if operation == "bash":
        # PIPE capture is bounded without retaining unbounded output in parent memory.
        process = subprocess.Popen([bash, "--noprofile", "--norc", "-c", args["command"]], cwd=root,
                                   env={"PATH": os.environ["PI_WORKER_PATH"], "HOME": "/tmp", "LANG": "C.UTF-8"},
                                   stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   close_fds=True)
        try:
            body = process.stdout.read(MAX_OUTPUT + 1)
            require(len(body) <= MAX_OUTPUT)
            code = process.wait()
            require(0 <= code <= 255)
            return code, body.decode("utf-8")
        finally:
            process.stdout.close()
            if process.poll() is None:
                process.kill()
            process.wait()
    fd, name = parent_fd(root, args["path"])
    try:
        if operation == "read":
            lines = read_text(fd, name).splitlines(keepends=True)
            offset = args.get("offset", 1) - 1
            return 0, "".join(lines[offset:offset + args.get("limit", 200)])
        if operation == "edit":
            body = read_text(fd, name)
            require(args["oldText"] and body.count(args["oldText"]) == 1)
            body = body.replace(args["oldText"], args["newText"], 1)
        else:
            body = args["content"]
        write_text(fd, name, body)
        return 0, "written"
    finally:
        os.close(fd)


def sandbox_argv(policy, workspace):
    # Only individually reviewed closure members, never the host's whole /nix/store.
    args = [policy["bwrap"], "--unshare-user", "--unshare-pid", "--unshare-net", "--unshare-ipc",
            "--unshare-uts", "--unshare-cgroup", "--disable-userns", "--die-with-parent", "--new-session", "--as-pid-1",
            "--cap-drop", "ALL", "--clearenv", "--tmpfs", "/", "--dir", "/nix", "--dir", "/nix/store",
            "--proc", "/proc", "--dev", "/dev", "--size", "268435456", "--tmpfs", "/tmp",
            "--bind", workspace, "/workspace"]
    for path in policy["runtimePaths"]:
        require(str(Path(path).resolve()) == path and path.startswith("/nix/store/") and Path(path).exists())
        args += ["--ro-bind", path, path]
    args += ["--ro-bind", policy["worker"], "/worker.py", "--remount-ro", "/", "--chdir", "/workspace",
             "--setenv", "PATH", policy["workerPath"], "--setenv", "PI_WORKER_PATH", policy["workerPath"],
             "--setenv", "LANG", "C.UTF-8", "--setenv", "HOME", "/tmp",
             policy["python"], "-I", "/worker.py", "--worker", policy["bash"]]
    return args


def checked_workspace(path):
    require(path.startswith("/var/lib/pi-tool-workspaces/") and str(Path(path).resolve()) == path)
    info = os.stat(path)
    require(stat.S_ISDIR(info.st_mode) and info.st_uid == os.getuid() and not info.st_mode & 0o077)
    # A preprovisioned persistent, dedicated <=1GiB ext4 filesystem is required.
    # No allocation, formatting, quota change or fallback occurs in this helper.
    require(os.path.ismount(path))
    mounts = Path("/proc/self/mountinfo").read_text().splitlines()
    require(any(line.split()[4] == path and line.split(" - ")[1].split()[0] == "ext4" for line in mounts))
    usage = os.statvfs(path)
    require(0 < usage.f_blocks * usage.f_frsize <= 1073741824)
    return path


def checked_workspaces(paths):
    require(1 <= len(paths) <= 2)
    checked = {task: checked_workspace(path) for task, path in paths.items()}
    require(len({os.stat(path).st_dev for path in checked.values()}) == len(checked))
    return checked


def main():
    raw = sys.stdin.buffer.read(MAX_INPUT + 1)
    data = request(raw)
    if len(sys.argv) == 3 and sys.argv[1] == "--worker":
        code, text = operate(data, "/workspace", sys.argv[2])
        require(len(text.encode("utf-8")) <= MAX_OUTPUT)
        print(json.dumps({"version": "pi-tool-result/v1", "code": code, "text": text, "truncated": False}))
        return
    require(len(sys.argv) == 2)
    policy = json.loads(Path(sys.argv[1]).read_text())
    workspace = checked_workspaces(policy["workspaces"])[data["taskId"]]
    # The worker is PID1; namespace teardown is the intended cleanup boundary, not a shell timeout.
    process = subprocess.run(sandbox_argv(policy, workspace), input=raw, close_fds=True,
                             env={"LANG": "C.UTF-8"}, check=False)
    require(process.returncode == 0)


if __name__ == "__main__":
    try:
        main()
    except BaseException:
        print("Tool boundary refused or outcome unknown; preserve ownership.", file=sys.stderr)
        sys.exit(1)
