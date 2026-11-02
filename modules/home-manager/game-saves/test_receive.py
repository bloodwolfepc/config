import json
import os
from pathlib import Path
import stat
import tempfile
import unittest
from unittest import mock
import zipfile

from receive import Receiver, Refused, steam_running


class ReceiveTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.enterContext(mock.patch("receive.steam_running", return_value=False))
        self.root = Path(self.temp.name)
        self.state = self.root / "state"
        self.config = self.state / "native"
        self.config.mkdir(parents=True)
        self.inbox = self.root / "inbox"
        self.inbox.mkdir()
        self.backups = self.root / "backups"
        self.save = self.root / "game/save.dat"
        self.save.parent.mkdir()
        self.save.write_bytes(b"PC original")
        self.policy = {
            "manifest": {"enable": False},
            "cloud": {"synchronize": False},
            "release": {"check": False},
            "customGames": [{"name": "Fixture One", "files": [str(self.save)]}],
        }
        self.write_policy()
        self.receiver = Receiver(
            self.state, self.inbox, self.backups, os.environ["LUDUSAVI_TEST_BIN"]
        )

    def write_policy(self):
        (self.config / "config.yaml").write_text(json.dumps(self.policy))

    def archive(self, entries=None, event="001"):
        archive = self.inbox / f"Fixture One--{event}.zip"
        with zipfile.ZipFile(archive, "w") as out:
            for name, value in (
                entries or {"export/save.dat": b"Phone progress"}
            ).items():
                out.writestr(name, value)
        return archive

    def test_actual_native_import_preserves_native_original_and_ignores_replay(self):
        archive = self.archive()
        self.assertEqual(self.receiver.apply(archive), "applied")
        self.assertEqual(self.save.read_bytes(), b"Phone progress")
        self.assertFalse(self.receiver.pending.exists())
        self.assertEqual(self.receiver.apply(archive), "already applied")
        listing = self.receiver.call(
            self.config,
            "backups",
            "--api",
            "--path",
            str(self.backups),
            "--",
            "Fixture One",
        )
        self.assertIn("Fixture One", listing["games"])
        versions = listing["games"]["Fixture One"]["backups"]
        locked = [entry for entry in versions if entry["locked"]]
        self.assertEqual(len(locked), 1)
        self.receiver.game(
            self.receiver.call(
                self.config,
                "restore",
                "--force",
                "--api",
                "--no-cloud-sync",
                "--path",
                str(self.backups),
                "--backup",
                locked[0]["name"],
                "--",
                "Fixture One",
            ),
            "Fixture One",
        )
        self.assertEqual(self.save.read_bytes(), b"PC original")

    def test_same_payload_new_event_is_deliberately_applied_again(self):
        import shutil

        first = self.archive()
        self.receiver.apply(first)
        self.save.write_bytes(b"PC played again")
        second = self.inbox / "Fixture One--002.zip"
        shutil.copyfile(first, second)
        self.assertEqual(self.receiver.apply(second), "applied")
        self.assertEqual(self.save.read_bytes(), b"Phone progress")

    def test_mutating_a_processed_event_and_competing_events_are_refused(self):
        self.receiver.apply(self.archive())
        with self.assertRaisesRegex(Refused, "ID was changed"):
            self.receiver.apply(self.archive({"save.dat": b"changed upload"}))
        self.archive(event="002")
        self.archive(event="003")
        with self.assertRaisesRegex(Refused, "Multiple new"):
            self.receiver.run()
        self.assertEqual(self.save.read_bytes(), b"Phone progress")

    def test_equal_timestamps_use_native_mapping_order_and_verified_snapshot(self):
        self.policy["backup"] = {"retention": {"full": 7, "differential": 0}}
        self.write_policy()
        self.receiver.call(
            self.config,
            "backup",
            "--force",
            "--api",
            "--no-cloud-sync",
            "--path",
            str(self.backups),
            "--",
            "Fixture One",
        )
        self.save.write_bytes(b"new PC original")
        original = self.receiver.call

        def tied(config, *args, **kwargs):
            result = original(config, *args, **kwargs)
            if args[0] == "backups" and "--api" in args:
                for entry in result["games"]["Fixture One"]["backups"]:
                    entry["when"] = "2000-01-01T00:00:00Z"
            return result

        with mock.patch.object(self.receiver, "call", side_effect=tied):
            self.receiver.apply(self.archive())
        versions = original(
            self.config,
            "backups",
            "--api",
            "--path",
            str(self.backups),
            "--",
            "Fixture One",
        )["games"]["Fixture One"]["backups"]
        locked = [entry for entry in versions if entry["locked"]]
        self.assertEqual(len(locked), 1)
        original(
            self.config,
            "restore",
            "--force",
            "--api",
            "--no-cloud-sync",
            "--path",
            str(self.backups),
            "--backup",
            locked[0]["name"],
            "--",
            "Fixture One",
        )
        self.assertEqual(self.save.read_bytes(), b"new PC original")

    def test_uninspectable_same_user_process_fails_closed(self):
        proc = self.root / "proc"
        process = proc / "999999999"
        process.mkdir(parents=True)
        env = process / "environ"
        env.write_bytes(b"SteamAppId=12345\\0")
        env.chmod(0)
        with self.assertRaisesRegex(Refused, "Cannot inspect"):
            steam_running(proc)

    def test_known_session_daemon_does_not_indefinitely_block_imports(self):
        proc = self.root / "proc"
        process = proc / "999999999"
        process.mkdir(parents=True)
        (process / "comm").write_text("gamemoded\n")
        (process / "cgroup").write_text("0::/user.slice/app.slice/gamemoded.service\n")
        env = process / "environ"
        env.write_bytes(b"")
        env.chmod(0)
        self.assertFalse(steam_running(proc))

    def test_native_cloud_filter_also_limits_incoming_requests(self):
        self.policy["manifest"] = {"enable": True}
        self.policy["customGames"] = []
        self.policy["backup"] = {"filter": {"cloud": {"exclude": True, "steam": True}}}
        self.write_policy()
        (self.config / "manifest.yaml").write_text(
            json.dumps(
                {
                    "Fixture One": {
                        "files": {str(self.save): {}},
                        "cloud": {"steam": True},
                    }
                }
            )
        )
        with self.assertRaises(Refused):
            self.receiver.apply(self.archive())
        self.assertEqual(self.save.read_bytes(), b"PC original")

    def test_unknown_duplicate_traversal_and_numbered_names_are_refused(self):
        for entries in (
            {"unknown.dat": b"bad"},
            {"../save.dat": b"bad"},
            {"save (1).dat": b"bad"},
            {"a/save.dat": b"one", "b/save.dat": b"two"},
        ):
            with self.subTest(entries=list(entries)):
                with self.assertRaises(Refused):
                    self.receiver.apply(self.archive(entries))
                self.assertEqual(self.save.read_bytes(), b"PC original")
                self.assertFalse(self.receiver.pending.exists())

    def test_ambiguous_native_destinations_are_refused(self):
        other = self.root / "another/save.dat"
        other.parent.mkdir()
        other.write_bytes(b"other")
        self.policy["customGames"][0]["files"].append(str(other))
        self.write_policy()
        with self.assertRaisesRegex(Refused, "ambiguous"):
            self.receiver.apply(self.archive())
        self.assertEqual(other.read_bytes(), b"other")

    def test_archive_symlink_is_refused(self):
        archive = self.inbox / "Fixture One--001.zip"
        with zipfile.ZipFile(archive, "w") as out:
            item = zipfile.ZipInfo("save.dat")
            item.external_attr = (stat.S_IFLNK | 0o777) << 16
            out.writestr(item, "elsewhere")
        with self.assertRaisesRegex(Refused, "Unsafe"):
            self.receiver.apply(archive)

    def test_failed_restore_leaves_recovery_marker_and_original_native_backup(self):
        original = self.receiver.call

        def fail(config, *args, **kwargs):
            if args[0] == "restore" and "--force" in args:
                raise Refused("injected native restore failure")
            return original(config, *args, **kwargs)

        with mock.patch.object(self.receiver, "call", side_effect=fail):
            with self.assertRaises(Refused):
                self.receiver.apply(self.archive())
        self.assertTrue(self.receiver.pending.exists())
        self.assertTrue(list(self.backups.rglob("mapping.yaml")))
        with self.assertRaisesRegex(Refused, "Interrupted"):
            self.receiver.run()

    def test_successful_but_incomplete_or_unwritten_restore_keeps_pending(self):
        original = self.receiver.call
        for reported in ({}, {str(self.save): {"change": "Different", "bytes": 14}}):
            with self.subTest(reported=bool(reported)):
                self.receiver.pending.unlink(missing_ok=True)

                def skip_write(config, *args, **kwargs):
                    if args[0] == "restore" and "--force" in args:
                        return {
                            "games": {
                                "Fixture One": {
                                    "decision": "Processed",
                                    "files": reported,
                                    "registry": {},
                                }
                            }
                        }
                    return original(config, *args, **kwargs)

                with mock.patch.object(self.receiver, "call", side_effect=skip_write):
                    with self.assertRaises(Refused):
                        self.receiver.apply(self.archive())
                self.assertTrue(self.receiver.pending.exists())
                self.assertEqual(self.save.read_bytes(), b"PC original")
                self.assertEqual(list((self.state / "received").iterdir()), [])

    def test_running_game_defers_without_applying(self):
        self.archive()
        with mock.patch("receive.steam_running", return_value=True):
            self.assertIn("deferred", self.receiver.run()["state"])
            with self.assertRaisesRegex(Refused, "active"):
                self.receiver.run(before_launch=True)
        self.assertEqual(self.save.read_bytes(), b"PC original")


if __name__ == "__main__":
    unittest.main()
