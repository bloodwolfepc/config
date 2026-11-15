import os
from pathlib import Path
import subprocess
import shutil
import sys
import tempfile
import unittest


SCRIPT = Path(sys.argv.pop(1)).resolve()
LIBVIRT = "sh -c 'which virt-ssh-helper 1>/dev/null 2>&1; if test $? = 0; then     virt-ssh-helper 'qemu:///system'; else    if 'nc' -q 2>&1 | grep \"requires an argument\" >/dev/null 2>&1; then ARG=-q0;else ARG=;fi;'nc' $ARG -U /var/run/libvirt/libvirt-sock; fi'"
LIBVIRT_RO = LIBVIRT.replace("virt-ssh-helper 'qemu", "virt-ssh-helper -r 'qemu").replace("libvirt-sock;", "libvirt-sock-ro;")
PROVIDER = 'sh -c \'virt-ssh-helper "qemu:///system"\''
GUARD = 'findmnt -rn --mountpoint /srv/libvirt >/dev/null && test -f /srv/libvirt/.srv-storage && test -d /data/garage && test -f /data/garage/.srv-storage'


class ForcedCommandTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for name, body in {
            'virt-ssh-helper': 'printf "<%s>\\n" "$@"',
            'findmnt': 'exit 19',
        }.items():
            mock = self.root / name
            mock.write_text('#!' + shutil.which('bash') + '\n' + body + '\n')
            mock.chmod(0o700)

    def run_command(self, command):
        return subprocess.run(
            ['bash', str(SCRIPT)], text=True, capture_output=True,
            env={**os.environ, 'PATH': str(self.root) + ':' + os.environ['PATH'],
                 'SSH_ORIGINAL_COMMAND': command},
        )

    def test_observed_rpc_commands(self):
        for command, expected in ((LIBVIRT, '<qemu:///system>\n'),
                                  (LIBVIRT_RO, '<-r>\n<qemu:///system>\n'),
                                  (PROVIDER, '<qemu:///system>\n')):
            with self.subTest(command=command):
                result = self.run_command(command)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, expected)

    def test_storage_guard_propagates_mount_failure(self):
        self.assertEqual(self.run_command(GUARD).returncode, 19)

    def test_everything_else_is_denied(self):
        for command in (
            '', 'bash', 'id', 'internal-sftp', 'scp -t /tmp', 'virt-ssh-helper qemu:///system',
            PROVIDER + '; id', PROVIDER + '\n', PROVIDER.replace('/system', '/session'),
            LIBVIRT.replace('/system', '/session'), LIBVIRT.replace('then     ', 'then '),
            GUARD + ' && id', GUARD.replace('&&', ';'), '$(id)', '`id`',
        ):
            with self.subTest(command=command):
                result = self.run_command(command)
                self.assertEqual(result.returncode, 126)
                self.assertEqual(result.stdout, '')
                self.assertIn('Denied:', result.stderr)


unittest.main()
