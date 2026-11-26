"""Offline protocol tests: fake privilege/unit effects, real private temporary files.
No sudo, systemd effect, namespace, credential, provider or original-state access.
"""
import copy
from contextlib import contextmanager
import importlib.util
import io
import json
import os
from pathlib import Path
import stat
import sys
import tempfile
import types
import unittest
from unittest.mock import Mock, patch

SOURCE = Path(sys.argv.pop(1)) if len(sys.argv) > 1 else Path(__file__).with_name('pi-h1-continuation-controller.py')
spec = importlib.util.spec_from_file_location('controller_under_test', SOURCE)
c = importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
REAL_WRITE = c.write
REAL_PATH = Path


def bounded_names(path, maximum):
    names = {p.name for p in path.iterdir()}
    c.require(len(names) <= maximum, 'fixture-entry-bound')
    return names


def fixture_read(path, uid=0, maximum=5*1024*1024):
    # uid/gid authority is explicitly stubbed, never presented as privilege proof.
    s = path.lstat()
    c.require(stat.S_ISREG(s.st_mode) and s.st_nlink == 1 and not s.st_mode & 0o077
              and s.st_size <= maximum, 'fixture-unsafe-record')
    body = path.read_bytes()
    return {'sha256': c.sha(body), 'data': json.loads(body)}


def metadata(s):
    return {'uid': s.st_uid, 'gid': s.st_gid, 'mode': stat.S_IMODE(s.st_mode),
            'dev': s.st_dev, 'inode': s.st_ino, 'type': stat.S_IFMT(s.st_mode)}


def private_root(path):
    c.require(path.is_dir() and not path.is_symlink() and stat.S_IMODE(path.stat().st_mode) == 0o700, 'fixture-private-root')


@contextmanager
def store_uid_attestation():
    # Nix's build namespace may expose host-root store files as overflow UID65534.
    # Normalize ONLY this explicit authority fixture; production still requires UID0.
    lstat, fstat = Path.lstat, os.fstat
    def root_info(info):
        return types.SimpleNamespace(**{k:getattr(info,k) for k in dir(info) if k.startswith('st_')}|{'st_uid':0})
    def store_stat(path):
        info=lstat(path)
        return root_info(info) if str(path).startswith('/nix/store/') else info
    def store_fstat(fd):
        info=fstat(fd)
        return root_info(info) if info.st_uid != os.getuid() else info
    with patch.object(Path,'lstat',store_stat),patch.object(os,'fstat',store_fstat):
        yield


