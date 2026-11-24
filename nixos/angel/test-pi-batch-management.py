"""Offline collector fixtures. No mounted-volume, namespace, service or model qualification."""
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace

spec = importlib.util.spec_from_file_location("management", sys.argv.pop(1))
management = importlib.util.module_from_spec(spec)
spec.loader.exec_module(management)


class CollectorSourceTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.workspace = self.root / "workspace"
        self.workspace.mkdir(mode=0o700)
        (self.workspace / "file.txt").write_text("one")

    def test_bounded_tree_and_binary_blobs_are_stable_content_bound(self):
        (self.workspace / "snow-雪.txt").write_bytes(b"\0binary\xff")
        blobs = self.root / "blobs"
        blobs.mkdir(mode=0o700)
        tree = management.inspect(self.workspace, blobs)
        self.assertEqual(len(tree["files"]), 2)
        self.assertEqual(tree["treeDigest"], management.digest(management.encoded(tree["files"])))
        for entry in tree["files"]:
            body = (blobs / entry["sha256"]).read_bytes()
            self.assertEqual(management.digest(body), entry["sha256"])
            self.assertEqual((blobs / entry["sha256"]).stat().st_mode & 0o777, 0o400)
        (self.workspace / "file.txt").write_text("two")
        self.assertNotEqual(tree["treeDigest"], management.inspect(self.workspace)["treeDigest"])

    def test_links_special_oversized_git_and_privileged_files_refuse(self):
        for kind in ("symlink", "hardlink", "fifo", "large", "git", "setuid"):
            with self.subTest(kind=kind):
                p = self.workspace / "bad"
                if kind == "symlink":
                    p.symlink_to("file.txt")
                elif kind == "hardlink":
                    os.link(self.workspace / "file.txt", p)
                elif kind == "fifo":
                    os.mkfifo(p)
                elif kind == "large":
                    p.write_bytes(b"x" * 1048577)
                elif kind == "git":
                    p = self.workspace / ".git"
                    p.mkdir()
                else:
                    p.write_text("bad")
                if kind == "setuid":
                    # Nix forbids creating setuid files; synthetic metadata tests the refusal only.
                    real_stat = os.stat
                    def privileged(name, **kwargs):
                        info = real_stat(name, **kwargs)
                        return SimpleNamespace(st_dev=info.st_dev, st_uid=info.st_uid, st_nlink=1, st_mode=info.st_mode | 0o4000) if name == "bad" else info
                    with patch.object(management.os, "stat", privileged), self.assertRaises(ValueError):
                        management.inspect(self.workspace)
                else:
                    with self.assertRaises((ValueError, OSError)):
                        management.inspect(self.workspace)
                p.rmdir() if p.is_dir() else p.unlink()

    def test_second_pass_detects_changed_files_and_metadata(self):
        scan = management.scan
        calls = 0
        def changing(*args):
            nonlocal calls
            result = scan(*args)
            calls += 1
            if calls == 1:
                (self.workspace / "file.txt").write_text("concurrent update")
            return result
        with patch.object(management, "scan", changing), self.assertRaises(ValueError):
            management.inspect(self.workspace)

    def test_capture_is_exclusive_owner_bound_and_manifest_last(self):
        journal = self.root / "journal"
        journal.mkdir(mode=0o700)
        (journal / "owner.json").write_text(json.dumps({"runId": "fixture-run", "approvalId": "fixture-approval"}))
        run = journal / "run-fixture-run"
        run.mkdir(mode=0o700)
        policy = {"workspaces": {"fixture-task": str(self.workspace)}, "journalRoot": str(journal)}
        tree = management.inspect(self.workspace)
        request = {"version": "pi-batch-management/v1", "action": "preflight", "runId": "fixture-run", "approvalId": "fixture-approval", "tasks": [{"id": "fixture-task", "base": "a" * 40, "initialTree": tree["treeDigest"]}]}
        management.manage(policy, request, lambda paths: paths)  # Synthetic workspace qualification only.
        self.assertEqual(list(run.iterdir()), [])
        request["action"] = "before"
        result = management.manage(policy, request, lambda paths: paths)
        self.assertEqual(management.digest((run / "artifacts-before" / "bundle.json").read_bytes()), result["bundleDigest"])
        with self.assertRaises(FileExistsError):
            management.manage(policy, request, lambda paths: paths)
        request["action"] = "after"
        request["approvalId"] = "another-approval"
        with self.assertRaises(ValueError):
            management.manage(policy, request, lambda paths: paths)
        self.assertFalse((run / "artifacts-after").exists())
        self.assertTrue((journal / "owner.json").exists())


unittest.main()
