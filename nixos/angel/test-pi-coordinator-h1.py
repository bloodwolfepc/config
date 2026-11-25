"""Offline source fixtures only: never starts a unit, namespace or model."""
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("h1", sys.argv.pop(1))
h1 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h1)


class Fixture:
    def __init__(self, root):
        self.state = root / "state"
        self.state.mkdir(mode=0o700)
        self.workspace = root / "workspace"
        self.workspace.mkdir(mode=0o700)
        self.canary = root / "store-canary"
        self.canary.write_text("synthetic H1 marker, not a credential\n")
        self.settings = {"state": str(self.state), "workspace": str(self.workspace), "taskId": "h1_fixture_20261124",
                         "helper": "fixture-helper", "launcher": "fixture-launcher", "launch": "fixture-launch.json",
                         "storeCanary": str(self.canary), "python": "fixture-python", "workerSource": "unused"}
        self.calls = []
        self.fail = None
        self.failure_output = b"synthetic failure, never a credential\n"
        self.bad_namespace = False
        self.saw_inherited_fd = False

    def call(self, argv, body, pass_fds):
        self.calls.append((argv, body, pass_fds))
        if self.fail == len(self.calls):
            return 1, self.failure_output
        if argv[0] == "fixture-helper":
            request = json.loads(body)
            op, args = request["operation"], request["args"]
            if op == "write":
                (self.workspace / args["path"]).write_text(args["content"])
                text = "written"
            elif op == "edit":
                p = self.workspace / args["path"]
                p.write_text(p.read_text().replace(args["oldText"], args["newText"]))
                text = "written"
            elif op == "read":
                text = (self.workspace / args["path"]).read_text()
            elif "json.dumps" in args["command"]:
                names = ["user", "mnt", "pid", "net", "ipc", "uts", "cgroup"]
                text = json.dumps({n: os.stat(f"/proc/self/ns/{n}").st_ino + (0 if self.bad_namespace else 1) for n in names})
            else:
                text = "h1-ok\n" if "printf" in args["command"] else ""
                if pass_fds:
                    self.saw_inherited_fd = all(os.fstat(fd).st_size > 0 for fd in pass_fds)
            return 0, json.dumps({"version": "pi-tool-result/v1", "code": 0, "text": text, "truncated": False}).encode()
        mode = argv[1]
        if mode == "--inventory":
            return 0, json.dumps({"authority": "not-granted", "initialTrees": {self.settings["taskId"]: "0" * 64},
                                  "policyDigest": "1" * 64, "launchDigest": "2" * 64, "environmentDigest": "3" * 64}).encode()
        if mode == "--preflight":
            assert (self.state / "journal/owner.json").exists()
            return 1, b"Manual batch launcher refused/held.\n"
        if mode == "--report":
            return 0, b'{"status":"incomplete","ownerRetained":true}'
        raise AssertionError("Unexpected operation; no --run/model path permitted")

    def run(self):
        return h1.run(self.settings, self.call, lambda _: str(self.workspace))


