"""Offline source/operation fixtures; NO namespaces, services, disk images or denial trials."""
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from types import SimpleNamespace
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("helper", sys.argv.pop(1))
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


def message(operation, **args):
    return helper.request(json.dumps({"version": "pi-tool-operation/v1", "taskId": "offline-task-0001",
                                      "operation": operation, "args": args}).encode())


class BoundarySourceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def operate(self, operation, **args):
        return helper.operate(message(operation, **args), str(self.root), os.environ["PI_TEST_BASH"])

    def test_text_operations_and_exact_edit(self):
        self.operate("write", path="example.txt", content="one\ntwo\n")
        self.assertEqual(self.operate("read", path="example.txt", offset=2, limit=1), (0, "two\n"))
        self.operate("edit", path="example.txt", oldText="two", newText="three")
        self.assertEqual((self.root / "example.txt").read_text(), "one\nthree\n")
        with self.assertRaises(ValueError):
            self.operate("edit", path="example.txt", oldText="absent", newText="bad")

    def test_file_route_rejects_absolute_traversal_symlinks_and_hardlinks(self):
        (self.root / "file").write_text("fixture")
        (self.root / "link").symlink_to("file")
        (self.root / "directory").mkdir()
        (self.root / "dirlink").symlink_to("directory", target_is_directory=True)
        for path in ("../file", "/file", "link", "dirlink/new", "./file", "directory/../file"):
            with self.subTest(path=path), self.assertRaises((ValueError, OSError)):
                self.operate("write", path=path, content="refused")
        os.link(self.root / "file", self.root / "hard")
        with self.assertRaises(ValueError):
            self.operate("read", path="hard")
        self.assertEqual((self.root / "file").read_text(), "fixture")

    def test_text_routes_reject_nul_and_reads_reject_large_or_special_files(self):
        with self.assertRaises(ValueError):
            self.operate("write", path="nul-write", content="x\0y")
        self.assertFalse((self.root / "nul-write").exists())
        for name, body in [("binary", b"\0png"), ("large", b"x" * 1048577)]:
            (self.root / name).write_bytes(body)
            with self.assertRaises(ValueError):
                self.operate("read", path=name)
        os.mkfifo(self.root / "fifo")
        with self.assertRaises(ValueError):
            self.operate("read", path="fifo")

    def test_bash_fixture_has_sterile_environment_and_no_input(self):
        # Positive operation fixture only, NOT a confinement or network test.
        os.environ["PI_WORKER_PATH"] = os.environ["PI_TEST_BIN_PATH"]
        os.environ["FAKE_PROVIDER_SECRET"] = "fixture-must-not-be-inherited"
        code, text = self.operate("bash", command='printf "%s|%s" "${FAKE_PROVIDER_SECRET-unset}" "$HOME"')
        self.assertEqual((code, text), (0, "unset|/tmp"))
        code, _ = self.operate("bash", command="exit 7")
        self.assertEqual(code, 7)

    def test_unknown_routes_fields_bad_types_and_oversized_requests_refuse(self):
        for raw in [b"x" * 65537, b'{}', b'{"version":"old"}',
                    json.dumps({"version": "pi-tool-operation/v1", "taskId": "offline-task-0001", "operation": "ssh", "args": {}}).encode()]:
            with self.assertRaises((ValueError, KeyError)):
                helper.request(raw)
        with self.assertRaises(ValueError):
            message("read", path="file", offset=True)
        with self.assertRaises(ValueError):
            message("bash", command="true", helper="untrusted")

    def test_required_namespace_flags_and_exact_closure_not_host_store(self):
        policy = json.loads(Path(os.environ["PI_TOOL_POLICY"]).read_text())
        argv = helper.sandbox_argv(policy, "/fake/workspace")
        help_text = subprocess.check_output([os.environ["PI_BWRAP"], "--help"], text=True)
        for flag in ("--unshare-user", "--unshare-pid", "--unshare-net", "--unshare-ipc", "--unshare-uts",
                     "--unshare-cgroup", "--disable-userns", "--clearenv", "--die-with-parent", "--as-pid-1"):
            self.assertIn(flag, argv)
            self.assertIn(flag, help_text)
        for prohibited in ("--unshare-all", "--unshare-user-try", "--unshare-cgroup-try", "--share-net", "--preserve-fds"):
            self.assertNotIn(prohibited, argv)
        binds = [(argv[i + 1], argv[i + 2]) for i, value in enumerate(argv) if value == "--ro-bind"]
        self.assertNotIn(("/nix/store", "/nix/store"), binds)
        self.assertEqual(binds[:-1], [(p, p) for p in policy["runtimePaths"]])
        self.assertIn("--remount-ro", argv)
        self.assertIn("268435456", argv)

    def test_fresh_pid_private_proc_is_sealed_before_worker_without_host_proc_bind(self):
        policy = json.loads(Path(os.environ["PI_TOOL_POLICY"]).read_text())
        argv = helper.sandbox_argv(policy, "/fake/workspace")
        proc = argv.index("--proc")
        self.assertEqual(argv.count("--proc"), 1)
        self.assertEqual(argv[proc:proc + 4], ["--proc", "/proc", "--remount-ro", "/proc"])
        self.assertLess(argv.index("--unshare-pid"), proc)
        self.assertLess(proc + 3, argv.index("/worker.py"))
        self.assertEqual([argv[i + 1] for i, arg in enumerate(argv) if arg == "--remount-ro"], ["/proc", "/"])
        for i, arg in enumerate(argv):
            if arg in {"--bind", "--ro-bind", "--dev-bind"}:
                self.assertFalse(any(p == "/proc" or p.startswith("/proc/") for p in argv[i + 1:i + 3]))
        for prohibited in ("--pidns", "--userns", "--userns2", "--unshare-user-try", "--share-net"):
            self.assertNotIn(prohibited, argv)

    def test_failed_sandbox_setup_refuses_without_retry_or_host_fallback(self):
        policy_path = Path(os.environ["PI_TOOL_POLICY"])
        raw = json.dumps(message("bash", command="true")).encode()
        with patch.object(helper.sys, "argv", ["helper", str(policy_path)]), \
             patch.object(helper.sys, "stdin", SimpleNamespace(buffer=io.BytesIO(raw))), \
             patch.object(helper, "checked_workspaces", return_value={"offline-task-0001": "/fake/workspace"}), \
             patch.object(helper.subprocess, "run", return_value=SimpleNamespace(returncode=1)) as run:
            with self.assertRaises(ValueError):
                helper.main()
        run.assert_called_once()
        self.assertIn("--proc", run.call_args.args[0])
        self.assertEqual(run.call_args.kwargs["env"], {"LANG": "C.UTF-8"})
        self.assertTrue(run.call_args.kwargs["close_fds"])

    def test_workspace_aliases_refuse_using_synthetic_device_metadata_only(self):
        paths = {"first-task": "/fake/one", "second-task": "/fake/two"}
        with patch.object(helper, "checked_workspace", side_effect=lambda p: p), patch.object(helper.os, "stat") as metadata:
            metadata.return_value = SimpleNamespace(st_dev=1)
            with self.assertRaises(ValueError):
                helper.checked_workspaces(paths)
            metadata.side_effect = [SimpleNamespace(st_dev=1), SimpleNamespace(st_dev=2)]
            self.assertEqual(helper.checked_workspaces(paths), paths)
        with self.assertRaises(ValueError):
            helper.checked_workspaces({})

    def test_no_temporary_workspace_or_implicit_provisioning_fallback(self):
        with self.assertRaises(ValueError):
            helper.checked_workspace(str(self.root))

    def test_immutable_management_wrapper_refuses_malformed_input_before_any_state_access(self):
        # Actual packaged import/protocol smoke only; no namespace, workspace or service launch.
        result = subprocess.run([os.environ["PI_BATCH_MANAGEMENT"]], input=b"{}", capture_output=True,
                                env={"LANG": "C.UTF-8"}, check=False)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, b"")
        self.assertIn(b"preserve owner and partial artifacts", result.stderr)

    def test_parent_proc_compatible_with_readonly_private_worker_proc(self):
        service = json.loads(Path(os.environ["PI_UNIT_METADATA"]).read_text())["service"]
        # Metadata only: parent proc overmounts conflict with unprivileged fresh proc mounts.
        for key, value in {"MountAPIVFS": True, "ProcSubset": "all", "ProtectProc": "invisible",
                           "ProtectKernelTunables": False, "User": "pi-coordinator", "Group": "pi-coordinator",
                           "RestrictSUIDSGID": True, "ProtectKernelModules": True,
                           "ProtectControlGroups": True, "NoNewPrivileges": True,
                           "CapabilityBoundingSet": "", "ProtectSystem": "strict"}.items():
            with self.subTest(setting=key):
                self.assertEqual(service[key], value)

    def test_disabled_defaults_and_declared_service_caps_not_actual_enforcement(self):
        data = json.loads(Path(os.environ["PI_UNIT_METADATA"]).read_text())
        self.assertFalse(data["disabledUnit"])
        self.assertFalse(data["disabledIdentity"])
        self.assertTrue(data["candidateValid"])
        self.assertEqual(data["wantedBy"], [])
        self.assertTrue(data["missingBindingRejected"])
        self.assertTrue(data["broadNetworkRejected"])
        service = data["service"]
        for key, value in {"Restart": "no", "KillMode": "control-group", "CPUQuota": "200%", "MemoryMax": "4G",
                           "MemorySwapMax": 0, "TasksMax": 128, "IPAddressDeny": "any", "ProtectHome": True,
                           "NoNewPrivileges": True, "StandardOutput": "null"}.items():
            self.assertEqual(service[key], value)
        self.assertEqual(service["IPAddressAllow"], ["203.0.113.1/32"])
        self.assertNotIn("/home", service["BindPaths"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