class Protocol(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name);self.root = self.base/'controller';self.state = self.base/'state'
        self.probe = self.state/'h1-probe';self.work = self.base/'work';self.group = self.base/'group'
        for p in [self.state, self.probe, self.state/'journal', self.work]:
            p.mkdir(mode=0o700)
        for name, body in [('owner.json', {'old': 'owner'}), ('HELD.json', {'old': 'held'}),
                           ('credential-marker.json', {'marker':'SYNTHETIC-H1-NOT-A-CREDENTIAL'})]:
            REAL_WRITE(self.probe/name, body)
        self.descriptor = self.base/'descriptor.json'
        descriptor = {'version': 'pi-h1-continuation/v1', 'id': '0001', 'taskId': 'h1_fixture_20261124',
                      'previousOwnerSha256': c.sha((self.probe/'owner.json').read_bytes()),
                      'previousHeldSha256': c.sha((self.probe/'HELD.json').read_bytes()),
                      'previousWriteOutputSha256': 'f'*64, 'stateUUID':'11111111-1111-1111-1111-111111111111',
                      'workspaceUUID':'22222222-2222-2222-2222-222222222222'}
        REAL_WRITE(self.descriptor, descriptor)
        self.settings = self.base/'settings.json'
        REAL_WRITE(self.settings, {'continuation':str(self.descriptor), 'state':str(self.state),
                                   'workspace':str(self.work), 'taskId':'h1_fixture_20261124'})
        self.unit_file = self.base/'generation/etc/systemd/system/pi-coordinator.service'
        self.unit_file.parent.mkdir(parents=True);self.unit_file.write_text('immutable unit fixture\n')
        self.activation_root = self.base/'activation';self.activation_root.mkdir(mode=0o700)
        activation_hashes = {}
        for name in ['owner.json','audit.attempt.json','evidence.json','audit.done.json',
                     'failed-unit-definitions.json','activate.attempt.json','activate.done.json']:
            REAL_WRITE(self.activation_root/name, {'fixture': name})
            activation_hashes[name] = c.sha((self.activation_root/name).read_bytes())
        self.runtime = {'harnessSha256':'a'*64,'settingsSha256':'b'*64,'files':{}}
        self.h = types.SimpleNamespace(
            VERSION='pi-local-h1-probes/v1', CONTINUATION='pi-h1-continuation/v1',
            LIMITS={'dispatches':13,'operationSeconds':15,'inputBytes':8192,'captureBytes':131072,
                    'failureBytes':131072,'runtimeSeconds':240,'stopGraceSeconds':10},
            PENDING=['real host checks remain'], runtime_binding=lambda _:copy.deepcopy(self.runtime),
            read_record=lambda p,uid,mode,gid:fixture_read_bytes(p, mode),
            root_grant=lambda p:fixture_read_bytes(p,0o440))
        self.unit = {'LoadState':'loaded','ActiveState':'inactive','SubState':'dead','MainPID':'0',
                     'ControlGroup':'','Job':'','NRestarts':'0','DropInPaths':'','WantedBy':'','TriggeredBy':'',
                     'ProcSubset':'all','ProtectProc':'invisible','RuntimeMaxUSec':'4min',
                     'FragmentPath':str(self.unit_file),'InvocationID':'','ExecMainStartTimestampMonotonic':'0',
                     'Result':'success','ExecMainStatus':'0','ExecMainCode':'0'}
        self.saved = {'legacyRecords':{'old':'unchanged'},'mounts':{'fixed':'mounts'},
                      'diagnosticRecords':{'consumed':'unchanged'},'priorActivationRecords':{'old':'receipts'},
                      'controllerState':{},'units':{'pi-coordinator.service':self.unit}}
        self.saved['controllerState'] = {
            'h1-probe':{'directory':metadata(self.probe.stat()),
                        'files':{p.name:metadata(p.stat()) for p in self.probe.iterdir()}},
            'journal':{'directory':metadata((self.state/'journal').stat()),'files':{}}}
        self.commands = [];self.snapshot_calls = 0
        self.a = types.SimpleNamespace(
            M={'target':str(self.unit_file.parents[3]),'targetUnitSha256':c.sha(self.unit_file.read_bytes()),
               'bootId':'fixture-boot','booted':str(self.base/'booted'),'default':str(self.base/'default'),
               'diagnosticRecordHashes':{'startup-diagnostic-v2.result.json':'d'*64},'systemctl':'FIXTURE-NO-EXEC',
               'invocations':{'pi-coordinator.service':'old'}},
            STATE=self.activation_root, read_record=fixture_read, entry_names=bounded_names,
            h=types.SimpleNamespace(safe_ancestors=lambda _:None, private_root=private_root, sync_dir=lambda _:None),
            inputs={'mounts':{'state':{'device':1792,'uuid':descriptor['stateUUID']},
                              'slot':{'device':1793,'uuid':descriptor['workspaceUUID']}}},
            reader_module=types.SimpleNamespace(metadata=metadata),
            prior_activation=Mock(return_value={'previous':'verified'}), roots=Mock(), owned=Mock(), pending=Mock(),
            snapshot=self.snapshot, properties=lambda *args:copy.deepcopy(self.unit),
            inert=Mock(), command=self.command)
        self.m = {'runtime':copy.deepcopy(self.runtime),'descriptorSha256':c.sha(self.descriptor.read_bytes()),
                  'activationRecords':activation_hashes}
        for name, value in [('ROOT',self.root),('STATE',self.state),('WORK',self.work),('PROBE',self.probe),
                            ('GRANT',self.probe/'continuation-0001.grant.json'),('GROUP',self.group),('SETTINGS',str(self.settings))]:
            p = patch.object(c,name,value);p.start();self.addCleanup(p.stop)
        self.writer = patch.object(c,'write',self.write);self.writer.start();self.addCleanup(self.writer.stop)
        self.clock = types.SimpleNamespace(now=0.0, monotonic=lambda:self.clock.now,
                                          sleep=lambda seconds:setattr(self.clock,'now',self.clock.now+seconds))
        p = patch.object(c,'time',self.clock);p.start();self.addCleanup(p.stop)
        self.controller = c.Controller(self.a,self.h,self.m,'e'*64,'f'*64)
        self.runtime_patch = patch.object(c,'root_runtime',side_effect=lambda _:copy.deepcopy(self.runtime))
        self.runtime_patch.start();self.addCleanup(self.runtime_patch.stop)
        # These independently exercised host checks are stubbed for phase-flow tests.
        self.controller.idle = Mock(return_value=copy.deepcopy(self.unit))
        self.controller.snapshot = Mock(side_effect=lambda:self.snapshot(False))
        self.controller.original = Mock(return_value={})
        self.original_old = {p.name:p.read_bytes() for p in self.probe.iterdir()}

    def snapshot(self, before=False):
        self.snapshot_calls += 1
        return copy.deepcopy(self.saved)

    def write(self,path,value,gid=None):
        if gid is not None:
            self.assertEqual(gid,977)
            self.assertTrue((self.root/'grant.attempt.json').exists())
            REAL_WRITE(path,value);path.chmod(0o440)
        else:
            REAL_WRITE(path,value)

    def command(self, argv):
        self.commands.append(argv)
        if argv[1]=='show':
            return 'KillMode=control-group\nTimeoutStopUSec=10s\nRestart=no\nUser=pi-coordinator\nGroup=pi-coordinator'
        if argv[1]=='start':
            self.assertTrue((self.root/'dispatch.attempt.json').exists())
        if argv[1]=='stop':
            self.assertTrue((self.root/'stop.attempt.json').exists())
        return ''

    def advance(self,last='grant'):
        for phase in c.PHASES[:c.PHASES.index(last)+1]:
            getattr(self.controller,phase)()

    def assert_old(self):
        for name,body in self.original_old.items():
            self.assertEqual((self.probe/name).read_bytes(),body)

    def test_phase_order_full_issuer_and_no_effect_dispatch(self):
        self.advance()
        self.assertEqual(self.commands,[])
        self.assertEqual(c.GRANT.read_bytes(),c.encoded(self.controller.grant_value()))
        self.assertEqual(stat.S_IMODE(c.GRANT.stat().st_mode),0o440)
        self.assertEqual(self.controller.grant_value()['host']['reconciliationSha256'],fixture_read(self.root/'reconcile.done.json')['sha256'])
        self.assert_old()
        for phase in c.PHASES[:-1]:
            with self.subTest(replay=phase),self.assertRaises(Exception):getattr(self.controller,phase)()

    def test_runtime_cannot_attest_a_different_physical_uuid(self):
        self.controller.runtime();self.a.inputs['mounts']['state']['uuid']='other-volume'
        with self.assertRaises(Exception):self.controller.runtime()
        self.assertEqual(self.commands,[]);self.assertFalse(c.GRANT.exists())

    def test_skip_phases_refuse(self):
        for phase in c.PHASES[1:]:
            with self.subTest(phase=phase),self.assertRaises(Exception):getattr(self.controller,phase)()
        self.assertFalse(self.root.exists());self.assertEqual(self.commands,[])

    def test_partial_audit_is_consumed(self):
        self.controller.snapshot = Mock(side_effect=RuntimeError('PRIVATE_DO_NOT_LOG'))
        with self.assertRaises(Exception):self.controller.audit()
        self.assertTrue((self.root/'audit.attempt.json').exists())
        with self.assertRaises(Exception):self.controller.audit()
        self.assertFalse((self.root/'audit.done.json').exists());self.assertEqual(self.commands,[])

    def test_reconcile_drift_before_attempt_and_no_authority(self):
        self.advance('audit');self.saved['units']['new']={}
        with self.assertRaises(Exception):self.controller.reconcile()
        self.assertFalse((self.root/'reconcile.attempt.json').exists());self.assertFalse(c.GRANT.exists())

    def test_capture_required_not_implicit_in_reconciliation(self):
        self.advance('reconcile')
        with self.assertRaises(Exception):self.controller.grant()
        self.assertFalse(c.GRANT.exists());self.assertEqual(self.commands,[])

    def test_partial_grant_is_consumed_and_never_replaces(self):
        self.advance('capture')
        def collision(path,value,gid=None):
            if path == c.GRANT:
                path.write_text('collision')
            self.write(path,value,gid)
        with patch.object(c,'write',side_effect=collision),self.assertRaises(Exception):self.controller.grant()
        self.assertTrue((self.root/'grant.attempt.json').exists())
        self.assertEqual(c.GRANT.read_text(),'collision')
        with self.assertRaises(Exception):self.controller.grant()
        self.assertEqual(self.commands,[])

    def test_existing_grant_fails_before_consuming_issuer(self):
        self.advance('capture');c.GRANT.write_text('collision')
        with self.assertRaises(Exception):self.controller.grant()
        self.assertFalse((self.root/'grant.attempt.json').exists());self.assertEqual(c.GRANT.read_text(),'collision')

    @store_uid_attestation()
    def test_root_runtime_matches_actual_nonroot_consumer_contract(self):
        self.runtime_patch.stop()
        harness=os.environ.get('PI_H1_CONTROLLER_HARNESS',c.HARNESS)
        actual = c.module(harness,c.sha(Path(harness).read_bytes()),'consumer_schema_only')
        settings=json.loads(Path(os.environ.get('PI_H1_SETTINGS','/nix/store/rv3vjqb2zpwpcgcjvma3g74dz8z20a5l-pi-h1-settings.json')).read_bytes())
        self.assertEqual(c.root_runtime(settings,harness),actual.runtime_binding(settings))
        # The consumer's convenience root_grant() is group-relative; the root issuer
        # must use explicit UID0/GID977, not its own GID0.
        source=SOURCE.read_text();self.assertNotIn('self.h.root_grant(',source)
        self.assertIn('self.h.read_record(GRANT, 0, 0o440, 977)',source)

    @store_uid_attestation()
    def test_actual_consumer_accepts_issuer_schema_with_explicit_authority_stubs(self):
        # Parser interoperability only: fake root file authority and host/unit attestation.
        self.advance();self.runtime_patch.stop()
        harness=os.environ.get('PI_H1_CONTROLLER_HARNESS',c.HARNESS)
        actual=c.module(harness,c.sha(Path(harness).read_bytes()),'actual_consumer_parser')
        settings=json.loads(Path(os.environ.get('PI_H1_SETTINGS','/nix/store/rv3vjqb2zpwpcgcjvma3g74dz8z20a5l-pi-h1-settings.json')).read_bytes())
        descriptor=json.loads(Path(settings['continuation']).read_bytes())
        self.controller.descriptor=descriptor;self.m['descriptorSha256']=c.sha(Path(settings['continuation']).read_bytes())
        self.m['runtime']=c.root_runtime(settings,harness)
        self.a.M.update(target='/nix/store/'+'a'*32+'-nixos-system-angel-26.11.20260923.4975466')
        old_owner={'version':actual.VERSION,'synthetic':True,'retry':False}
        held={'version':actual.VERSION,'phase':'tools','cases':[{'name':'write','exit':1,
              'expectedExitObserved':False,'outputSha256':descriptor['previousWriteOutputSha256']}],
              'ownerRetained':True,'retry':False,'qualification':'not-granted'}
        for name,value in [('owner.json',old_owner),('HELD.json',held)]:
            (self.probe/name).unlink();REAL_WRITE(self.probe/name,value)
        self.assertEqual(c.sha((self.probe/'owner.json').read_bytes()),descriptor['previousOwnerSha256'])
        self.assertEqual(c.sha((self.probe/'HELD.json').read_bytes()),descriptor['previousHeldSha256'])
        c.GRANT.unlink();REAL_WRITE(c.GRANT,self.controller.grant_value());c.GRANT.chmod(0o440)
        digest=actual.file_digest;expected_unit=self.a.M['target']+'/etc/systemd/system/pi-coordinator.service'
        with patch.object(actual,'root_grant',side_effect=lambda p:fixture_read_bytes(p,0o440)),\
             patch.object(actual,'host_state',return_value={'bootId':'fixture-boot','stateDevice':1792,'workspaceDevice':1793}),\
             patch.object(actual,'file_digest',side_effect=lambda p:self.a.M['targetUnitSha256'] if str(p)==expected_unit else digest(p)):
            result=actual.prepare_continuation(settings,self.probe)
        self.assertEqual(result['grantSha256'],c.sha(c.GRANT.read_bytes()))
        self.assertEqual(result['hostAttestation']['reconciliationSha256'],fixture_read(self.root/'reconcile.done.json')['sha256'])
        self.assertEqual(self.commands,[])

    def test_grant_rechecks_after_durable_attempt(self):
        self.advance('capture');count=[0];original=self.controller.snapshot
        def changed(*args):
            count[0]+=1
            if count[0]==2:raise RuntimeError('drift')
            return original(*args)
        self.controller.snapshot=changed
        with self.assertRaises(Exception):self.controller.grant()
        self.assertTrue((self.root/'grant.attempt.json').exists());self.assertFalse(c.GRANT.exists())
        with self.assertRaises(Exception):self.controller.grant()

    def test_original_symlink_and_hardlink_refuse(self):
        self.advance('capture');path=self.probe/'owner.json';path.unlink();path.symlink_to(self.probe/'HELD.json')
        with self.assertRaises(Exception):self.controller.grant()
        path.unlink();os.link(self.probe/'HELD.json',path)
        with self.assertRaises(Exception):self.controller.grant()
        self.assertFalse(c.GRANT.exists())

    def test_same_metadata_cannot_adopt_a_different_review_manifest(self):
        self.advance('audit');self.controller.review_sha='0'*64
        with self.assertRaises(Exception):self.controller.reconcile()
        self.assertFalse((self.root/'reconcile.attempt.json').exists());self.assertEqual(self.commands,[])

    def test_partial_checkpoint_and_metadata_tamper_refuse(self):
        self.advance('capture');p=self.root/'capture.done.json';data=fixture_read(p)['data'];p.unlink()
        data['metadataSha256']='0'*64;REAL_WRITE(p,data)
        with self.assertRaises(Exception):self.controller.grant()
        self.assertFalse(c.GRANT.exists())

    def test_start_drift_before_dispatch_does_not_stop_someone_else(self):
        self.advance();self.controller.granted_preflight=Mock(side_effect=[None,RuntimeError('PRIVATE')])
        result=self.controller.start()
        self.assertEqual(result['status'],'held');self.assertEqual(self.commands,[])
        self.assertFalse((self.root/'dispatch.attempt.json').exists());self.assertFalse((self.root/'stop.attempt.json').exists())
        with self.assertRaises(Exception):self.controller.start()

    def test_start_command_uncertainty_stops_only_once_and_retains(self):
        self.advance();self.controller.granted_preflight=Mock()
        def uncertain(argv):
            self.command(argv)
            if argv[1]=='start':raise RuntimeError('PRIVATE_DO_NOT_LOG')
        self.a.command=uncertain
        result=self.controller.start()
        self.assertEqual([a[1] for a in self.commands],['start','stop'])
        self.assertTrue(result['quiescenceObserved']);self.assertEqual(result['status'],'held')
        self.assertNotIn('PRIVATE',(self.root/'HELD.json').read_text());self.assert_old()
        with self.assertRaises(Exception):self.controller.start()

    def test_stop_unknown_is_never_retried(self):
        self.advance();self.controller.granted_preflight=Mock();self.controller.idle=Mock(side_effect=RuntimeError('busy'))
        self.a.properties=Mock(side_effect=RuntimeError('metadata unavailable'))
        result=self.controller.start()
        self.assertEqual([a[1] for a in self.commands],['start','stop'])
        self.assertFalse(result['quiescenceObserved']);self.assertEqual(result['stopOutcome'],'unknown-no-retry')
        self.assertTrue((self.root/'stop.attempt.json').exists());self.assert_old()

    def test_failure_preservation_uncertainty_is_not_silently_passed(self):
        self.advance();self.controller.granted_preflight=Mock();self.a.properties=Mock(side_effect=RuntimeError('unknown'))
        self.controller.original=Mock(side_effect=RuntimeError('changed-retained-record'))
        result=self.controller.start()
        self.assertEqual(result['status'],'held')
        self.assertEqual(result['postRetentionCollection'],'held-not-preservation-proof')
        self.assertNotIn('retainedAfter',result);self.assert_old()

    def test_interruption_performs_one_authorized_stop(self):
        self.advance();self.controller.granted_preflight=Mock();self.a.properties=Mock(side_effect=KeyboardInterrupt)
        result=self.controller.start()
        self.assertEqual([a[1] for a in self.commands],['start','stop']);self.assertEqual(result['status'],'held')

    def test_sigterm_handler_takes_the_same_one_stop_path(self):
        self.advance();self.controller.granted_preflight=Mock()
        self.a.properties=Mock(side_effect=lambda:c.interrupted(15,None))
        result=self.controller.start()
        self.assertEqual([a[1] for a in self.commands],['start','stop'])
        self.assertEqual(result['status'],'held');self.assertTrue(result['quiescenceObserved'])

    def test_unchanged_start_metadata_hits_finite_deadline_and_stops(self):
        self.advance();self.controller.granted_preflight=Mock()
        result=self.controller.start()
        self.assertEqual([a[1] for a in self.commands],['start','stop']);self.assertLessEqual(len(result['frames']),501)
        self.assertEqual(result['status'],'held');self.assertLessEqual(self.clock.now,266)

    def consumer_artifacts(self):
        g=self.controller.grant_value();gh=c.sha(c.encoded(g));prefix='continuation-0001.'
        continuation={'id':'0001','grantSha256':gh,'descriptorSha256':g['descriptorSha256'],
                      'previousHeldSha256':self.controller.descriptor['previousHeldSha256'],
                      'hostAttestation':g['host'],'runtime':g['runtime'],'limits':g['limits']}
        out={prefix+'attempt.json':{'data':{'version':self.h.CONTINUATION,'continuation':continuation,
                                         'synthetic':True,'retry':False,'qualification':'not-granted'}}}
        cases=[]
        for i,name in enumerate(c.CASES,1):
            expected=1 if name=='existing-owner-refusal' else 0
            cases.append({'name':name,'exit':expected,'expectedExitObserved':True,'outputSha256':'a'*64})
            out[prefix+'case-%02d.attempt.json'%i]={'data':{'name':name,'expectedExit':expected,'grantSha256':gh}}
        names=['user','mnt','pid','net','ipc','uts','cgroup']
        result={'version':self.h.CONTINUATION,'status':'partial-h1','qualification':'not-granted','synthetic':True,
                'ownerRetained':True,'continuation':continuation,'harnessSha256':self.runtime['harnessSha256'],
                'settingsSha256':self.runtime['settingsSha256'],'stateDevice':1792,'workspaceDevice':1793,
                'pending':self.h.PENDING,'cases':cases,'inventory':{'authority':'not-granted'},
                'namespaceIds':{'controller':{n:i+1 for i,n in enumerate(names)},'worker':{n:i+101 for i,n in enumerate(names)}}}
        out[prefix+'RESULT.json']={'data':result};return out

    def test_closed_consumer_result_and_each_binding_refuses_tamper(self):
        self.advance();artifacts=self.consumer_artifacts();self.controller.validate_result(artifacts)
        mutations=[lambda a:a['continuation-0001.RESULT.json']['data'].update(qualification='granted'),
                   lambda a:a['continuation-0001.RESULT.json']['data']['cases'].pop(),
                   lambda a:a['continuation-0001.RESULT.json']['data']['cases'][0].update(exit=True),
                   lambda a:a['continuation-0001.case-01.attempt.json']['data'].update(grantSha256='0'*64),
                   lambda a:a['continuation-0001.RESULT.json']['data']['namespaceIds']['worker'].update(user=1),
                   lambda a:a.update({'continuation-0001.HELD.json':{}})]
        for mutation in mutations:
            altered=copy.deepcopy(artifacts);mutation(altered)
            with self.subTest(mutation=mutations.index(mutation)),self.assertRaises(Exception):self.controller.validate_result(altered)

    def test_success_is_partial_and_retains_owners(self):
        self.advance();self.controller.granted_preflight=Mock()
        self.unit.update(InvocationID='a'*32,ExecMainStartTimestampMonotonic='100',ExecMainCode='1')
        self.controller.idle.return_value=copy.deepcopy(self.unit)
        self.controller.artifacts=Mock(return_value=self.consumer_artifacts())
        result=self.controller.start()
        self.assertEqual(result['status'],'partial-h1-observed');self.assertEqual(result['qualification'],'not-granted')
        self.assertTrue(result['quiescenceObserved']);self.assertTrue((self.root/'RESULT.json').exists())
        self.assertEqual(result['activationAfter']['current'],self.m['activationRecords']);self.assertIn('retainedAfter',result)
        self.assertEqual([a[1] for a in self.commands],['start']);self.assert_old()
        with self.assertRaises(Exception):self.controller.start()

    def test_exit_receipt_without_invocation_is_not_success(self):
        self.advance();self.controller.granted_preflight=Mock()
        self.unit.update(ExecMainStartTimestampMonotonic='100',ExecMainCode='1')
        self.controller.idle.return_value=copy.deepcopy(self.unit)
        self.controller.artifacts=Mock(return_value=self.consumer_artifacts())
        self.assertEqual(self.controller.start()['status'],'held');self.assert_old()

    def test_replaced_final_invocation_cannot_borrow_success_receipts(self):
        self.advance();self.controller.granted_preflight=Mock()
        self.unit.update(InvocationID='a'*32,ExecMainStartTimestampMonotonic='100',ExecMainCode='1')
        self.controller.idle.return_value=copy.deepcopy(self.unit)|{'InvocationID':'b'*32}
        self.controller.artifacts=Mock(return_value=self.consumer_artifacts())
        self.assertEqual(self.controller.start()['status'],'held')

    def test_original_receipts_storage_and_consumed_diagnostics_stay_bound(self):
        records={'retained/owner':{'available':True,'sha256':'a'*64},'synthetic-journal/owner.json':{'available':False}}
        mounts={'state':{'uuid':'state'},'slot':{'uuid':'slot'},'workspaceTopLevel':{'count':1}}
        diagnostic=b'{"synthetic":"diagnostic"}'
        self.a.M['diagnosticRecordHashes']={'startup-diagnostic-v2.result.json':c.sha(diagnostic)}
        self.a.retained={'records':copy.deepcopy(records),'mountsWorkspace':copy.deepcopy(mounts)}
        self.a.reader_module.Reader=Mock(return_value=types.SimpleNamespace(data=lambda p:(diagnostic,{})))
        self.a.reader_module.private_records=lambda *args:copy.deepcopy(records)
        self.a.reader_module.mounts_and_workspace=lambda *args:copy.deepcopy(mounts)
        c.Controller.original(self.controller)
        records['synthetic-journal/owner.json']={'available':True}
        with self.assertRaises(Exception):c.Controller.original(self.controller)
        REAL_WRITE(self.state/'journal/owner.json',{'version':self.h.VERSION,'synthetic':True,'reconciliation':'human'})
        c.Controller.original(self.controller,after=True)
        records['retained/owner']['sha256']='0'*64
        with self.assertRaises(Exception):c.Controller.original(self.controller,after=True)
        records['retained/owner']['sha256']='a'*64;mounts['state']['uuid']='changed'
        with self.assertRaises(Exception):c.Controller.original(self.controller,after=True)
        mounts['state']['uuid']='state';self.a.M['diagnosticRecordHashes']['startup-diagnostic-v2.result.json']='0'*64
        with self.assertRaises(Exception):c.Controller.original(self.controller,after=True)

    def test_real_root_grant_writer_sets_explicit_gid_before_publication(self):
        path=self.base/'grant-writer-fixture.json'
        with patch.object(c.os,'fchown') as chown:
            REAL_WRITE(path,{'synthetic':True},gid=977)
        self.assertEqual(chown.call_args.args[1:],(0,977))
        self.assertEqual(stat.S_IMODE(path.stat().st_mode),0o440)
        with self.assertRaises(Exception):REAL_WRITE(path,{'replacement':True},gid=977)
        self.assertEqual(json.loads(path.read_bytes()),{'synthetic':True})

    def test_audit_yes_needs_review_recheck_and_creates_only_fixture_evidence(self):
        self.a.checked_packet=Mock()
        with patch.object(c,'load',return_value=self.controller),patch.object(c.sys,'argv',['controller','audit','a'*64]),\
             patch.object(c.sys,'stdin',io.StringIO('y\n')),patch.object(c.sys,'stdout',io.StringIO()) as output,\
             patch.object(c.sys,'stderr',io.StringIO()):
            self.assertEqual(c.main(),0)
        self.a.checked_packet.assert_called_once();result=json.loads(output.getvalue())
        self.assertEqual(result['phase'],'audit');self.assertEqual(result['qualification'],'not-granted')
        self.assertEqual(self.commands,[]);self.assert_old()

    def test_real_idle_validator_rejects_drift(self):
        proc=self.base/'proc';(proc/'sys/kernel/random').mkdir(parents=True)
        (proc/'sys/kernel/random/boot_id').write_text('fixture-boot')
        mapping={'/proc':proc,'/proc/sys/kernel/random/boot_id':proc/'sys/kernel/random/boot_id',
                 '/run/current-system':self.unit_file.parents[3],'/run/booted-system':self.base/'booted',
                 '/nix/var/nix/profiles/system':self.base/'default'}
        def translate(value):return mapping.get(str(value),REAL_PATH(value))
        with patch.object(c,'Path',side_effect=translate):
            c.Controller.idle(self.controller)
            for key,value in [('MainPID','42'),('Job','123'),('DropInPaths','override'),('NRestarts','1'),
                              ('RuntimeMaxUSec','infinity'),('ProcSubset','pid'),('ProtectProc','default')]:
                old=self.unit[key];self.unit[key]=value
                with self.subTest(key=key),self.assertRaises(Exception):c.Controller.idle(self.controller)
                self.unit[key]=old
            self.group.mkdir()
            with self.assertRaises(Exception):c.Controller.idle(self.controller)

    def test_real_snapshot_uses_only_current_h1_read_verifiers(self):
        self.a.legacy_records=Mock(return_value=({'receipts':'same'},{'mounts':'same'},{'diagnostic':'same'}))
        self.a.controller_state=Mock(return_value=copy.deepcopy(self.saved['controllerState']))
        self.a.M.update(nixStore='FIXTURE-NIX-NO-EXEC',targetHash='known-store-metadata')
        self.a.command=Mock(return_value='known-store-metadata')
        result=c.Controller.snapshot(self.controller)
        self.assertEqual(result['legacyRecords'],{'receipts':'same'})
        self.assertIn('pi-coordinator.service',result['units'])
        self.a.snapshot_calls=0
        self.assertEqual(self.snapshot_calls,0)  # Not the old activation snapshot/HM hook guard.
        self.a.command.assert_called_once_with(['FIXTURE-NIX-NO-EXEC','--query','--hash',self.a.M['target']])
        self.assertEqual(self.commands,[])

    def test_granted_preflight_checks_stop_control_properties(self):
        self.advance();self.controller.granted_preflight()
        self.a.command=Mock(return_value='KillMode=process\nTimeoutStopUSec=10s\nRestart=no\nUser=pi-coordinator\nGroup=pi-coordinator')
        with self.assertRaises(Exception):self.controller.granted_preflight()

    def test_five_independent_default_no_human_prompts(self):
        for phase in c.PHASES:
            for answer in ['', '\n','yes\n','n\n']:
                with self.subTest(phase=phase,answer=answer),patch.object(c,'load',return_value=self.controller),\
                     patch.object(c.sys,'argv',['controller',phase,'a'*64]),patch.object(c.sys,'stdin',io.StringIO(answer)),\
                     patch.object(c.sys,'stderr',io.StringIO()) as output:
                    self.assertEqual(c.main(),3)
                    self.assertIn('Approve: ',output.getvalue());self.assertIn('\n\n<y/N> ',output.getvalue())
            self.assertFalse(self.root.exists())
        self.assertEqual(self.commands,[])

    def test_load_cannot_cross_noninteractive_or_nonroot_boundary(self):
        for uid,tty,sudo in [(1000,True,'1000'),(0,False,'1000'),(0,True,'999')]:
            with self.subTest(uid=uid,tty=tty,sudo=sudo),patch.object(c.os,'geteuid',return_value=uid),\
                 patch.object(c.sys.stdin,'isatty',return_value=tty),patch.dict(c.os.environ,{'SUDO_UID':sudo}),\
                 patch.object(c,'module') as imported:
                with self.assertRaises(Exception):c.load('a'*64)
                imported.assert_not_called()


def fixture_read_bytes(path, mode):
    s=path.lstat();c.require(stat.S_ISREG(s.st_mode) and s.st_nlink==1 and stat.S_IMODE(s.st_mode)==mode,'fixture-read-metadata')
    return path.read_bytes()


if __name__=='__main__':
    unittest.main()
