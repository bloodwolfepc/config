"""One-shot synthetic H1 probes. Never imports a model client or qualifies the host."""
import fcntl
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import selectors
import shlex
import stat
import subprocess
import sys
import time

VERSION = "pi-local-h1-probes/v1"
PENDING = ["host-side process/cgroup/mount/device/socket inspection", "controlled network/DNS denial",
           "CPU/memory/PID/disk/scratch exhaustion", "descendant cancellation and independent teardown",
           "reboot/persistence and crash durability", "collector tamper/failure trials",
           "final task/runtime/policy/storage requalification", "human review and H1 decision"]


def require(value):
    if not value:
        raise ValueError("H1 probe refused")


def sync_dir(path):
    fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def exclusive(path, value):
    body = json.dumps(value, sort_keys=True).encode() + b"\n"
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    try:
        with os.fdopen(fd, "wb", closefd=False) as stream:
            stream.write(body)
            stream.flush()
        os.fchmod(fd, 0o400)
        os.fsync(fd)
    finally:
        os.close(fd)
    sync_dir(path.parent)


def private_directory(path):
    info = path.lstat()
    require(stat.S_ISDIR(info.st_mode) and info.st_uid == os.getuid() and not info.st_mode & 0o077)
    require(path.resolve() == path)


def immutable(path):
    p = Path(path)
    info = p.lstat()
    require(str(p).startswith("/nix/store/") and p.resolve() == p and stat.S_ISREG(info.st_mode))
    require(info.st_uid != os.getuid() and not info.st_mode & 0o222)


def invoke(argv, body=b"", pass_fds=()):
    """Finite operational probe timeout/output cap, not a model/run allowance."""
    require(len(body) <= 8192)
    process = subprocess.Popen(argv, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               env={"LANG": "C.UTF-8"}, close_fds=True, pass_fds=pass_fds)
    output = bytearray()
    try:
        process.stdin.write(body)
        process.stdin.close()
        os.set_blocking(process.stdout.fileno(), False)
        with selectors.DefaultSelector() as selector:
            selector.register(process.stdout, selectors.EVENT_READ)
            deadline = time.monotonic() + 15
            while selector.get_map():
                if time.monotonic() >= deadline:
                    raise TimeoutError("operational probe deadline")
                for key, _ in selector.select(timeout=0.1):
                    chunk = os.read(key.fd, 16384)
                    if not chunk:
                        selector.unregister(key.fileobj)
                    else:
                        output.extend(chunk)
                        require(len(output) <= 131072)
        code = process.wait(timeout=max(0.01, deadline - time.monotonic()))
        return code, bytes(output)
    finally:
        process.stdout.close()
        if process.poll() is None:
            process.kill()
        process.wait(timeout=2)
        # A timeout is uncertain: the retained receipt requires host-side teardown inspection.


def output_diagnostic(output):
    # Child text may contain secrets or forged errors: persist only closed, untrusted hints.
    require(isinstance(output, bytes) and len(output) <= 131072)
    patterns = [(b"bwrap:", "bubblewrap"), (b"namespace", "namespace"),
                (b"Operation not permitted", "operation-not-permitted"),
                (b"Permission denied", "permission-denied"), (b"No such file or directory", "missing-path"),
                (b"uid map", "uid-map"), (b"gid map", "gid-map"),
                (b"Traceback (most recent call last):", "python-traceback"),
                (b"Tool boundary refused or outcome unknown; preserve ownership.", "helper-held"),
                (b"Manual batch launcher refused/held.", "launcher-held")]
    return {"outputBytes": len(output), "untrusted": True,
            "hints": sorted(label for pattern, label in patterns if pattern in output)}


def transport_diagnostic(error):
    if isinstance(error, (TimeoutError, subprocess.TimeoutExpired)):
        kind = "timeout"
    elif isinstance(error, OSError):
        kind = "os-error"
    elif isinstance(error, ValueError):
        kind = "refused"
    elif isinstance(error, (KeyboardInterrupt, SystemExit)):
        kind = "interrupted"
    else:
        kind = "other"
    result = {"transport": kind}
    if isinstance(error, OSError) and type(error.errno) is int and 0 <= error.errno <= 4095:
        result["errno"] = error.errno
    return result


