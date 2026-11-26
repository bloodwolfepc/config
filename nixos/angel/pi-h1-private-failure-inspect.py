"""One human-approved closed-label inspection; no raw export or runtime authority."""
import fcntl
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import stat
import sys

PACKET = Path('/tmp/pi-h1-private-failure-inspection-20261125-v1')
ROOT = Path('/persist/pi-h1-continuation-controller-20261125-v1')
PROBE = Path('/var/lib/pi-coordinator/h1-probe')
FAILURE = PROBE / 'continuation-0001.failure.bin'
CONTROLLER = '/nix/store/h0dssalbyk8mnqwadwwhrxpzfys41v2q-pi-h1-continuation-controller/controller.py'
CONTROLLER_SHA = '1ea06eb3689bcec05549c67185821e0261a3686cb3c6e9d2795429d83a30cde3'
OWNER_SHA = 'a1fa5e3cfe756ba1a2b9e70aea217f74a0738d19a5efaaffa70e055802c994b6'
HELD_SHA = 'a526fe66bfee7fd310d90de9decb4412d74966c470a45668c8fdd106fdda1bc1'
FAILURE_SHA = '57ddeac2030715f9ce836f84e0be5c234b7e99f3062174f6c15da19b1b6075d0'
TARGET = '/nix/store/biypbkhv2yjfq4qjzn4jfrz18c9aja7q-nixos-system-angel-26.11.20260923.4975466'
BOOT = '5f53e8ed-e7c7-426e-bb83-99ba93f5ea95'
INVOCATION = 'ccbe9e8c7db6448099bc3b33d7936b51'
UNIT_SHA = '01a391626438bb4818be9fdc23421f565ea7f295d316cde5b77e7c80f1a82e39'
SYSTEMCTL = '/nix/store/baxgs06659w4i6ggsfr56srjrb52v1h8-systemd-261.2/bin/systemctl'
PREFIX = 'failure-inspection-0001.'
VERSION = 'h1-private-failure-inspection/v1'
# Public immutable Bubblewrap message templates, NOT guesses reconstructed from a hash.
STAGES = {
    b'Creating new namespace failed': 'namespace-create',
    b'setting up uid map': 'uid-map-setup',
    b'setting up gid map': 'gid-map-setup',
    b'unshare pid ns': 'pid-namespace-unshare',
    b'unshare user ns': 'user-namespace-unshare',
    b'Failed to make / slave': 'root-mount-propagation',
    b'Joining specified user namespace failed': 'user-namespace-join',
}
ERRORS = {b'Operation not permitted': 'EPERM', b'Permission denied': 'EACCES',
          b'No such file or directory': 'ENOENT', b'Invalid argument': 'EINVAL'}
GENERIC = b'Tool boundary refused or outcome unknown; preserve ownership.'


def require(ok, reason):
    if not ok:
        raise RuntimeError(reason)


def sha(body):
    return hashlib.sha256(body).hexdigest()


def classify(body):
    """No input fragments, variable paths or exception text ever leave this function."""
    require(type(body) is bytes and len(body) <= 120, 'classification-bound')
    known = {b'bwrap: ' + stage + b': ' + error: {'stage': label, 'reportedErrno': code}
             for stage, label in STAGES.items() for error, code in ERRORS.items()}
    matches = [];unknown = 0;helper = False
    for line in body.splitlines():
        if line == GENERIC:
            helper = True
        elif line in known:
            if known[line] not in matches:
                matches.append(known[line])
        else:
            unknown += 1
    return {'version': VERSION, 'status': 'known-message-observed' if matches else 'no-known-message',
            'messageClasses': matches, 'genericHelperHeldSeen': helper, 'unknownLineCount': unknown,
            'bytes': len(body), 'sha256': sha(body), 'untrustedMessages': True,
            'deniedSyscallAndPolicyNotProven': True, 'rawContentExported': False,
            'runtimeChanged': False, 'qualification': 'not-granted'}


def private_directory(path, uid, gid=None):
    s = path.lstat()
    require(path.resolve() == path and stat.S_ISDIR(s.st_mode) and s.st_uid == uid
            and stat.S_IMODE(s.st_mode) == 0o700 and (gid is None or s.st_gid == gid), 'private-directory-binding')


def failed_file(path, expected_bytes):
    s = path.lstat()
    require(stat.S_ISREG(s.st_mode) and s.st_uid == 987 and s.st_gid == 977 and s.st_nlink == 1
            and stat.S_IMODE(s.st_mode) == 0o400 and s.st_size == expected_bytes and s.st_dev == 1792,
            'fixed-failure-metadata')


def host(a):
    require(str(Path('/run/current-system').resolve()) == TARGET
            and Path('/proc/sys/kernel/random/boot_id').read_text().strip() == BOOT, 'host-drift')
    require(sha((Path(TARGET) / 'etc/systemd/system/pi-coordinator.service').read_bytes()) == UNIT_SHA, 'unit-file-drift')
    p = a.properties()
    require(p['ActiveState'] == p['SubState'] == 'failed' and p['MainPID'] == '0'
            and not p['ControlGroup'] and p['Job'] in {'', '0'} and p['InvocationID'] == INVOCATION
            and p['ExecMainStatus'] == '1' and p['ExecMainCode'] == '1' and p['NRestarts'] == '0'
            and not any(p[k] for k in ['DropInPaths','WantedBy','TriggeredBy']), 'held-unit-drift')
    require(not Path('/sys/fs/cgroup/system.slice/pi-coordinator.service').exists(), 'cgroup-present')
    count = 0
    for entry in Path('/proc').iterdir():
        if not entry.name.isdigit():
            continue
        count += 1;require(count <= 16384, 'process-bound')
        try:
            require(entry.stat().st_uid != 987, 'dedicated-process-live')
        except FileNotFoundError:
            pass
    return p


