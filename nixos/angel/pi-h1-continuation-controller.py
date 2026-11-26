"""Human-only, append-only controller for the retained synthetic H1 continuation.

Not a model admission, owner release, ResetFailed or H1 qualification interface.
The packet/wrapper is a separate reviewed human handoff; no implicit approvals.
"""
import fcntl
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import signal
import stat
import sys
import time

PACKET = Path('/tmp/pi-h1-continuation-controller-20261125-v1')
ROOT = Path('/persist/pi-h1-continuation-controller-20261125-v1')
BASE = '/nix/store/jvlj079ndz39cgmgrszvpbkl695zdjkv-helper.py'
BASE_SHA = '22bcc2e74c95b4712f677346f9fb62fa1d4d04fecdefc7b7a3ba528085c4e457'
BASE_MANIFEST = '9f5572bef4da5fd61f00a04813fdbe3385f9f658f433194bd31f8221f5a181b3'
HARNESS = '/nix/store/dhlyjlfmjjvakp912alwrjn2583kdw07-pi-coordinator-h1.py'
SETTINGS = '/nix/store/rv3vjqb2zpwpcgcjvma3g74dz8z20a5l-pi-h1-settings.json'
STATE = Path('/var/lib/pi-coordinator')
WORK = Path('/var/lib/pi-tool-workspaces/slot-1')
PROBE = STATE / 'h1-probe'
GRANT = PROBE / 'continuation-0001.grant.json'
UNIT = 'pi-coordinator.service'
GROUP = Path('/sys/fs/cgroup/system.slice/pi-coordinator.service')
VERSION = 'human-h1-continuation-controller/v1'
PHASES = ['audit', 'reconcile', 'capture', 'grant', 'start']
CASES = ['startup-marker', 'write', 'read', 'edit', 'bash', 'state-credential-denial',
         'excluded-store-denial', 'sterile-environment', 'namespace-identities',
         'inherited-fd-denial', 'inventory-no-authority', 'existing-owner-refusal', 'unsealed-report']
OLD_NAMES = {'owner.json', 'HELD.json', 'credential-marker.json'}
ENV = {'LANG': 'C', 'LC_ALL': 'C', 'HOME': '/root', 'PATH': '/run/current-system/sw/bin'}


def require(ok, reason):
    if not ok:
        raise RuntimeError(reason)


def sha(body):
    return hashlib.sha256(body).hexdigest()


def encoded(value):
    return json.dumps(value, sort_keys=True).encode() + b'\n'


def module(path, expected, name):
    p = Path(path);s = p.lstat()
    require(str(p).startswith('/nix/store/') and p.resolve() == p and stat.S_ISREG(s.st_mode)
            and s.st_uid == 0 and not s.st_mode & 0o222 and s.st_size <= 262144
            and sha(p.read_bytes()) == expected, 'immutable-library-binding')
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec);spec.loader.exec_module(result)
    return result


