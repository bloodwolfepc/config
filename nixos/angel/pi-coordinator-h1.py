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
    except BaseException as error:
        error.h1_private_output = bytes(output[:131072])
        raise
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


CONTINUATION = "pi-h1-continuation/v1"
LIMITS = {"dispatches": 13, "operationSeconds": 15, "inputBytes": 8192,
          "captureBytes": 131072, "failureBytes": 131072, "runtimeSeconds": 240, "stopGraceSeconds": 10}


def read_record(path, uid, mode, gid=None):
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        before = os.fstat(fd)
        require(stat.S_ISREG(before.st_mode) and before.st_uid == uid and before.st_nlink == 1
                and stat.S_IMODE(before.st_mode) == mode and before.st_size <= 65536)
        require(gid is None or before.st_gid == gid)
        body = bytearray()
        while len(body) <= 65536:
            block = os.read(fd, min(16384, 65537 - len(body)))
            if not block:
                break
            body.extend(block)
        after = os.fstat(fd)
        require(len(body) == before.st_size and (before.st_size, before.st_mtime_ns, before.st_ctime_ns) ==
                (after.st_size, after.st_mtime_ns, after.st_ctime_ns))
        return bytes(body)
    finally:
        os.close(fd)


def root_grant(path):
    return read_record(path, 0, 0o440, os.getgid())


def file_digest(path):
    immutable(path)
    require(Path(path).stat().st_size <= 16 * 1024 * 1024)
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def runtime_binding(settings):
    return {"harnessSha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            "settingsSha256": hashlib.sha256(json.dumps(settings, sort_keys=True).encode()).hexdigest(),
            "files": {key: {"path": settings[key], "sha256": file_digest(settings[key])} for key in
                      ["helper", "launcher", "launch", "workerSource", "python", "storeCanary", "policy", "continuation"]}}


def host_state(settings):
    return {"bootId": Path("/proc/sys/kernel/random/boot_id").read_text().strip(),
            "stateDevice": Path(settings["state"]).stat().st_dev,
            "workspaceDevice": Path(settings["workspace"]).stat().st_dev}


def prepare_continuation(settings, root):
    private_directory(root)
    require({p.name for p in root.iterdir()} == {"owner.json", "HELD.json", "credential-marker.json",
                                               "continuation-0001.grant.json"})
    immutable(settings["continuation"])
    require(Path(settings["continuation"]).stat().st_size <= 65536)
    descriptor_bytes = Path(settings["continuation"]).read_bytes()
    descriptor = json.loads(descriptor_bytes)
    require(set(descriptor) == {"version", "id", "taskId", "previousOwnerSha256", "previousHeldSha256",
                                "previousWriteOutputSha256", "stateUUID", "workspaceUUID"})
    require(descriptor["version"] == CONTINUATION and descriptor["id"] == "0001"
            and descriptor["taskId"] == settings["taskId"] == "h1_fixture_20261124")
    for key in ["stateUUID", "workspaceUUID"]:
        require(type(descriptor[key]) is str and re.fullmatch("[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}", descriptor[key]))
    require(descriptor["stateUUID"] != descriptor["workspaceUUID"])
    for key in ["previousOwnerSha256", "previousHeldSha256", "previousWriteOutputSha256"]:
        require(type(descriptor[key]) is str and re.fullmatch("[a-f0-9]{64}", descriptor[key]))
    owner = read_record(root / "owner.json", os.getuid(), 0o400)
    held_bytes = read_record(root / "HELD.json", os.getuid(), 0o400)
    marker = read_record(root / "credential-marker.json", os.getuid(), 0o400)
    require(hashlib.sha256(owner).hexdigest() == descriptor["previousOwnerSha256"]
            and hashlib.sha256(held_bytes).hexdigest() == descriptor["previousHeldSha256"])
    require(json.loads(owner) == {"version": VERSION, "synthetic": True, "retry": False})
    require(marker == json.dumps({"marker": "SYNTHETIC-H1-NOT-A-CREDENTIAL"}, sort_keys=True).encode() + b"\n")
    held = json.loads(held_bytes)
    require(held["version"] == VERSION and held["phase"] == "tools" and held["retry"] is False
            and held["ownerRetained"] is True and held["qualification"] == "not-granted"
            and len(held["cases"]) == 1)
    case = held["cases"][0]
    require(case["name"] == "write" and case["exit"] == 1 and case["expectedExitObserved"] is False
            and case["outputSha256"] == descriptor["previousWriteOutputSha256"])
    grant_bytes = root_grant(root / "continuation-0001.grant.json")
    grant = json.loads(grant_bytes)
    require(type(grant.get("limits")) is dict and all(type(value) is int for value in grant["limits"].values()))
    require(set(grant) == {"version", "id", "authority", "descriptorSha256", "runtime", "host", "limits", "retainPrivateFailure"})
    require(grant["version"] == CONTINUATION and grant["id"] == "0001"
            and grant["authority"] == "one-synthetic-continuation-only" and grant["retainPrivateFailure"] is True
            and grant["descriptorSha256"] == hashlib.sha256(descriptor_bytes).hexdigest()
            and grant["runtime"] == runtime_binding(settings) and grant["limits"] == LIMITS)
    host = grant["host"]
    require(set(host) == {"generation", "unitSha256", "reconciliationSha256", "bootId", "stateDevice", "workspaceDevice", "stateUUID", "workspaceUUID"})
    require(type(host["generation"]) is str and re.fullmatch(r"/nix/store/[a-z0-9]{32}-nixos-system-angel-[A-Za-z0-9.]+", host["generation"]))
    for key in ["unitSha256", "reconciliationSha256"]:
        require(type(host[key]) is str and re.fullmatch("[a-f0-9]{64}", host[key]))
    unit_file = (Path(host["generation"]) / "etc/systemd/system/pi-coordinator.service").resolve()
    require(file_digest(unit_file) == host["unitSha256"])
    actual_host = host_state(settings)
    require(all(host[key] == value for key, value in actual_host.items())
            and type(host["stateDevice"]) is int and type(host["workspaceDevice"]) is int
            and host["stateDevice"] != host["workspaceDevice"]
            and host["stateUUID"] == descriptor["stateUUID"] and host["workspaceUUID"] == descriptor["workspaceUUID"])
    # Generation/unit/reconciliation fields are the trusted root supervisor's attestation;
    # this chroot cannot independently inspect the host's /run/current-system or unit manager.
    return {"id": "0001", "grantSha256": hashlib.sha256(grant_bytes).hexdigest(),
            "descriptorSha256": grant["descriptorSha256"], "previousHeldSha256": descriptor["previousHeldSha256"],
            "hostAttestation": host, "runtime": grant["runtime"], "limits": LIMITS}


