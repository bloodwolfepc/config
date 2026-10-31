import contextlib
import io
import json
import os
import re
import shutil
import sqlite3
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import backup as tool


class BackupTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.state = self.root / "state"
        self.export = self.state / "export"
        self.state.mkdir()

    def put(self, relative, content="fixture"):
        path = self.home / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def put_profiles(self):
        expected = {
            "legcord": [
                ".config/legcord/Preferences",
                ".config/legcord/Cookies",
                ".config/legcord/Local Storage/leveldb/state.ldb",
                ".config/legcord/themes/custom.css",
            ],
            "anki": [
                ".local/share/Anki2/prefs21.db",
                ".local/share/Anki2/User 1/collection.anki2",
                ".local/share/Anki2/User 1/collection.anki2-wal",
                ".local/share/Anki2/User 1/collection.media/audio.ogg",
                ".local/share/Anki2/addons21/custom/config.json",
            ],
            "firefox": [
                f".config/mozilla/firefox/example.default/{name}"
                for name in (
                    "key4.db",
                    "logins.json",
                    "cookies.sqlite",
                    "places.sqlite-wal",
                    "sessionstore-backups/recovery.jsonlz4",
                    "browser-extension-data/custom/storage.js",
                )
            ],
            "terraria": [
                ".local/share/Terraria/Worlds/world.wld",
                ".local/share/Terraria/Players/person.plr",
                ".local/share/Terraria/tModLoader/Mods/custom.tmod",
                ".local/share/Steam/userdata/123/105600/remote/players/cloud.plr",
                ".local/share/Steam/steamapps/compatdata/105600/pfx/drive_c/users/steamuser/Documents/My Games/Terraria/Worlds/proton.wld",
                ".var/app/com.valvesoftware.Steam/data/Terraria/Worlds/sandbox.wld",
            ],
        }
        for paths in expected.values():
            for relative in paths:
                self.put(relative, f"precious {relative}")
        self.put(
            ".config/mozilla/firefox/profiles.ini",
            "[Profile0]\nPath=example.default\nIsRelative=1\n",
        )
        return expected

    def test_full_profiles_include_authentication_and_skip_only_runtime_caches(self):
        expected = self.put_profiles()
        omitted = {
            "legcord": [
                ".config/legcord/Cache/data",
                ".config/legcord/Code Cache/javascript",
                ".config/legcord/SingletonLock",
                ".config/legcord/.org.chromium.Chromium.tmp",
            ],
            "anki": [".local/share/Anki2/logs/old.log"],
            "firefox": [
                ".config/mozilla/firefox/example.default/cache2/cache",
                ".config/mozilla/firefox/example.default/parent.lock",
            ],
            "terraria": [
                ".local/share/Steam/config/loginusers.vdf",
                ".local/share/Steam/userdata/123/570/remote/unrelated",
            ],
        }
        for paths in omitted.values():
            for relative in paths:
                self.put(relative, "regenerable or unrelated")
        self.put(".local/share/task/taskchampion.sqlite3", "untouched Taskwarrior")
        self.put(".config/sops/age/key.txt", "unrelated credential store")
        for group, paths in expected.items():
            export = self.state / group
            tool.prepare_export(self.home, export, group)
            for relative in paths:
                self.assertEqual(
                    (export / "home" / relative).read_text(), f"precious {relative}"
                )
            for relative in omitted[group] + [
                ".local/share/task/taskchampion.sqlite3",
                ".config/sops/age/key.txt",
            ]:
                self.assertFalse((export / "home" / relative).exists(), relative)

    def test_missing_profile_does_not_make_a_successful_empty_backup(self):
        for group in tool.PROFILE_PATHS:
            with self.assertRaisesRegex(ValueError, "No .* data found"):
                tool.prepare_export(self.home, self.state / group, group)

    def test_external_firefox_profile_is_not_silently_omitted(self):
        external = self.root / "external-profile"
        external.mkdir()
        self.put(
            ".config/mozilla/firefox/profiles.ini",
            f"[Profile0]\nPath={external}\nIsRelative=0\n",
        )
        with self.assertRaisesRegex(ValueError, "explicit inclusion"):
            tool.prepare_export(self.home, self.export, "firefox")

    def test_linked_anki_media_is_not_silently_omitted(self):
        profile = self.home / ".local/share/Anki2/User 1"
        profile.mkdir(parents=True)
        (profile / "collection.media").symlink_to(self.root, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "explicit inclusion"):
            tool.prepare_export(self.home, self.export, "anki")

    def test_busy_firefox_does_not_block_other_groups_or_share_success_markers(self):
        self.put_profiles()
        env = {
            "ANGEL_BACKUP_HOME": str(self.home),
            "ANGEL_BACKUP_STATE": str(self.state),
        }
        with (
            patch.dict(os.environ, env),
            patch.object(tool, "configure_remote") as remote,
            patch.object(
                tool, "apps_busy", side_effect=lambda group: group == "firefox"
            ),
            patch.object(tool, "restic") as restic,
            contextlib.redirect_stderr(io.StringIO()),
        ):
            self.assertEqual(tool.main(["scheduled", "--group", "firefox"]), 75)
            remote.assert_not_called()
            self.assertEqual(tool.main(["scheduled"]), 0)
            self.assertEqual(tool.main(["scheduled", "--group", "anki"]), 0)
            self.assertTrue((self.state / "last-success").exists())
            self.assertTrue((self.state / "profiles/anki/last-success").exists())
            self.assertFalse((self.state / "profiles/firefox/last-success").exists())
            before = restic.call_count
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(tool.main(["scheduled", "--group", "anki"]), 0)
            self.assertEqual(restic.call_count, before)
            tags = [
                call.args[call.args.index("--tag") + 1]
                for call in restic.call_args_list
                if "--tag" in call.args
            ]
            self.assertEqual(
                tags, ["angel-state", "angel-state", "angel-anki", "angel-anki"]
            )

    def test_wrapped_state_apps_are_detected_without_blocking_other_groups(self):
        with patch.object(
            tool.subprocess, "run", return_value=subprocess.CompletedProcess([], 1)
        ) as run:
            self.assertFalse(tool.apps_busy("state"))
            arguments = run.call_args.args[0]
            self.assertIn("-i", arguments)
            pattern = arguments[-1]
        for name in (
            ".gimp-3.0-wrap",
            ".krita-wrapped",
            ".prismlauncher-",
            "ArdourGUI",
            "java",
        ):
            self.assertIsNotNone(re.fullmatch(pattern, name, re.IGNORECASE), name)
        for name in ("firefox", "anki", "legcord", "zathura"):
            self.assertIsNone(re.fullmatch(pattern, name, re.IGNORECASE), name)

    def test_interpreter_launched_apps_are_detected(self):
        for group in ("anki", "legcord"):
            with patch.object(
                tool.subprocess,
                "run",
                side_effect=[
                    subprocess.CompletedProcess([], 1),
                    subprocess.CompletedProcess([], 0),
                ],
            ) as run:
                self.assertTrue(tool.apps_busy(group))
                self.assertIn("-f", run.call_args.args[0])

    def test_selection_excludes_accounts_and_keeps_worlds_and_settings(self):
        self.put(".config/GIMP/3.0/gimprc")
        self.put("projects/art/krita/project.kra")
        instance = ".local/share/PrismLauncher/instances/example"
        self.put(instance + "/instance.cfg")
        self.put(instance + "/mmc-pack.json")
        self.put(instance + "/.minecraft/saves/world/level.dat")
        self.put(instance + "/.minecraft/mods/custom.jar")
        self.put(instance + "/.minecraft/logs/latest.log")
        self.put(".local/share/PrismLauncher/accounts.json", "private account fixture")
        self.put(".pi/agent/auth.json", "private auth fixture")
        self.put(".config/millennium/quick.css")
        self.put(
            ".config/millennium/config.json",
            json.dumps(
                {
                    "general": {"injectCSS": True},
                    "themes": {"activeTheme": "example"},
                    "network": {"proxyPassword": "NEVER_EXPORT"},
                    "unexpected": "NEVER_EXPORT",
                }
            ),
        )
        tool.prepare_export(self.home, self.export)
        self.assertTrue((self.export / "home/projects/art/krita/project.kra").exists())
        self.assertTrue(
            (
                self.export / "home" / instance / ".minecraft/saves/world/level.dat"
            ).exists()
        )
        self.assertTrue(
            (self.export / "home" / instance / ".minecraft/mods/custom.jar").exists()
        )
        self.assertFalse((self.export / "home" / instance / ".minecraft/logs").exists())
        self.assertFalse(
            (self.export / "home/.local/share/PrismLauncher/accounts.json").exists()
        )
        self.assertFalse((self.export / "home/.pi").exists())
        self.assertNotIn(
            "NEVER_EXPORT",
            (self.export / "home/.config/millennium/config.json").read_text(),
        )

    def test_sqlite_backup_includes_uncheckpointed_wal(self):
        source = self.home / ".local/share/krita/resourcecache.sqlite"
        source.parent.mkdir(parents=True)
        with contextlib.closing(sqlite3.connect(source)) as database:
            database.execute("PRAGMA journal_mode=WAL")
            database.execute("CREATE TABLE resources (name TEXT)")
            database.execute("INSERT INTO resources VALUES ('custom brush')")
            database.commit()
            self.assertTrue(Path(str(source) + "-wal").exists())
            tool.prepare_export(self.home, self.export)
        copied = self.export / "home/.local/share/krita/resourcecache.sqlite"
        with contextlib.closing(sqlite3.connect(copied)) as database:
            self.assertEqual(
                database.execute("SELECT name FROM resources").fetchall(),
                [("custom brush",)],
            )
        self.assertFalse(Path(str(copied) + "-wal").exists())

    def test_full_anki_profile_keeps_committed_wal_data(self):
        source = self.home / ".local/share/Anki2/User 1/collection.anki2"
        source.parent.mkdir(parents=True)
        with contextlib.closing(sqlite3.connect(source)) as original:
            original.execute("PRAGMA journal_mode=WAL")
            original.execute("CREATE TABLE notes (content TEXT)")
            original.execute("INSERT INTO notes VALUES ('precious card')")
            original.commit()
            tool.prepare_export(self.home, self.export, "anki")
            copied = self.export / "home" / source.relative_to(self.home)
            self.assertTrue(Path(str(copied) + "-wal").exists())
            with contextlib.closing(sqlite3.connect(copied)) as restored:
                self.assertEqual(
                    restored.execute("SELECT content FROM notes").fetchall(),
                    [("precious card",)],
                )

    def test_sqlite_export_refuses_symlink_parent_without_touching_source(self):
        source = self.put("original.sqlite", "not a database")
        destination_parent = self.root / "linked"
        destination_parent.symlink_to(self.home, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "symlink"):
            tool.backup_sqlite(source, destination_parent / source.name)
        self.assertEqual(source.read_text(), "not a database")

    def test_minecraft_symlink_is_not_followed(self):
        instance = self.home / ".local/share/PrismLauncher/instances/example"
        instance.mkdir(parents=True)
        (instance / ".minecraft").symlink_to(self.root, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "symlinked"):
            tool.prepare_export(self.home, self.export)

    def test_busy_and_recent_scheduled_backup_make_no_network_calls(self):
        env = {
            "ANGEL_BACKUP_HOME": str(self.home),
            "ANGEL_BACKUP_STATE": str(self.state),
        }
        with (
            patch.dict(os.environ, env),
            patch.object(tool, "configure_remote") as remote,
            patch.object(tool, "apps_busy", return_value=True),
            contextlib.redirect_stderr(io.StringIO()),
        ):
            self.assertEqual(tool.main(["scheduled"]), 75)
            remote.assert_not_called()
            (self.state / "last-success").touch()
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(tool.main(["scheduled"]), 0)
            remote.assert_not_called()

    def test_partial_backup_does_not_prune_or_record_success(self):
        env = {
            "ANGEL_BACKUP_HOME": str(self.home),
            "ANGEL_BACKUP_STATE": str(self.state),
        }
        self.put("projects/art/gimp/project.xcf")
        with (
            patch.dict(os.environ, env),
            patch.object(tool, "configure_remote"),
            patch.object(tool, "apps_busy", return_value=False),
            patch.object(
                tool,
                "restic",
                side_effect=subprocess.CalledProcessError(3, ["restic", "backup"]),
            ) as restic,
            contextlib.redirect_stderr(io.StringIO()),
        ):
            self.assertEqual(tool.main(["backup"]), 1)
        self.assertEqual(restic.call_count, 1)
        self.assertFalse((self.state / "last-success").exists())
        self.assertFalse(self.export.exists())

    def test_failed_integrity_check_prevents_retention(self):
        env = {
            "ANGEL_BACKUP_HOME": str(self.home),
            "ANGEL_BACKUP_STATE": str(self.state),
        }
        self.put("projects/art/gimp/project.xcf")

        def command(*arguments):
            if arguments[0] == "check":
                raise subprocess.CalledProcessError(1, ["restic", "check"])

        with (
            patch.dict(os.environ, env),
            patch.object(tool, "configure_remote"),
            patch.object(tool, "apps_busy", return_value=False),
            patch.object(tool, "restic", side_effect=command) as restic,
            contextlib.redirect_stderr(io.StringIO()),
        ):
            self.assertEqual(tool.main(["backup"]), 1)
        self.assertEqual(
            [call.args[0] for call in restic.call_args_list], ["backup", "check"]
        )
        self.assertFalse((self.state / "last-success").exists())

    @unittest.skipUnless(shutil.which("restic"), "restic is not in the environment")
    def test_real_local_repository_backup_and_restore(self):
        password = self.root / "password"
        password.write_text("test-only-password")
        env = {
            "ANGEL_BACKUP_HOME": str(self.home),
            "ANGEL_BACKUP_STATE": str(self.state),
            "RESTIC_REPOSITORY": str(self.root / "repository"),
            "RESTIC_PASSWORD_FILE": str(password),
        }
        self.put("projects/art/krita/project.kra", "precious fixture")
        self.put(".config/GIMP/3.0/gimprc", "personal settings")
        expected_profiles = self.put_profiles()
        destination = self.root / "restored"

        def local_restic(*arguments, **kwargs):
            return subprocess.run(
                ["restic", *arguments],
                check=True,
                capture_output=True,
                text=True,
                **kwargs,
            )

        with (
            patch.dict(os.environ, env),
            patch.object(tool, "configure_remote"),
            patch.object(tool, "apps_busy", return_value=False),
            patch.object(tool, "restic", side_effect=local_restic),
        ):
            local_restic("init")
            self.assertEqual(tool.main(["backup"]), 0)
            self.assertTrue((self.state / "last-success").exists())
            self.assertFalse(self.export.exists())
            self.assertEqual(tool.main(["restore", "latest", str(destination)]), 0)
            self.assertEqual(
                (destination / "home/projects/art/krita/project.kra").read_text(),
                "precious fixture",
            )
            self.assertEqual(
                (destination / "home/.config/GIMP/3.0/gimprc").read_text(),
                "personal settings",
            )
            with contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(tool.main(["restore", "latest", str(destination)]), 1)
            for group, paths in expected_profiles.items():
                self.assertEqual(tool.main(["backup", "--group", group]), 0)
                restored = self.root / f"restored-{group}"
                self.assertEqual(
                    tool.main(["--group", group, "restore", "latest", str(restored)]), 0
                )
                for relative in paths:
                    self.assertEqual(
                        (restored / "home" / relative).read_text(),
                        f"precious {relative}",
                    )
            snapshots = json.loads(local_restic("snapshots", "--json").stdout)
            self.assertEqual(
                {tuple(snapshot["tags"]) for snapshot in snapshots},
                {(f"angel-{group}",) for group in tool.GROUP_BUSY_APPS},
            )
            self.assertEqual(len(snapshots), 5)


if __name__ == "__main__":
    unittest.main()