def write(path, value, gid=None):
    body = encoded(value)
    require(len(body) <= 5 * 1024 * 1024, 'receipt-bound')
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    try:
        if gid is not None:
            os.fchown(fd, 0, gid)
        with os.fdopen(fd, 'wb', closefd=False) as stream:
            stream.write(body);stream.flush()
        os.fchmod(fd, 0o440 if gid is not None else 0o400);os.fsync(fd)
    finally:
        os.close(fd)
    fd = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def root_runtime(settings, harness=HARNESS):
    """Same bytes as the UID987 consumer binding, without its non-root UID guard."""
    def immutable_bytes(value):
        p = Path(value);s = p.lstat()
        require(str(p).startswith('/nix/store/') and p.resolve() == p and stat.S_ISREG(s.st_mode)
                and s.st_uid == 0 and not s.st_mode & 0o222 and s.st_size <= 16 * 1024 * 1024, 'root-runtime-input')
        fd = os.open(p, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        try:
            before = os.fstat(fd);body = bytearray()
            while len(body) <= 16 * 1024 * 1024:
                block = os.read(fd, min(16384, 16 * 1024 * 1024 + 1 - len(body)))
                if not block:
                    break
                body.extend(block)
            after = os.fstat(fd)
            require((s.st_dev,s.st_ino,s.st_size,s.st_mtime_ns,s.st_ctime_ns) ==
                    (before.st_dev,before.st_ino,before.st_size,before.st_mtime_ns,before.st_ctime_ns) ==
                    (after.st_dev,after.st_ino,after.st_size,after.st_mtime_ns,after.st_ctime_ns)
                    and len(body) == s.st_size, 'root-runtime-race')
            return bytes(body)
        finally:
            os.close(fd)
    return {'harnessSha256': sha(immutable_bytes(harness)),
            'settingsSha256': sha(json.dumps(settings, sort_keys=True).encode()),
            'files': {key: {'path': settings[key], 'sha256': sha(immutable_bytes(settings[key]))}
                      for key in ['helper','launcher','launch','workerSource','python','storeCanary','policy','continuation']}}


class Controller:
    def __init__(self, base, harness, metadata, metadata_sha, review_sha):
        self.a, self.h, self.m, self.metadata_sha = base, harness, metadata, metadata_sha
        self.review_sha = review_sha
        self.settings = json.loads(Path(SETTINGS).read_bytes())
        self.descriptor = json.loads(Path(self.settings['continuation']).read_bytes())

    def record(self, name):
        return self.a.read_record(ROOT / name, maximum=5 * 1024 * 1024)

    def owner(self):
        return {'version': VERSION, 'metadataSha256': self.metadata_sha,
                'controllerSha256': sha(Path(__file__).read_bytes()), 'reviewManifestSha256': self.review_sha,
                'scope': 'retained-continuation-0001-only', 'retry': False,
                'ownerReleaseAuthorized': False, 'qualification': 'not-granted'}

    def activation(self):
        """Re-read both old activation evidence domains, not just operator exports."""
        a = self.a
        previous = a.prior_activation()
        a.owned()
        root = a.STATE;a.h.safe_ancestors(root);a.h.private_root(root)
        require(a.entry_names(root, 8) == set(self.m['activationRecords']), 'activation-record-set')
        total = 0
        for name, expected in self.m['activationRecords'].items():
            record = self.a.read_record(root / name, maximum=262144)
            total += len(encoded(record['data']));require(total <= 1048576, 'activation-read-bound')
            require(record['sha256'] == expected, 'activation-record-drift')
        a.roots()  # Read-only validation of existing activation GC roots; never create.
        return {'current': dict(self.m['activationRecords']), 'previous': previous}

    def runtime(self):
        require(root_runtime(self.settings) == self.m['runtime'], 'runtime-drift')
        require(self.settings['state'] == str(STATE) and self.settings['workspace'] == str(WORK)
                and self.settings['taskId'] == 'h1_fixture_20261124', 'original-roots-required')
        require(sha(Path(self.settings['continuation']).read_bytes()) == self.m['descriptorSha256'], 'descriptor-drift')
        require(self.descriptor['stateUUID'] == self.a.inputs['mounts']['state']['uuid']
                and self.descriptor['workspaceUUID'] == self.a.inputs['mounts']['slot']['uuid'], 'descriptor-physical-uuid-drift')

    def original(self, after=False):
        """Original receipts stay immutable; journal owner creation is the one declared exception."""
        a = self.a;reader = a.reader_module.Reader()
        records = a.reader_module.private_records(reader, a.inputs)
        saved = a.retained['records']
        for key, value in saved.items():
            if after and key == 'synthetic-journal/owner.json':
                continue
            require(records[key] == value, 'original-receipt-drift')
        if after and records['synthetic-journal/owner.json']['available']:
            body = json.loads(self.h.read_record(STATE / 'journal/owner.json', 987, 0o400, 977))
            require(body == {'version': self.h.VERSION, 'synthetic': True, 'reconciliation': 'human'}, 'journal-owner-drift')
        mounts = a.reader_module.mounts_and_workspace(reader, a.inputs)
        for alias in ['state', 'slot']:
            require(mounts[alias] == a.retained['mountsWorkspace'][alias], 'physical-storage-drift')
        for name, expected in a.M['diagnosticRecordHashes'].items():
            body, _ = reader.data(Path('/persist/pi-h1-repair-activation-20261124-v1') / name)
            require(sha(body) == expected, 'consumed-diagnostic-drift')
        return {'records': records, 'mounts': mounts}

    def idle(self, after=False):
        a = self.a
        require(Path('/proc/sys/kernel/random/boot_id').read_text().strip() == a.M['bootId'], 'boot-drift')
        for path, key in [('/run/current-system', 'target'), ('/run/booted-system', 'booted'),
                          ('/nix/var/nix/profiles/system', 'default')]:
            require(str(Path(path).resolve()) == a.M[key], 'generation-drift')
        require(sha((Path(a.M['target']) / 'etc/systemd/system' / UNIT).read_bytes()) == a.M['targetUnitSha256'], 'unit-file-drift')
        unit = a.properties()
        require(unit['LoadState'] == 'loaded' and unit['ActiveState'] in {'inactive', 'failed'}
                and unit['SubState'] in {'dead', 'failed'} and unit['MainPID'] == '0'
                and not unit['ControlGroup'] and unit['Job'] in {'', '0'} and unit['NRestarts'] == '0'
                and not any(unit[k] for k in ['DropInPaths', 'WantedBy', 'TriggeredBy'])
                and unit['ProcSubset'] == 'all' and unit['ProtectProc'] == 'invisible'
                and unit['RuntimeMaxUSec'] == '4min', 'unit-not-quiescent')
        require(str(Path(unit['FragmentPath']).resolve()) == str((Path(a.M['target']) / 'etc/systemd/system' / UNIT).resolve()), 'loaded-unit-drift')
        if not after:
            a.inert(unit, False)
        require(not GROUP.exists(), 'fixed-cgroup-remains')
        count = 0
        for p in Path('/proc').iterdir():
            if not p.name.isdigit():
                continue
            count += 1;require(count <= 16384, 'process-inventory-bound')
            try:
                require(p.stat().st_uid != 987, 'dedicated-process-remains')
            except FileNotFoundError:
                pass
        for name in set(a.M['invocations']) - {UNIT}:
            a.inert(a.properties(name), False, name)
        return unit

    def controller(self, granted=False, after=False):
        a = self.a
        for relative in ['profile', 'admission.json', 'h1.json']:
            require(not os.path.lexists(STATE / relative), 'unexpected-native-authority')
        baseline = self.record('audit.json')['data']['controllerState']
        for relative in ['h1-probe', 'journal']:
            root = STATE / relative;s = root.lstat()
            require(a.reader_module.metadata(s) == baseline[relative]['directory'] and root.resolve() == root, 'retained-directory-drift')
        for name, saved in baseline['h1-probe']['files'].items():
            path = PROBE / name
            require(a.reader_module.metadata(path.lstat()) == saved, 'original-probe-metadata-drift')
            body = self.h.read_record(path, 987, 0o400, 977)
            expected = {'owner.json': self.descriptor['previousOwnerSha256'],
                        'HELD.json': self.descriptor['previousHeldSha256'],
                        'credential-marker.json': sha(encoded({'marker': 'SYNTHETIC-H1-NOT-A-CREDENTIAL'}))}[name]
            require(sha(body) == expected, 'original-probe-content-drift')
        names = a.entry_names(PROBE, 32)
        allowed = OLD_NAMES | ({GRANT.name} if granted else set())
        if after:
            allowed |= {'continuation-0001.attempt.json', 'continuation-0001.RESULT.json',
                        'continuation-0001.HELD.json', 'continuation-0001.failure.bin'}
            allowed |= {'continuation-0001.case-%02d.attempt.json' % i for i in range(1, 14)}
        require(OLD_NAMES <= names and names <= allowed, 'unexpected-probe-entry')
        require(a.entry_names(STATE / 'journal', 2) <= ({'owner.json'} if after else set()), 'journal-entry-drift')
        if granted:
            require(self.h.read_record(GRANT, 0, 0o440, 977) == encoded(self.grant_value()), 'root-grant-drift')

    def snapshot(self):
        self.runtime();self.activation();self.a.pending()
        # No activation is performed: unrelated HM/bootstrap/sync hooks are not run
        # or made new prerequisites for this synthetic controller operation.
        unit = self.idle()
        records, mounts, diagnostics = self.a.legacy_records()
        state = self.a.controller_state()
        require(not os.path.lexists(STATE / 'profile'), 'unexpected-profile-directory')
        require(self.a.command([self.a.M['nixStore'], '--query', '--hash', self.a.M['target']])
                == self.a.M['targetHash'], 'target-store-metadata-drift')
        require(self.idle() == unit, 'audit-time-unit-drift')
        return {'legacyRecords': records, 'mounts': mounts, 'diagnosticRecords': diagnostics,
                'priorActivationRecords': self.a.prior_activation(), 'controllerState': state,
                'units': {UNIT: unit}}

    def ready(self, phase):
        self.a.h.safe_ancestors(ROOT);self.a.h.private_root(ROOT)
        require(self.record('owner.json')['data'] == self.owner(), 'controller-owner-drift')
        expected = {'owner.json'}
        for previous in PHASES[:PHASES.index(phase)]:
            expected |= {previous + '.attempt.json', previous + '.done.json'}
        if phase != 'audit':
            expected.add('audit.json')
        require(self.a.entry_names(ROOT, 32) == expected, 'phase-consumed-or-incomplete')
        for previous in PHASES[:PHASES.index(phase)]:
            attempt = self.record(previous + '.attempt.json')
            done = self.record(previous + '.done.json')['data']
            require(done['attemptSha256'] == attempt['sha256'] and done['metadataSha256'] == self.metadata_sha, 'phase-checkpoint-drift')
        return self.record('audit.json') if phase != 'audit' else None

    def complete(self, phase, value):
        write(ROOT / (phase + '.done.json'), value | {
            'attemptSha256': self.record(phase + '.attempt.json')['sha256'], 'metadataSha256': self.metadata_sha})

    def audit(self):
        require(not os.path.lexists(ROOT), 'controller-already-consumed')
        self.a.h.safe_ancestors(ROOT);ROOT.mkdir(mode=0o700);self.a.h.sync_dir(ROOT.parent)
        write(ROOT / 'owner.json', self.owner())
        write(ROOT / 'audit.attempt.json', self.owner())
        data = self.snapshot();write(ROOT / 'audit.json', data)
        self.complete('audit', {'auditSha256': self.record('audit.json')['sha256']})

    def reconcile(self):
        audit = self.ready('reconcile');current = self.snapshot()
        for key in ['legacyRecords', 'mounts', 'diagnosticRecords', 'priorActivationRecords', 'controllerState', 'units']:
            require(current[key] == audit['data'][key], 'audit-to-reconciliation-drift')
        value = {'version': VERSION, 'scope': 'one-append-only-synthetic-continuation-0001',
                 'auditSha256': audit['sha256'], 'descriptorSha256': self.m['descriptorSha256'],
                 'previousOwnerSha256': self.descriptor['previousOwnerSha256'],
                 'previousHeldSha256': self.descriptor['previousHeldSha256'],
                 'diagnosticV2Sha256': self.a.M['diagnosticRecordHashes']['startup-diagnostic-v2.result.json'],
                 'observation': 'proc-visibility-correction-active-not-live-proof',
                 'ownerReleaseAuthorized': False, 'qualification': 'not-granted'}
        write(ROOT / 'reconcile.attempt.json', value)
        require(self.snapshot()['controllerState'] == current['controllerState'], 'reconciliation-time-drift')
        self.complete('reconcile', value)

    def capture(self):
        self.ready('capture');self.snapshot()
        value = {'version': VERSION, 'scope': 'continuation-0001-only', 'operatorPrivate': True,
                 'failureBytes': 131072, 'combinedLastHelperOutput': True,
                 'hashReadAuthorized': True, 'rawExportAuthorized': False, 'qualification': 'not-granted'}
        write(ROOT / 'capture.attempt.json', value);self.complete('capture', value)

    def grant_value(self):
        a = self.a
        return {'version': self.h.CONTINUATION, 'id': '0001', 'authority': 'one-synthetic-continuation-only',
                'descriptorSha256': self.m['descriptorSha256'], 'runtime': self.m['runtime'],
                'host': {'generation': a.M['target'], 'unitSha256': a.M['targetUnitSha256'],
                         'reconciliationSha256': self.record('reconcile.done.json')['sha256'],
                         'bootId': a.M['bootId'], 'stateDevice': a.inputs['mounts']['state']['device'],
                         'workspaceDevice': a.inputs['mounts']['slot']['device'],
                         'stateUUID': self.descriptor['stateUUID'], 'workspaceUUID': self.descriptor['workspaceUUID']},
                'limits': self.h.LIMITS, 'retainPrivateFailure': True}

    def grant(self):
        self.ready('grant');self.snapshot();self.controller()
        consent = self.record('capture.done.json')['data']
        require(consent['failureBytes'] == 131072 and consent['combinedLastHelperOutput'] is True
                and consent['hashReadAuthorized'] is True and consent['rawExportAuthorized'] is False, 'capture-consent-required')
        value = self.grant_value()
        write(ROOT / 'grant.attempt.json', {'grantSha256': sha(encoded(value)), 'qualification': 'not-granted'})
        self.snapshot();self.controller()  # Drift/uncertainty consumes the issuer before any grant effect.
        write(GRANT, value, gid=977)
        require(self.h.read_record(GRANT, 0, 0o440, 977) == encoded(value), 'grant-install-verification')
        self.complete('grant', {'grantSha256': sha(encoded(value)), 'qualification': 'not-granted'})

    def granted_preflight(self):
        self.runtime();self.activation();self.a.pending();self.idle();self.original();self.controller(granted=True)
        require(self.record('grant.done.json')['data']['grantSha256'] == sha(encoded(self.grant_value())), 'grant-checkpoint-drift')
        controls = self.a.command([self.a.M['systemctl'], 'show', UNIT,
                                  '--property=KillMode,TimeoutStopUSec,Restart,User,Group'])
        fields = dict(line.split('=', 1) for line in controls.splitlines())
        require(fields == {'KillMode': 'control-group', 'TimeoutStopUSec': '10s', 'Restart': 'no',
                           'User': 'pi-coordinator', 'Group': 'pi-coordinator'}, 'stop-control-definition-drift')

    def stop(self):
        """One separately disclosed fixed-unit stop; never ResetFailed/restart/kill fallback."""
        write(ROOT / 'stop.attempt.json', {'unit': UNIT, 'retry': False, 'qualification': 'not-granted'})
        try:
            self.a.command([self.a.M['systemctl'], 'stop', '--no-block', UNIT])
        except BaseException:
            pass  # The stop outcome is uncertain; inspect, never repeat its dispatch.
        deadline = time.monotonic() + 15
        for _ in range(31):
            try:
                return self.idle(after=True)
            except Exception:
                if time.monotonic() >= deadline:
                    break
                time.sleep(0.5)
        raise RuntimeError('stop-outcome-unknown-preserve-all-state')

    def artifacts(self):
        self.controller(granted=True, after=True)
        values = {};total = 0
        for name in sorted(self.a.entry_names(PROBE, 32) - OLD_NAMES - {GRANT.name}):
            path = PROBE / name
            if name.endswith('.failure.bin'):
                info = path.lstat()
                require(info.st_gid == 977 and stat.S_IMODE(info.st_mode) == 0o400, 'private-failure-metadata')
                body = self.a.file_bytes(path, 987, 131072, True)
                values[name] = {'bytes': len(body), 'sha256': sha(body), 'rawContentExported': False}
            else:
                body = self.h.read_record(path, 987, 0o400, 977)
                values[name] = {'sha256': sha(body), 'data': json.loads(body)}
            total += len(body);require(total <= 1024 * 1024, 'artifact-collection-bound')
        return values

    def validate_result(self, artifacts):
        prefix = 'continuation-0001.';g = self.grant_value();grant_sha = sha(encoded(g))
        continuation = {'id': '0001', 'grantSha256': grant_sha, 'descriptorSha256': g['descriptorSha256'],
                        'previousHeldSha256': self.descriptor['previousHeldSha256'],
                        'hostAttestation': g['host'], 'runtime': g['runtime'], 'limits': g['limits']}
        require(prefix + 'HELD.json' not in artifacts and prefix + 'failure.bin' not in artifacts, 'continuation-held')
        require(artifacts[prefix + 'attempt.json']['data'] == {
            'version': self.h.CONTINUATION, 'continuation': continuation, 'synthetic': True,
            'retry': False, 'qualification': 'not-granted'}, 'consumer-attempt-binding')
        result = artifacts[prefix + 'RESULT.json']['data']
        require(result['version'] == self.h.CONTINUATION and result['status'] == 'partial-h1'
                and result['qualification'] == 'not-granted' and result['synthetic'] is True
                and result['ownerRetained'] is True and result['continuation'] == continuation
                and result['harnessSha256'] == self.m['runtime']['harnessSha256']
                and result['settingsSha256'] == self.m['runtime']['settingsSha256']
                and result['stateDevice'] == g['host']['stateDevice']
                and result['workspaceDevice'] == g['host']['workspaceDevice']
                and result['pending'] == self.h.PENDING, 'consumer-result-binding')
        require(len(result['cases']) == 13, 'case-count')
        for i, (name, case) in enumerate(zip(CASES, result['cases']), 1):
            expected = 1 if name == 'existing-owner-refusal' else 0
            require(case['name'] == name and case['expectedExitObserved'] is True and type(case['exit']) is int
                    and case['exit'] == expected and re.fullmatch('[a-f0-9]{64}', case['outputSha256']), 'case-binding')
            require(artifacts[prefix + 'case-%02d.attempt.json' % i]['data'] == {
                'name': name, 'expectedExit': expected, 'grantSha256': grant_sha}, 'case-attempt-binding')
        ns = result['namespaceIds'];names = {'user', 'mnt', 'pid', 'net', 'ipc', 'uts', 'cgroup'}
        require(set(ns) == {'controller', 'worker'} and all(set(v) == names for v in ns.values())
                and all(type(ns[x][n]) is int and ns[x][n] > 0 for x in ns for n in names)
                and all(ns['controller'][n] != ns['worker'][n] for n in names), 'namespace-result-binding')
        require(result['inventory']['authority'] == 'not-granted', 'inventory-authority')
        return result

    def start(self):
        self.ready('start');self.granted_preflight()
        write(ROOT / 'start.attempt.json', {'unit': UNIT, 'grantSha256': sha(encoded(self.grant_value())),
                                         'retry': False, 'qualification': 'not-granted'})
        report = {'status': 'held', 'qualification': 'not-granted', 'ownersRetained': True,
                  'invocation': None, 'frames': [], 'artifacts': {}}
        quiescent = False;ok = False;dispatched = False;sample_bytes = 0
        try:
            self.granted_preflight()  # Attempt precedes even approval-time drift refusal.
            write(ROOT / 'dispatch.attempt.json', {'unit': UNIT, 'retry': False, 'qualification': 'not-granted'})
            dispatched = True
            self.a.command([self.a.M['systemctl'], 'start', '--no-block', UNIT])
            deadline = time.monotonic() + 250
            for _ in range(501):
                require(time.monotonic() < deadline, 'observation-deadline')
                unit = self.a.properties()
                invocation = unit['InvocationID']
                if invocation:
                    require(re.fullmatch('[a-f0-9]{32}', invocation) and report['invocation'] in {None, invocation}, 'invocation-changed')
                    report['invocation'] = invocation
                require(len(report['frames']) < 501, 'sample-count')
                sample = {'unit': unit, 'monotonic': time.monotonic()}
                size = len(encoded(sample));sample_bytes += size
                require(size <= 8192 and sample_bytes <= 3 * 1024 * 1024, 'sample-byte-bound')
                write(ROOT / ('sample-%03d.json' % len(report['frames'])), sample);report['frames'].append(sample)
                if unit['ActiveState'] in {'inactive', 'failed'} and unit['Job'] in {'', '0'} and unit['ExecMainStartTimestampMonotonic'] != '0':
                    final = self.idle(after=True);quiescent = True
                    self.runtime();report['activationAfter'] = self.activation()
                    report['retainedAfter'] = self.original(after=True)
                    report['artifacts'] = self.artifacts()
                    require(final['ActiveState'] == 'inactive' and final['Result'] == 'success'
                            and final['ExecMainStatus'] == '0' and final['ExecMainCode'] == '1'
                            and report['invocation'] is not None and final['InvocationID'] == report['invocation']
                            and final['ExecMainStartTimestampMonotonic'] == unit['ExecMainStartTimestampMonotonic'],
                            'successful-unit-exit-unavailable')
                    self.validate_result(report['artifacts']);ok = True;break
                time.sleep(0.5)
            require(ok, 'continuation-not-observed')
        except BaseException:
            # No exception/output/argv/environment strings cross this boundary.
            report['error'] = 'continuation-held-or-outcome-unknown'
        finally:
            if dispatched and not quiescent:
                try:
                    report['stopState'] = self.stop();quiescent = True
                except BaseException:
                    report['stopOutcome'] = 'unknown-no-retry'
            if quiescent and 'retainedAfter' not in report:
                try:
                    self.runtime();report['activationAfter'] = self.activation()
                    report['retainedAfter'] = self.original(after=True)
                except BaseException:
                    report['postRetentionCollection'] = 'held-not-preservation-proof'
            if quiescent and not report['artifacts']:
                try:
                    report['artifacts'] = self.artifacts()
                except BaseException:
                    report['artifactCollection'] = 'held'
            report['quiescenceObserved'] = quiescent
            report['status'] = 'partial-h1-observed' if ok else 'held'
            write(ROOT / ('RESULT.json' if ok else 'HELD.json'), report)
        # This phase is deliberately never replayable, including successful partial H1.
        return report


def load(manifest):
    require(os.geteuid() == 0 and os.environ.get('SUDO_UID') == '1000' and sys.stdin.isatty(), 'human-sudo-terminal-required')
    require(re.fullmatch('[a-f0-9]{64}', manifest), 'manifest-format')
    source = Path(__file__);info = source.lstat()
    require(str(source).startswith('/nix/store/') and source.resolve() == source and info.st_uid == 0
            and stat.S_ISREG(info.st_mode) and not info.st_mode & 0o222, 'immutable-controller-required')
    a = module(BASE, BASE_SHA, 'passive_activation_checks')
    a.load(BASE_MANIFEST)  # Verifiers/imports only; NEVER audit/activate/main/saved_audit.
    bodies = a.checked_packet(PACKET, manifest, 1000, 262144, 1048576)
    require(sha(Path(__file__).read_bytes()) == sha(bodies['controller.py']), 'reviewed-controller-binding')
    m = json.loads(bodies['metadata.json'])
    require(set(m) == {'runtime', 'descriptorSha256', 'activationRecords'}, 'metadata-schema')
    h = module(HARNESS, m['runtime']['harnessSha256'], 'pure_continuation_contract')
    return Controller(a, h, m, sha(bodies['metadata.json']), manifest)


def interrupted(_number, _frame):
    raise InterruptedError('operator-interruption')


def main():
    os.umask(0o077)
    for number in [signal.SIGTERM, signal.SIGHUP]:
        signal.signal(number, interrupted)
    require(len(sys.argv) == 3 and sys.argv[1] in PHASES, 'exact-phase-manifest-required')
    phase = sys.argv[1];c = load(sys.argv[2])
    effects = {
        'audit': 'Read the retained private H1/diagnostic/activation receipts and physical/controller metadata; create one private, non-replayable audit evidence owner and export metadata-only evidence to the operator. Do not grant, start, release, reset or qualify anything.',
        'reconcile': 'Append a scoped reconciliation acknowledging the retained original H1 failure and consumed diagnostics with the proc correction active. Keep every original hold/owner; this grants neither execution nor H1 qualification.',
        'capture': 'Permit this one synthetic continuation to retain up to128KiB of the last combined helper output privately on failure, and permit bounded hash-only reading of that file. No raw content export, credentials, provider or model use is authorized.',
        'grant': 'Install the root-owned0440 continuation-0001 grant in the EXISTING held probe directory, bound to these exact runtime/host/reconciliation/storage identities. Consume the issuer before writing; do not start, release, reset, replace or qualify anything.',
        'start': 'Start pi-coordinator.service once for the thirteen synthetic no-model probes and collect bounded metadata/receipts for about250seconds, exporting private metadata/receipt evidence but never raw helper failure contents. If this dispatch fails, is interrupted or has unknown/nonquiescent outcome, allow ONE stop of that same dedicated unit and a15-second teardown polling window (metadata queries can overrun it); preserve all partial state, with no reset/restart/retry/cleanup/release or H1 qualification.'}
    print('Target: ' + c.a.M['target'] + '\nUnit SHA256: ' + c.a.M['targetUnitSha256']
          + '\nManifest: ' + sys.argv[2] + '\nContinuation: 0001; original state/slot-1 only', file=sys.stderr)
    print('Approve: ' + effects[phase] + '\n\n<y/N> ', end='', flush=True, file=sys.stderr)
    if sys.stdin.readline().rstrip('\r\n') not in {'y', 'Y'}:
        return 3
    c.a.checked_packet(PACKET, sys.argv[2], 1000, 262144, 1048576)
    result = None
    if phase == 'audit':
        c.audit()
    else:
        c.a.h.private_root(ROOT)
        fd = os.open(ROOT / 'owner.json', os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        try:
            info = os.fstat(fd)
            require(stat.S_ISREG(info.st_mode) and info.st_uid == 0 and info.st_nlink == 1
                    and stat.S_IMODE(info.st_mode) == 0o400, 'unsafe-controller-lock')
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            result = getattr(c, phase)()
        finally:
            os.close(fd)
    evidence = result if phase == 'start' else c.record('audit.json' if phase == 'audit' else phase + '.done.json')['data']
    print(json.dumps({'version': VERSION, 'phase': phase, 'qualification': 'not-granted',
                      'ownersRetained': True, 'rawFailureExported': False, 'evidence': evidence}, sort_keys=True))
    return 1 if phase == 'start' and result['status'] != 'partial-h1-observed' else 0


if __name__ == '__main__':
    try:
        code = main()
    except BaseException:
        print('Continuation controller refused/held; preserve every checkpoint. No retry or release.', file=sys.stderr)
        code = 1
    sys.exit(code)
