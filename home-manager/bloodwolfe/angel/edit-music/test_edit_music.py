import importlib.util
import io
import json
import os
from pathlib import Path
import pty
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).with_name("edit_music.py")
spec = importlib.util.spec_from_file_location("edit_music", SCRIPT)
client = importlib.util.module_from_spec(spec)
spec.loader.exec_module(client)

# This executable is the only SSH reachable by the CLI tests. No real server is used.
FAKE_SSH = r'''
import base64, json, os, shlex, sys
arguments = sys.argv[1:]
if '-O' in arguments: sys.exit(0)
command = shlex.split(arguments[-1])
event = {"options": arguments[:-1], "command": command}
if command[0] == 'srv-compose' and 'tee' in command or command[1:2] == ['receive']:
    event['input'] = base64.b64encode(sys.stdin.buffer.read()).decode()
with open(os.environ['TEST_LOG'], 'a') as log:
    log.write(json.dumps(event) + '\n')
mode = os.environ.get('TEST_MODE', '')
if mode == 'missing':
    print('private error https://invalid.test/?signature=DO-NOT-PRINT', file=sys.stderr)
    sys.exit(127)
if command[0] == 'srv-compose':
    if 'zsh' in command: print('interactive zsh')
    sys.exit(0)
action = command[1]
if action == 'version':
    commands = %COMMANDS%
    if mode == 'missing-command': commands.remove('publish')
    print(json.dumps({'version': 0 if mode == 'old' else 1, 'backend': 'srv-music-workbench', 'commands': commands}))
elif action == 'check':
    if mode == 'stale':
        print('unsafe legacy publisher private error', file=sys.stderr)
        sys.exit(1)
    print(json.dumps({'version': 1, 'protocol': 'music-workbench'}))
elif action in ('acquire', 'receive', 'extract'):
    if mode == 'failure':
        print(command[-1], file=sys.stderr)
        sys.exit(1)
    print('/outside/unsafe' if mode == 'bad-path' else '/workspace/staging/returned-job/content')
elif action == 'import': print('interactive import')
elif action == 'cache-clean': print('cache cleaned')
else:
    print(json.dumps({'ready': False, 'warnings': ['verify edition'], 'blockers': ['art missing'],
                      'url': 'https://invalid.test/?signature=DO-NOT-PRINT', 'basis': 'private basis',
                      'album': 'example'}))
'''.replace("%COMMANDS%", repr(sorted(client.HOST_COMMANDS)))