def private_failure(path, body):
    require(type(body) is bytes and len(body) <= 131072)
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
    if "continuation" in settings:
        require(journal.exists())  # Never recreate missing retained state to make a continuation fresh.
    if not journal.exists():
        journal.mkdir(mode=0o700)
        sync_dir(state)
    private_directory(journal)
    require(not any(journal.iterdir()))
    root = state / "h1-probe"
    continuation = prepare_continuation(settings, root) if "continuation" in settings else None
    prefix = "continuation-0001." if continuation else ""
    if continuation:
        exclusive(root / (prefix + "attempt.json"), {"version": CONTINUATION, "continuation": continuation,
                                                    "synthetic": True, "retry": False, "qualification": "not-granted"})
    else:
        root.mkdir(mode=0o700)  # Never replace/retry a prior attempt, including partial creation.
        sync_dir(state)
        exclusive(root / "owner.json", {"version": VERSION, "synthetic": True, "retry": False})
    cases = []
    phase = "fixture"
    last_output = None
    output_complete = False
    try:
        marker = root / "credential-marker.json"
        if not continuation:
            exclusive(marker, {"marker": "SYNTHETIC-H1-NOT-A-CREDENTIAL"})
        require(Path(settings["storeCanary"]).read_text() == "synthetic H1 marker, not a credential\n")

        def observed(name, argv, body=b"", pass_fds=(), expected=0):
            nonlocal last_output, output_complete
            last_output, output_complete = None, False
            require(len(cases) < (13 if continuation else 12))
            case = {"name": name, "expectedExitObserved": False}
            cases.append(case)
            if continuation:
                exclusive(root / (prefix + f"case-{len(cases):02d}.attempt.json"),
                          {"name": name, "expectedExit": expected, "grantSha256": continuation["grantSha256"]})
            try:
                code, output = call(argv, body, pass_fds)
                require(type(output) is bytes and len(output) <= 131072)
            except BaseException as error:
                partial = getattr(error, "h1_private_output", None)
                if continuation and type(partial) is bytes and len(partial) <= 131072:
                    last_output = partial
                case["diagnostic"] = transport_diagnostic(error)
                raise
            last_output, output_complete = output, True
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

        if continuation:
            phase = "startup"
            require(tool("startup-marker", "bash", {"command": "printf '%s\\n' 'PI_H1_CONTINUATION_0001'"}) == "PI_H1_CONTINUATION_0001\n")
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
        if continuation:
            receipt.update(version=CONTINUATION, continuation=continuation)
        exclusive(root / (prefix + "RESULT.json"), receipt)
        return receipt
    except BaseException:
        failure = None
        if continuation and last_output is not None:
            try:
                private_failure(root / (prefix + "failure.bin"), last_output)
                failure = {"bytes": len(last_output), "sha256": hashlib.sha256(last_output).hexdigest(),
                           "complete": output_complete, "operatorPrivate": True, "case": cases[-1]["name"],
                           "scope": "last-captured-helper-output-not-cause-proof"}
            except BaseException:
                failure = {"persistence": "failed-preserve-attempt-no-retry"}
        try:
            held = {"version": CONTINUATION if continuation else VERSION, "phase": phase, "cases": cases,
                    "ownerRetained": True, "retry": False, "qualification": "not-granted"}
            if continuation:
                held.update(continuation=continuation, privateFailure=failure)
            exclusive(root / (prefix + "HELD.json"), held)
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
    keys = {"state", "taskId", "workspace", "storeCanary", "launch", "helper", "launcher", "workerSource", "python"}
    require(set(settings) == keys or set(settings) == keys | {"continuation", "policy"})
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