def validate_workspace(settings):
    spec = importlib.util.spec_from_file_location("trusted_pi_tool_validator", settings["workerSource"])
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.checked_workspace(settings["workspace"])


def run(settings, call=invoke, check_workspace=validate_workspace):
    state = Path(settings["state"])
    private_directory(state)
    # Stat only. H1 must never read, replace or use real credentials/authority.
    require(not any(os.path.lexists(state / name) for name in ["profile/auth.json", "admission.json", "h1.json"]))
    workspace = Path(check_workspace(settings))
    require(workspace == Path(settings["workspace"]))
    require({p.name for p in workspace.iterdir()} <= {"lost+found"})
    if (workspace / "lost+found").exists():
        private_directory(workspace / "lost+found")
        require(not any((workspace / "lost+found").iterdir()))
    journal = state / "journal"
    if not journal.exists():
        journal.mkdir(mode=0o700)
        sync_dir(state)
    private_directory(journal)
    require(not any(journal.iterdir()))
    root = state / "h1-probe"
    root.mkdir(mode=0o700)  # Never replace/retry a prior attempt, including partial creation.
    sync_dir(state)
    exclusive(root / "owner.json", {"version": VERSION, "synthetic": True, "retry": False})
    cases = []
    phase = "fixture"
    try:
        marker = root / "credential-marker.json"
        exclusive(marker, {"marker": "SYNTHETIC-H1-NOT-A-CREDENTIAL"})
        require(Path(settings["storeCanary"]).read_text() == "synthetic H1 marker, not a credential\n")

        def observed(name, argv, body=b"", pass_fds=(), expected=0):
            case = {"name": name, "expectedExitObserved": False}
            cases.append(case)
            try:
                code, output = call(argv, body, pass_fds)
            except BaseException as error:
                case["diagnostic"] = transport_diagnostic(error)
                raise
            case.update({"expectedExitObserved": code == expected, "exit": code,
                         "outputSha256": hashlib.sha256(output).hexdigest()})
            if code != expected:
                case["diagnostic"] = output_diagnostic(output)
            require(code == expected)
            return output

        def tool(name, operation, args, pass_fds=()):
            body = json.dumps({"version": "pi-tool-operation/v1", "taskId": settings["taskId"],
                               "operation": operation, "args": args}).encode()
            raw = observed(name, [settings["helper"]], body, pass_fds)
            reply = json.loads(raw)
            require(set(reply) == {"version", "code", "text", "truncated"})
            require(reply["version"] == "pi-tool-result/v1" and type(reply["code"]) is int and reply["code"] == 0
                    and reply["truncated"] is False and isinstance(reply["text"], str))
            return reply["text"]

        phase = "tools"
        tool("write", "write", {"path": "h1-probe.txt", "content": "first\n"})
        require(tool("read", "read", {"path": "h1-probe.txt"}) == "first\n")
        tool("edit", "edit", {"path": "h1-probe.txt", "oldText": "first", "newText": "second"})
        require(tool("bash", "bash", {"command": "test \"$(cat h1-probe.txt)\" = second && printf 'h1-ok\\n'"}) == "h1-ok\n")
        tool("state-credential-denial", "bash", {"command": f"test ! -r '{marker}'"})
        tool("excluded-store-denial", "bash", {"command": f"test ! -e '{settings['storeCanary']}'"})
        tool("sterile-environment", "bash", {"command": "test -z \"${SSH_AUTH_SOCK-}${GPG_AGENT_INFO-}${OPENAI_API_KEY-}${CODEX_API_KEY-}${NODE_OPTIONS-}\""})
        namespaces = ["user", "mnt", "pid", "net", "ipc", "uts", "cgroup"]
        parent = {name: os.stat(f"/proc/self/ns/{name}").st_ino for name in namespaces}
        code = "import json,os; print(json.dumps({n:os.stat('/proc/self/ns/'+n).st_ino for n in " + repr(namespaces) + "}))"
        child = json.loads(tool("namespace-identities", "bash", {"command": f"{settings['python']} -I -c {shlex.quote(code)}"}))
        require(set(child) == set(parent) and all(type(child[n]) is int and child[n] > 0 and child[n] != parent[n] for n in parent))
        fd = os.open(marker, os.O_RDONLY | os.O_NOFOLLOW)
        try:
            inherited = fcntl.fcntl(fd, fcntl.F_DUPFD_CLOEXEC, 200)
            try:
                tool("inherited-fd-denial", "bash", {"command": f"test ! -e /proc/self/fd/{inherited}"}, (inherited,))
            finally:
                os.close(inherited)
        finally:
            os.close(fd)
        phase = "inventory"
        raw = observed("inventory-no-authority", [settings["launcher"], "--inventory", settings["launch"]])
        inventory = json.loads(raw)
        require(set(inventory) == {"authority", "initialTrees", "policyDigest", "launchDigest", "environmentDigest"})
        require(inventory["authority"] == "not-granted" and set(inventory["initialTrees"]) == {settings["taskId"]})
        require(all(isinstance(value, str) and re.fullmatch("[a-f0-9]{64}", value) for value in
                    [inventory["policyDigest"], inventory["launchDigest"], inventory["environmentDigest"],
                     inventory["initialTrees"][settings["taskId"]]]))
        phase = "owner-refusal"
        exclusive(journal / "owner.json", {"version": VERSION, "synthetic": True, "reconciliation": "human"})
        observed("existing-owner-refusal", [settings["launcher"], "--preflight", settings["launch"]], expected=1)
        raw = observed("unsealed-report", [settings["launcher"], "--report", settings["launch"]])
        report = json.loads(raw)
        require(report["status"] == "incomplete" and report["ownerRetained"] is True)
        phase = "receipt"
        receipt = {"version": VERSION, "status": "partial-h1", "qualification": "not-granted", "synthetic": True,
                   "harnessSha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                   "settingsSha256": hashlib.sha256(json.dumps(settings, sort_keys=True).encode()).hexdigest(),
                   "namespaceIds": {"controller": parent, "worker": child},
                   "stateDevice": state.stat().st_dev, "workspaceDevice": workspace.stat().st_dev,
                   "cases": cases, "inventory": inventory, "pending": PENDING, "ownerRetained": True}
        exclusive(root / "RESULT.json", receipt)
        return receipt
    except BaseException:
        try:
            exclusive(root / "HELD.json", {"version": VERSION, "phase": phase, "cases": cases,
                                           "ownerRetained": True, "retry": False, "qualification": "not-granted"})
        except Exception:
            pass  # Even a failed receipt leaves the exclusive owner/partial files in place.
        raise RuntimeError("H1 held; retain synthetic state and inspect host-side teardown. No retry.") from None


def main():
    if sys.argv[1:] == ["--help"]:
        print("pi-coordinator-h1 /nix/store/.../settings.json: one-shot synthetic probes; never a model or H1 qualification")
        return
    require(len(sys.argv) == 2)
    immutable(sys.argv[1])
    require(Path(sys.argv[1]).stat().st_size <= 65536)
    settings = json.loads(Path(sys.argv[1]).read_bytes())
    require(set(settings) == {"state", "taskId", "workspace", "storeCanary", "launch", "helper", "launcher", "workerSource", "python"})
    require(settings["state"] == "/var/lib/pi-coordinator" and settings["workspace"] == "/var/lib/pi-tool-workspaces/slot-1")
    for key in ["storeCanary", "launch", "helper", "launcher", "workerSource", "python"]:
        immutable(settings[key])
    run(settings)
    print("Synthetic probes recorded; H1 remains incomplete. Retain owners; no model or retry.")


if __name__ == "__main__":
    try:
        main()
    except BaseException:
        print("H1 refused/held; preserve state and reconcile manually. No retry or qualification.", file=sys.stderr)
        sys.exit(1)