def inspect(a, c, manifest):
    private_directory(ROOT, 0);private_directory(PROBE, 987, 977)
    owner = a.file_bytes(ROOT / 'owner.json', 0, 4096, True)
    require(sha(owner) == OWNER_SHA, 'original-observer-owner-drift')
    held = a.file_bytes(PROBE / 'continuation-0001.HELD.json', 987, 65536, True)
    require(sha(held) == HELD_SHA, 'consumed-continuation-drift')
    f = json.loads(held)['privateFailure']
    require(f['bytes'] == 120 and f['sha256'] == FAILURE_SHA and f['case'] == 'startup-marker'
            and f['complete'] is True, 'retained-failure-binding')
    host(a);failed_file(FAILURE, 120)
    require(not any(os.path.lexists(ROOT / (PREFIX + suffix)) for suffix in
                    ['attempt.json','done.json','HELD.json']), 'inspection-already-consumed')
    value = {'version': VERSION, 'reviewManifestSha256': manifest, 'inspectorSha256': sha(Path(__file__).read_bytes()),
             'ownerSha256': OWNER_SHA, 'heldSha256': HELD_SHA, 'failureSha256': FAILURE_SHA,
             'failureBytes': 120, 'authority': 'one-closed-label-content-inspection-only',
             'rawExportAuthorized': False, 'runtimeAuthority': False, 'retry': False, 'qualification': 'not-granted'}
    c.write(ROOT / (PREFIX + 'attempt.json'), value)  # Before opening any failure content.
    try:
        failed_file(FAILURE, 120)
        body = a.file_bytes(FAILURE, 987, 120, True)
        require(len(body) == 120 and sha(body) == FAILURE_SHA, 'retained-content-hash-drift')
        result = classify(body)
        host(a)
        require(sha(a.file_bytes(PROBE / 'continuation-0001.HELD.json', 987, 65536, True)) == HELD_SHA
                and sha(a.file_bytes(ROOT / 'owner.json', 0, 4096, True)) == OWNER_SHA, 'post-inspection-drift')
        c.write(ROOT / (PREFIX + 'done.json'), value | {'diagnostic': result})
        return result
    except BaseException:
        c.write(ROOT / (PREFIX + 'HELD.json'), value | {'status': 'inspection-held', 'rawContentExported': False})
        raise RuntimeError('inspection-held-preserve-checkpoints') from None


def load(manifest):
    require(os.geteuid() == 0 and os.environ.get('SUDO_UID') == '1000' and sys.stdin.isatty(), 'human-sudo-terminal-required')
    require(re.fullmatch('[a-f0-9]{64}', manifest), 'manifest-format')
    here = Path(__file__);s = here.lstat()
    require(str(here).startswith('/nix/store/') and here.resolve() == here and stat.S_ISREG(s.st_mode)
            and s.st_uid == 0 and not s.st_mode & 0o222, 'immutable-inspector-required')
    p = Path(CONTROLLER);s = p.lstat()
    require(p.resolve() == p and stat.S_ISREG(s.st_mode) and s.st_uid == 0 and not s.st_mode & 0o222
            and s.st_size <= 262144 and sha(p.read_bytes()) == CONTROLLER_SHA, 'controller-library-binding')
    spec = importlib.util.spec_from_file_location('only_pure_controller_utilities', p)
    c = importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
    a = c.module(c.BASE, c.BASE_SHA, 'only_bounded_file_and_metadata_reader')
    # No load/main/audit/activation/controller dispatch functions are called.
    a.M = {'systemctl': SYSTEMCTL, 'invocations': {'pi-coordinator.service': INVOCATION}}
    bodies = a.checked_packet(PACKET, manifest, 1000, 262144, 1048576)
    require(sha(bodies['inspect.py']) == sha(here.read_bytes()), 'reviewed-inspector-binding')
    return a, c


def main():
    os.umask(0o077)
    require(len(sys.argv) == 2, 'exact-manifest-required')
    manifest = sys.argv[1];a,c = load(manifest)
    print('Failure SHA256: ' + FAILURE_SHA + '\nExact size: 120bytes; invocation: ' + INVOCATION, file=sys.stderr)
    print('Approve: Inspect ONLY this hash-bound private failure content once and export fixed diagnostic labels, byte count and digest. Append inspection evidence to the existing observer directory; never export raw text, change runtime, retry/start/stop/reset the unit, issue a grant, release holds or qualify H1. Unknown input stays undisclosed.\n\n<y/N> ', end='', flush=True, file=sys.stderr)
    if sys.stdin.readline().rstrip('\r\n') not in {'y','Y'}:
        return 3
    a.checked_packet(PACKET, manifest, 1000, 262144, 1048576)
    private_directory(ROOT, 0)
    fd = os.open(ROOT / 'owner.json', os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        s = os.fstat(fd)
        require(stat.S_ISREG(s.st_mode) and s.st_uid == 0 and s.st_nlink == 1
                and stat.S_IMODE(s.st_mode) == 0o400, 'unsafe-inspection-lock')
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        result = inspect(a,c,manifest)
    finally:
        os.close(fd)
    print(json.dumps(result,sort_keys=True))
    return 0


if __name__ == '__main__':
    try:
        code = main()
    except BaseException:
        print('Private inspection refused/held. Preserve all files; no retry or runtime authority.', file=sys.stderr)
        code = 1
    sys.exit(code)