class Probes(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.fixture = Fixture(Path(self.temp.name))

    def test_success_is_only_partial_and_retains_both_owners(self):
        f = self.fixture
        result = f.run()
        self.assertEqual(result["status"], "partial-h1")
        self.assertEqual(result["qualification"], "not-granted")
        self.assertGreaterEqual(len(result["pending"]), 8)
        self.assertEqual(len(result["namespaceIds"]["controller"]), 7)
        self.assertTrue(all(result["namespaceIds"]["controller"][n] != result["namespaceIds"]["worker"][n]
                            for n in result["namespaceIds"]["controller"]))
        self.assertEqual(len(result["harnessSha256"]), 64)
        self.assertEqual(len(result["settingsSha256"]), 64)
        self.assertTrue(f.saw_inherited_fd)
        for name in ["h1-probe/owner.json", "journal/owner.json", "h1-probe/RESULT.json"]:
            self.assertTrue((f.state / name).exists())
            self.assertEqual((f.state / name).stat().st_mode & 0o777, 0o400)
        self.assertFalse(any("--run" in argv for argv, _, _ in f.calls))
        self.assertFalse((f.state / "admission.json").exists())
        self.assertFalse((f.state / "h1.json").exists())
        self.assertTrue(all(case["expectedExitObserved"] for case in result["cases"]))
        self.assertNotIn("synthetic failure", json.dumps(result))

    def test_replay_refuses_without_more_dispatch(self):
        f = self.fixture
        f.run()
        count = len(f.calls)
        with self.assertRaises(ValueError):
            f.run()
        self.assertEqual(len(f.calls), count)
        self.assertTrue((f.state / "h1-probe/RESULT.json").exists())

    def test_helper_failure_retains_attempt_and_no_retry(self):
        f = self.fixture
        f.fail = 2
        with self.assertRaises(RuntimeError):
            f.run()
        held = json.loads((f.state / "h1-probe/HELD.json").read_text())
        self.assertEqual(held["phase"], "tools")
        self.assertFalse(held["retry"])
        self.assertFalse((f.state / "h1-probe/RESULT.json").exists())
        self.assertEqual(len(f.calls), 2)
        with self.assertRaises((ValueError, FileExistsError)):
            f.run()
        self.assertEqual(len(f.calls), 2)

    def test_unexpected_exit_retains_only_closed_untrusted_hints(self):
        f = self.fixture
        f.fail = 1
        f.failure_output = (b"bwrap: Creating new namespace failed: Operation not permitted\n"
                            b"Tool boundary refused or outcome unknown; preserve ownership.\n"
                            b"SYNTHETIC-PRIVATE-OUTPUT-DO-NOT-RETAIN\n")
        with self.assertRaises(RuntimeError):
            f.run()
        held = json.loads((f.state / "h1-probe/HELD.json").read_text())
        case = held["cases"][0]
        self.assertEqual(case["name"], "write")
        self.assertEqual(case["diagnostic"], {"outputBytes": len(f.failure_output), "untrusted": True,
                         "hints": ["bubblewrap", "helper-held", "namespace", "operation-not-permitted"]})
        self.assertNotIn("SYNTHETIC-PRIVATE-OUTPUT", json.dumps(held))
        self.assertEqual(len(f.calls), 1)
        self.assertTrue((f.state / "h1-probe/owner.json").exists())
        self.assertFalse((f.state / "h1-probe/RESULT.json").exists())

    def test_unknown_binary_output_is_not_persisted_or_decoded(self):
        f = self.fixture
        f.fail = 1
        f.failure_output = b"SYNTHETIC-PRIVATE-UNKNOWN\x00\xff"
        with self.assertRaises(RuntimeError):
            f.run()
        held = json.loads((f.state / "h1-probe/HELD.json").read_text())
        self.assertEqual(held["cases"][0]["diagnostic"],
                         {"outputBytes": len(f.failure_output), "hints": [], "untrusted": True})
        self.assertNotIn("SYNTHETIC-PRIVATE-UNKNOWN", json.dumps(held))

    def test_transport_error_retains_probe_name_not_exception_value(self):
        f = self.fixture
        calls = []
        def broken(argv, body, pass_fds):
            calls.append(argv)
            raise OSError(13, "SYNTHETIC-PRIVATE-EXCEPTION")
        with self.assertRaises(RuntimeError):
            h1.run(f.settings, broken, lambda _: str(f.workspace))
        held = json.loads((f.state / "h1-probe/HELD.json").read_text())
        self.assertEqual(held["cases"][0], {"name": "write", "expectedExitObserved": False,
                         "diagnostic": {"transport": "os-error", "errno": 13}})
        self.assertNotIn("SYNTHETIC-PRIVATE-EXCEPTION", json.dumps(held))
        self.assertEqual(len(calls), 1)

    def test_unchanged_namespaces_hold_even_with_zero_exit(self):
        f = self.fixture
        f.bad_namespace = True
        with self.assertRaises(RuntimeError):
            f.run()
        self.assertTrue((f.state / "h1-probe/HELD.json").exists())
        self.assertFalse((f.state / "h1-probe/RESULT.json").exists())

    def test_credentials_or_authority_are_refused_without_read_or_replace(self):
        f = self.fixture
        (f.state / "profile").mkdir(mode=0o700)
        auth = f.state / "profile/auth.json"
        auth.symlink_to("/nonexistent-private-store")
        with self.assertRaises(ValueError):
            f.run()
        self.assertTrue(auth.is_symlink())
        self.assertEqual(f.calls, [])
        self.assertFalse((f.state / "h1-probe").exists())

    def test_existing_workspace_data_is_never_overwritten(self):
        f = self.fixture
        p = f.workspace / "existing"
        p.write_text("retain me")
        with self.assertRaises(ValueError):
            f.run()
        self.assertEqual(p.read_text(), "retain me")
        self.assertEqual(f.calls, [])

    def test_existing_journal_is_never_reconciled(self):
        f = self.fixture
        journal = f.state / "journal"
        journal.mkdir(mode=0o700)
        (journal / "owner.json").write_text("existing owner")
        with self.assertRaises(ValueError):
            f.run()
        self.assertEqual((journal / "owner.json").read_text(), "existing owner")
        self.assertEqual(f.calls, [])

    def test_receipt_failure_is_not_success(self):
        f = self.fixture
        original = h1.exclusive
        def fail_result(path, value):
            if path.name == "RESULT.json":
                raise OSError("synthetic full disk")
            return original(path, value)
        h1.exclusive = fail_result
        try:
            with self.assertRaises(RuntimeError):
                f.run()
        finally:
            h1.exclusive = original
        self.assertTrue((f.state / "journal/owner.json").exists())
        self.assertEqual(json.loads((f.state / "h1-probe/HELD.json").read_text())["phase"], "receipt")

    def test_malformed_success_reply_holds(self):
        f = self.fixture
        original = f.call
        def malformed(argv, body, pass_fds):
            original(argv, body, pass_fds)
            return 0, b'{"version":"wrong"}'
        with self.assertRaises(RuntimeError):
            h1.run(f.settings, malformed, lambda _: str(f.workspace))
        self.assertTrue((f.state / "h1-probe/HELD.json").exists())
        self.assertFalse((f.state / "h1-probe/RESULT.json").exists())

    def test_capture_transport_is_bounded_and_sterile(self):
        from unittest.mock import patch
        script = "import os,sys; assert 'SSH_AUTH_SOCK' not in os.environ; sys.stdout.buffer.write(sys.stdin.buffer.read())"
        with patch.dict(os.environ, {"SSH_AUTH_SOCK": "synthetic-not-a-socket"}):
            self.assertEqual(h1.invoke([sys.executable, "-I", "-c", script], b"fixture"), (0, b"fixture"))
        with self.assertRaises(ValueError):
            h1.invoke([sys.executable, "-I", "-c", "print('x'*131073)"])
        with self.assertRaises(ValueError):
            h1.invoke([sys.executable, "-I", "-c", "pass"], b"x" * 8193)

    def test_safe_diagnostic_categories_never_copy_exception_values(self):
        for error, kind in [(TimeoutError("private"), "timeout"), (ValueError("private"), "refused"),
                            (KeyboardInterrupt("private"), "interrupted"), (RuntimeError("private"), "other")]:
            with self.subTest(kind=kind):
                self.assertEqual(h1.transport_diagnostic(error), {"transport": kind})
        with self.assertRaises(ValueError):
            h1.output_diagnostic(b"x" * 131073)
        with self.assertRaises(ValueError):
            h1.output_diagnostic("private")

    def test_operational_deadline_has_safe_timeout_category(self):
        from unittest.mock import patch
        with patch.object(h1.time, "monotonic", side_effect=[0, 16]):
            with self.assertRaises(TimeoutError):
                h1.invoke([sys.executable, "-I", "-c", "pass"])

    def test_broad_state_permissions_refused(self):
        f = self.fixture
        f.state.chmod(0o755)
        with self.assertRaises(ValueError):
            f.run()
        self.assertEqual(f.calls, [])


@unittest.skipUnless(os.environ.get("PI_H1_METADATA"), "Nix package/unit metadata required")
class Metadata(unittest.TestCase):
    def test_unit_and_mounts_are_inert(self):
        metadata = json.loads(Path(os.environ["PI_H1_METADATA"]).read_text())
        self.assertTrue(metadata["valid"])
        self.assertEqual(metadata["wantedBy"], [])
        self.assertEqual(metadata["startAt"], [])
        self.assertFalse(metadata["restartIfChanged"])
        self.assertFalse(metadata["stopIfChanged"])
        self.assertEqual(metadata["service"]["Restart"], "no")
        self.assertEqual(len(metadata["mounts"]), 2)
        for mount in metadata["mounts"].values():
            self.assertEqual(mount["fsType"], "ext4")
            self.assertIn("noauto", mount["options"])
            self.assertTrue(mount["device"].startswith("/persist/pi-coordinator-images/"))
        self.assertNotEqual(metadata["entrypoint"], metadata["workerPackage"])

    def test_h1_retains_proc_kernel_api_and_process_tunable_protections(self):
        service = json.loads(Path(os.environ["PI_H1_METADATA"]).read_text())["service"]
        for key, value in {"MountAPIVFS": True, "ProcSubset": "all", "ProtectProc": "invisible",
                           "ProtectKernelTunables": True, "ProtectKernelModules": True,
                           "ProtectControlGroups": True, "NoNewPrivileges": True,
                           "CapabilityBoundingSet": "", "ProtectSystem": "strict"}.items():
            with self.subTest(setting=key):
                self.assertEqual(service[key], value)

    def test_built_root_has_api_and_private_tmp_mount_targets(self):
        metadata = json.loads(Path(os.environ["PI_H1_METADATA"]).read_text())
        service = metadata["service"]
        self.assertTrue(service["MountAPIVFS"])
        self.assertTrue(service["PrivateTmp"])
        root = Path(service["RootDirectory"])
        # Independent artifact expectations: never start systemd or a namespace here.
        required = ["dev", "proc", "sys", "run", "tmp", "var/tmp", "nix/store", "etc/ssl/certs"]
        required += [name.lstrip("/") for name in metadata["mounts"]]
        for name in required:
            with self.subTest(path=name):
                path = root / name
                self.assertTrue(path.is_dir(), f"Missing namespace mount target: /{name}")
                self.assertFalse(path.is_symlink())
                self.assertFalse(path.stat().st_mode & 0o222)
        for name in ["etc/hosts", "etc/resolv.conf"]:
            with self.subTest(path=name):
                path = root / name
                self.assertTrue(path.is_file())
                self.assertFalse(path.is_symlink())
                self.assertEqual(path.stat().st_size, 0)

    def test_actual_immutable_paths_and_synthetic_launch(self):
        settings = json.loads(Path(os.environ["PI_H1_SETTINGS"]).read_text())
        for key in ["helper", "launcher", "launch", "workerSource", "python", "storeCanary"]:
            h1.immutable(settings[key])
        launch = json.loads(Path(os.environ["PI_H1_LAUNCH"]).read_text())
        self.assertEqual(launch["policyDigest"], "0" * 64)
        self.assertEqual(launch["batch"]["accountRef"], "h1_synthetic_only")
        self.assertEqual(launch["batch"]["tasks"][0]["id"], settings["taskId"])
        self.assertEqual(launch["batch"]["helper"], settings["helper"])
        self.assertEqual(settings["launcher"], os.environ["PI_FIXED_BATCH"])
        policy = json.loads(Path(os.environ["PI_H1_POLICY"]).read_text())
        self.assertNotIn(settings["storeCanary"], policy["runtimePaths"])
        self.assertEqual(policy["workspaces"], {settings["taskId"]: settings["workspace"]})


if __name__ == "__main__":
    unittest.main()