class CLI(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.log = self.root / "calls.jsonl"
        executable = self.root / "ssh"
        executable.write_text("#!" + sys.executable + "\n" + FAKE_SSH)
        executable.chmod(0o700)
        self.theme = self.root / "starship.toml"
        self.theme.write_text("format = '$directory$character'\n")

    def run_cli(self, *args, mode="", tty=False, theme=True):
        env = dict(os.environ, PATH=str(self.root), TEST_LOG=str(self.log), TEST_MODE=mode,
                   PYTHONDONTWRITEBYTECODE="1", STARSHIP_CONFIG=str(self.theme if theme else self.root / 'missing'))
        command = [sys.executable, "-B", str(SCRIPT), *args]
        if not tty:
            return subprocess.run(command, env=env, capture_output=True, text=True)
        master, slave = pty.openpty()
        try:
            result = subprocess.run(command, env=env, stdin=slave, stdout=slave, stderr=slave)
            os.close(slave)
            slave = None
            output = b""
            while True:
                try:
                    chunk = os.read(master, 65536)
                    if not chunk:
                        break
                    output += chunk
                except OSError:
                    break
            return subprocess.CompletedProcess(command, result.returncode, output.decode(), "")
        finally:
            os.close(master)
            if slave is not None:
                os.close(slave)

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def actions(self):
        return [call['command'][1] for call in self.calls() if call['command'][0] == 'srv-music-workbench']

    def test_no_args_checks_then_uploads_theme_and_opens_zsh(self):
        result = self.run_cli(tty=True)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.actions(), ['version', 'check'])
        upload, shell = self.calls()[-2:]
        self.assertIn('-T', upload['options'])
        self.assertIn('BatchMode=yes', upload['options'])
        self.assertIn('-t', shell['options'])
        self.assertEqual(shell['command'][-2:], ['zsh', '-l'])
        import base64
        self.assertEqual(base64.b64decode(upload['input']), self.theme.read_bytes())

    def test_missing_old_incomplete_and_stale_fail_closed(self):
        for mode in ('missing', 'old', 'missing-command', 'stale'):
            with self.subTest(mode=mode):
                self.log.unlink(missing_ok=True)
                result = self.run_cli('--dl', 'https://example.test/a.zip?signature=DO-NOT-PRINT', mode=mode)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('legacy', result.stderr)
                self.assertNotIn('DO-NOT-PRINT', result.stderr + result.stdout)
                self.assertNotIn('acquire', self.actions())
                self.assertTrue(all(c['command'][0] != 'srv-compose' for c in self.calls()))

    def test_signed_url_is_one_remote_argument_and_not_logged(self):
        url = "https://example.test/a.zip?sig=FAKE;'$(touch /tmp/not-executed)'&x=1"
        result = self.run_cli('--dl', url, theme=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        command = self.calls()[-1]['command']
        self.assertEqual(command, ['srv-music-workbench', 'acquire', url])
        self.assertNotIn(url, result.stdout + result.stderr)
        self.assertNotIn('publish', self.actions())
        self.assertNotIn('import', self.actions())

    def test_local_tar_preserves_basename_contents_and_originals(self):
        import base64
        source = self.root / "release ' quoted"
        source.mkdir()
        (source / 'track.flac').write_bytes(b'audio')
        os.link(source / 'track.flac', source / 'second.flac')
        result = self.run_cli('--dl', str(source), theme=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        event = self.calls()[-1]
        self.assertEqual(event['command'][:3], ['srv-music-workbench', 'receive', '--name'])
        self.assertRegex(event['command'][3], r'^angel-[a-f0-9]{32}$')
        self.assertIn('-T', event['options'])
        with tarfile.open(fileobj=io.BytesIO(base64.b64decode(event['input']))) as archive:
            self.assertEqual(archive.getnames(), [source.name, source.name + '/second.flac', source.name + '/track.flac'])
            self.assertTrue(all(m.isdir() or m.isfile() for m in archive.getmembers()))
            self.assertEqual(archive.extractfile(source.name + '/track.flac').read(), b'audio')
        self.assertEqual((source / 'track.flac').read_bytes(), b'audio')
        self.assertEqual(self.actions(), ['version', 'check', 'receive'])

    def test_links_and_special_files_never_reach_receive(self):
        source = self.root / 'release'
        source.mkdir()
        (source / 'link').symlink_to(self.theme)
        for path in (source, source / 'link'):
            result = self.run_cli('--dl', str(path))
            self.assertNotEqual(result.returncode, 0)
        (source / 'link').unlink()
        os.mkfifo(source / 'fifo')
        self.assertNotEqual(self.run_cli('--dl', str(source)).returncode, 0)
        self.assertNotIn('receive', self.actions())

    def test_extraction_is_remote_and_import_is_a_separate_tty(self):
        path = "/workspace/staging/a ' ; $(ignored).zip"
        self.assertEqual(self.run_cli('--extract', path).returncode, 0)
        self.assertEqual(self.calls()[-1]['command'], ['srv-music-workbench', 'extract', path])
        self.assertNotIn('import', self.actions())
        self.assertNotEqual(self.run_cli('--import', '/workspace/staging/job/content').returncode, 0)
        self.assertEqual(self.run_cli('--import', '/workspace/staging/job/content', tty=True).returncode, 0)
        self.assertIn('-t', self.calls()[-1]['options'])

    def test_review_and_status_redact_provenance_not_readiness(self):
        result = self.run_cli('--review', '3', theme=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads(result.stdout)
        self.assertFalse(report['ready'])
        self.assertTrue(report['warnings'])
        self.assertTrue(report['blockers'])
        self.assertNotIn('DO-NOT-PRINT', result.stdout)
        self.assertNotIn('private basis', result.stdout)
        self.assertNotIn('publish', self.actions())

    def test_publication_requires_explicit_album_basis_and_attribution(self):
        for args in (('--publish', '3'), ('--publish', '3', '--yes'), ('--status', '--yes'), ('--publish', '3 4', '--yes')):
            self.assertNotEqual(self.run_cli(*args).returncode, 0)
        self.assertNotIn('publish', self.actions())
        basis = "permission ' & $(ignored)"
        result = self.run_cli('--publish', '3', '--basis', basis, '--attribution', 'Public text', '--yes', '--replace', 'pub-old')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls()[-1]['command'], ['srv-music-workbench', 'publish', '3', '--basis=' + basis, '--attribution=Public text', '--replace=pub-old', '--yes'])
        self.assertNotIn(basis, result.stdout + result.stderr)
        self.assertIn('-T', self.calls()[-1]['options'])

    def test_interactive_publication_keeps_backend_confirmation(self):
        result = self.run_cli('--publish', '3', '--basis', 'music and artwork permission', '--attribution', 'Public', tty=True)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('-t', self.calls()[-1]['options'])
        self.assertNotIn('--yes', self.calls()[-1]['command'])

    def test_recovery_works_without_editor_but_resume_needs_readiness(self):
        for action in ('status', 'unpublish', 'purge'):
            self.log.unlink(missing_ok=True)
            args = ['--' + action] + ([] if action == 'status' else ['pub-one'])
            self.assertEqual(self.run_cli(*args, mode='stale').returncode, 0)
            self.assertEqual(self.actions(), ['version', action])
        self.log.unlink()
        self.assertNotEqual(self.run_cli('--resume', 'pub-one', mode='stale').returncode, 0)
        self.assertNotIn('resume', self.actions())

    def test_unsafe_urls_paths_and_empty_inputs_fail(self):
        for args in (('--dl', 'http://example.test/a'), ('--dl', 'https://u:secret@example.test/a'),
                     ('--dl', ''), ('--extract', '/workspace/staging/../library'), ('--import', '/tmp/music')):
            self.assertNotEqual(self.run_cli(*args).returncode, 0)
        self.assertNotIn('acquire', self.actions())
        self.assertNotIn('receive', self.actions())
        self.assertNotIn('extract', self.actions())

    def test_bad_backend_path_and_failure_do_not_echo_private_values(self):
        for mode in ('bad-path', 'failure'):
            result = self.run_cli('--dl', 'https://invalid.test/?signature=DO-NOT-PRINT', mode=mode)
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn('DO-NOT-PRINT', result.stdout + result.stderr)

    def test_other_backend_operations_and_named_download(self):
        for args, expected in ((('--albums',), ['albums', '--json']),
                               (('--cache-clean',), ['cache-clean']),
                               (('--check',), ['check']),
                               (('--resume', 'pub-one'), ['resume', 'pub-one']),
                               (('--dl', 'https://example.test/a', '--name', "name ' quoted"),
                                ['acquire', 'https://example.test/a', "--name=name ' quoted"])):
            self.assertEqual(self.run_cli(*args, theme=False).returncode, 0)
            self.assertEqual(self.calls()[-1]['command'][1:], expected)

    def test_no_shell_upload_without_terminal_or_theme(self):
        self.assertNotEqual(self.run_cli().returncode, 0)
        self.assertNotEqual(self.run_cli(tty=True, theme=False).returncode, 0)
        self.assertTrue(all(call['command'][0] != 'srv-compose' for call in self.calls()))

    def test_relative_colon_filename_is_local(self):
        source = self.root / 'artist: album.flac'
        source.write_bytes(b'audio')
        original = os.getcwd()
        try:
            os.chdir(self.root)
            result = self.run_cli('--dl', source.name)
        finally:
            os.chdir(original)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.actions(), ['version', 'check', 'receive'])

    def test_option_like_publication_text_is_not_an_option(self):
        result = self.run_cli('--publish', '3', '--basis=--licensed', '--attribution=--public', '--yes')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('--basis=--licensed', self.calls()[-1]['command'])
        self.assertIn('--attribution=--public', self.calls()[-1]['command'])

    def test_interactive_auth_uses_private_socket_before_batch_upload(self):
        self.assertEqual(self.run_cli(tty=True).returncode, 0)
        check, upload, shell = self.calls()[0], self.calls()[2], self.calls()[3]
        self.assertIn('BatchMode=no', check['options'])
        self.assertIn('BatchMode=yes', upload['options'])
        sockets = [call['options'][call['options'].index('-S') + 1] for call in (check, upload, shell)]
        self.assertEqual(len(set(sockets)), 1)
        self.assertFalse(Path(sockets[0]).parent.exists())

    def test_invalid_cli_does_not_echo_unknown_private_argument(self):
        result = self.run_cli('--unknown=https://invalid.test/?signature=DO-NOT-PRINT')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('DO-NOT-PRINT', result.stdout + result.stderr)
        self.assertEqual(self.actions(), [])


class PublicationPrompt(unittest.TestCase):
    def test_missing_text_is_collected_without_printing_private_basis(self):
        args = client.parser().parse_args(['--publish', '7'])
        with patch.object(sys.stdin, 'isatty', return_value=True), \
             patch.object(sys.stdout, 'isatty', return_value=True), \
             patch.object(client.getpass, 'getpass', return_value='private permission') as hidden, \
             patch('builtins.input', return_value='PUBLIC attribution') as public, \
             patch.object(client, 'backend') as backend:
            client.operate(args, 'publish')
        hidden.assert_called_once()
        public.assert_called_once()
        backend.assert_called_once_with('publish', '7', '--basis=private permission',
                                        '--attribution=PUBLIC attribution', tty=True)


class Archive(unittest.TestCase):
    def test_limits_fail_before_a_transfer_can_start(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'data'
            path.write_bytes(b'123')
            for limits in ({'MAX_FILES': 0}, {'MAX_BYTES': 2}):
                with patch.multiple(client, **limits), tempfile.TemporaryFile() as stream:
                    with self.assertRaises(client.Failure):
                        client.archive_input(str(path), stream)


if __name__ == '__main__':
    unittest.main()
