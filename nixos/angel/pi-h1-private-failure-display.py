"""One separately consented escaped /dev/tty disclosure; metadata only on stdout."""
import fcntl
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import stat
import sys

PACKET = Path('/tmp/pi-h1-private-terminal-disclosure-20261125-v1')
INSPECTOR = '/nix/store/clal6rd7cvyxvnps07aj2p1f956g0z60-pi-h1-private-failure-inspector/inspect.py'
INSPECTOR_SHA = '4f5e2df6437ecd8c6fd1d8832afef5ee5d98a4aa66cf5f267aab5e312b51f252'
INSPECTOR_MANIFEST = '35cbee8207e3a1a7373427469200d240d9f03e3144ee0f4681d3013c5a0af2f6'
PRIOR_DONE_SHA = '71ce95b52eb3d67361812991ff1397970710ce014c3419047af1eaeb8d65a0dd'
PREFIX = 'failure-local-disclosure-0001.'
VERSION = 'h1-private-terminal-disclosure/v1'


def require(ok, reason):
    if not ok:
        raise RuntimeError(reason)


def sha(body):
    return hashlib.sha256(body).hexdigest()


def escaped(body):
    require(type(body) is bytes and len(body) == 120, 'exact-display-bound')
    text = json.dumps(body.decode('utf-8', errors='backslashreplace'), ensure_ascii=True)
    require(text.isascii() and not any(ord(ch) < 32 for ch in text) and len(text) <= 1442, 'escaped-display-bound')
    return text


def terminal_display(body):
    # Not stdout/stderr: those may be redirected to the private metadata export.
    fd = os.open('/dev/tty', os.O_WRONLY | os.O_NOCTTY)
    try:
        s = os.fstat(fd)
        require(stat.S_ISCHR(s.st_mode) and os.isatty(fd), 'actual-controlling-terminal-required')
        text = 'PRIVATE TERMINAL ONLY. Review locally; do not paste credentials or personal data.\n' + escaped(body) + '\nEND PRIVATE DISPLAY. Only nonsecret diagnostic text may be shared deliberately.\n'
        data = text.encode('ascii')
        while data:
            written = os.write(fd, data);require(written > 0, 'terminal-write-incomplete');data = data[written:]
    finally:
        os.close(fd)


def bindings(a, p):
    p.private_directory(p.ROOT, 0);p.private_directory(p.PROBE, 987, 977)
    for path, uid, maximum, expected in [
        (p.ROOT/'owner.json',0,4096,p.OWNER_SHA),
        (p.PROBE/'continuation-0001.HELD.json',987,65536,p.HELD_SHA),
        (p.ROOT/'failure-inspection-0001.done.json',0,65536,PRIOR_DONE_SHA)]:
        require(sha(a.file_bytes(path,uid,maximum,True)) == expected, 'completed-evidence-drift')
    p.host(a);p.failed_file(p.FAILURE,120)


def disclose(a, c, p, manifest, display=terminal_display):
    bindings(a,p)
    require(not any(os.path.lexists(p.ROOT/(PREFIX+suffix)) for suffix in
                    ['attempt.json','done.json','HELD.json']), 'local-disclosure-already-consumed')
    record = {'version':VERSION,'reviewManifestSha256':manifest,'displayerSha256':sha(Path(__file__).read_bytes()),
              'priorInspectionDoneSha256':PRIOR_DONE_SHA,'failureSha256':p.FAILURE_SHA,'failureBytes':120,
              'authority':'one-terminal-only-escaped-disclosure','rawChatOrDiskExportAuthorized':False,
              'runtimeAuthority':False,'retry':False,'qualification':'not-granted'}
    c.write(p.ROOT/(PREFIX+'attempt.json'),record)
    try:
        p.failed_file(p.FAILURE,120)
        body = a.file_bytes(p.FAILURE,987,120,True)
        require(len(body) == 120 and sha(body) == p.FAILURE_SHA, 'fixed-content-hash-drift')
        display(body)
        bindings(a,p)
        result = {'version':VERSION,'status':'terminal-display-completed','bytes':120,'sha256':p.FAILURE_SHA,
                  'terminalEscaped':True,'rawSavedOrSentToAgent':False,'runtimeChanged':False,
                  'qualification':'not-granted'}
        c.write(p.ROOT/(PREFIX+'done.json'),record|{'result':result})
        return result
    except BaseException:
        c.write(p.ROOT/(PREFIX+'HELD.json'),record|{'status':'disclosure-held','displayMayBePartial':True})
        raise RuntimeError('local-disclosure-held-no-retry') from None


def load(manifest):
    require(os.geteuid() == 0 and os.environ.get('SUDO_UID') == '1000' and sys.stdin.isatty(), 'human-sudo-terminal-required')
    require(re.fullmatch('[a-f0-9]{64}',manifest), 'manifest-format')
    here = Path(__file__);s = here.lstat()
    require(str(here).startswith('/nix/store/') and here.resolve() == here and stat.S_ISREG(s.st_mode)
            and s.st_uid == 0 and not s.st_mode & 0o222, 'immutable-displayer-required')
    path = Path(INSPECTOR);s = path.lstat()
    require(path.resolve() == path and stat.S_ISREG(s.st_mode) and s.st_uid == 0
            and not s.st_mode & 0o222 and s.st_size <= 262144 and sha(path.read_bytes()) == INSPECTOR_SHA, 'immutable-inspector-binding')
    spec = importlib.util.spec_from_file_location('pure_previous_inspection_guards',path)
    p = importlib.util.module_from_spec(spec);spec.loader.exec_module(p)
    a,c = p.load(INSPECTOR_MANIFEST)  # Verifiers only; NEVER main/inspect/classify.
    bodies = a.checked_packet(PACKET,manifest,1000,262144,1048576)
    require(sha(bodies['display.py']) == sha(here.read_bytes()), 'reviewed-displayer-binding')
    return a,c,p


def main():
    os.umask(0o077)
    require(len(sys.argv) == 2, 'exact-manifest-required')
    manifest = sys.argv[1];a,c,p = load(manifest)
    print('Exact private failure:120bytes; SHA256 '+p.FAILURE_SHA, file=sys.stderr)
    print('Approve: Display ONLY this hash-bound failure once as escaped text directly on your controlling terminal. Do not save or send the text to Pi/chat; review locally and share only any nonsecret diagnostic you deliberately choose. Append metadata-only disclosure checkpoints in the existing observer directory; no probe/classifier replay, grant, unit action, repair, release or H1 qualification.\n\n<y/N> ',end='',flush=True,file=sys.stderr)
    if sys.stdin.readline().rstrip('\r\n') not in {'y','Y'}:
        return 3
    a.checked_packet(PACKET,manifest,1000,262144,1048576)
    p.private_directory(p.ROOT,0)
    fd = os.open(p.ROOT/'owner.json',os.O_RDONLY|os.O_NOFOLLOW|os.O_NONBLOCK)
    try:
        s = os.fstat(fd)
        require(stat.S_ISREG(s.st_mode) and s.st_uid == 0 and s.st_nlink == 1
                and stat.S_IMODE(s.st_mode) == 0o400, 'original-observer-lock-binding')
        fcntl.flock(fd,fcntl.LOCK_EX|fcntl.LOCK_NB)
        result = disclose(a,c,p,manifest)
    finally:
        os.close(fd)
    print(json.dumps(result,sort_keys=True))
    return 0


if __name__ == '__main__':
    try:
        code = main()
    except BaseException:
        print('Private local disclosure refused/held; preserve checkpoints, no retry or runtime authority.',file=sys.stderr)
        code = 1
    sys.exit(code)
