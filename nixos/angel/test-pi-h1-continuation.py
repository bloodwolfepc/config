"""Continuation fixtures only. No actual root grant, unit, namespace or provider."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

# Reuse the existing inert transport/workspace fixture, never a host helper.
spec = importlib.util.spec_from_file_location('legacy_fixtures', Path(sys.argv.pop(2)))
legacy = importlib.util.module_from_spec(spec);spec.loader.exec_module(legacy)
h1 = legacy.h1
sha = lambda body: hashlib.sha256(body).hexdigest()


class Continuation(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name);self.f = legacy.Fixture(self.base)
        self.f.fail = 1
        with self.assertRaises(RuntimeError):self.f.run()
        self.root = self.f.state / 'h1-probe'
        self.original = {p.name:p.read_bytes() for p in self.root.iterdir()}
        held = json.loads(self.original['HELD.json'])
        self.descriptor = {'version':h1.CONTINUATION,'id':'0001','taskId':self.f.settings['taskId'],
                           'previousOwnerSha256':sha(self.original['owner.json']),
                           'previousHeldSha256':sha(self.original['HELD.json']),
                           'previousWriteOutputSha256':held['cases'][0]['outputSha256'],
                           'stateUUID':'11111111-1111-1111-1111-111111111111',
                           'workspaceUUID':'22222222-2222-2222-2222-222222222222'}
        self.desc = self.base/'descriptor';self.desc.write_text(json.dumps(self.descriptor,sort_keys=True))
        self.f.settings.update(continuation=str(self.desc),policy='fixture-policy')
        self.runtime = {'fixture':'component-hashes'}
        self.host = {'bootId':'33333333-3333-3333-3333-333333333333','stateDevice':7,'workspaceDevice':8}
        self.grant = {'version':h1.CONTINUATION,'id':'0001','authority':'one-synthetic-continuation-only',
                      'descriptorSha256':sha(self.desc.read_bytes()),'runtime':self.runtime,
                      'host':self.host|{'generation':'/nix/store/'+'a'*32+'-nixos-system-angel-26.11',
                                         'unitSha256':'a'*64,'reconciliationSha256':'b'*64,
                                         'stateUUID':self.descriptor['stateUUID'],'workspaceUUID':self.descriptor['workspaceUUID']},
                      'limits':dict(h1.LIMITS),'retainPrivateFailure':True}
        self.grant_path = self.root/'continuation-0001.grant.json';self.save_grant()
        self.original_root_reader = h1.root_grant
        reader = h1.read_record
        for name,value in [('immutable',lambda p:None),('runtime_binding',lambda s:self.runtime),
                           ('host_state',lambda s:self.host),('file_digest',lambda p:'a'*64),
                           ('root_grant',lambda p:reader(p,os.getuid(),0o440,os.getgid()))]:
            p=patch.object(h1,name,value);p.start();self.addCleanup(p.stop)
        self.f.fail=None;self.f.calls=[]
        call=self.f.call
        def transport(argv,body,pass_fds):
            code,raw=call(argv,body,pass_fds)
            if code==0 and argv[0]=='fixture-helper' and b'PI_H1_CONTINUATION_0001' in body:
                reply=json.loads(raw);reply['text']='PI_H1_CONTINUATION_0001\n';raw=json.dumps(reply).encode()
            return code,raw
        self.f.call=transport
    def save_grant(self):
        if self.grant_path.exists():self.grant_path.chmod(0o600)
        self.grant_path.write_text(json.dumps(self.grant,sort_keys=True));self.grant_path.chmod(0o440)
    def unchanged(self):
        for name,body in self.original.items():self.assertEqual((self.root/name).read_bytes(),body)
        self.assertFalse((self.root/'RESULT.json').exists())
    def refused(self):
        attempt=self.root/'continuation-0001.attempt.json'
        before=attempt.read_bytes() if attempt.exists() else None
        with self.assertRaises((ValueError,OSError,KeyError)):self.f.run()
        self.assertEqual(self.f.calls,[])
        self.assertEqual(attempt.read_bytes() if attempt.exists() else None,before)
    def test_success_appends_thirteen_cases_and_preserves_original_hold(self):
        result=self.f.run();self.unchanged()
        self.assertEqual(result['version'],h1.CONTINUATION);self.assertEqual(result['status'],'partial-h1')
        self.assertEqual(result['qualification'],'not-granted');self.assertEqual(len(self.f.calls),13)
        self.assertEqual(result['cases'][0]['name'],'startup-marker')
        self.assertEqual(result['cases'][1]['name'],'write')
        self.assertEqual(len(list(self.root.glob('continuation-0001.case-*.attempt.json'))),13)
        self.assertTrue((self.root/'continuation-0001.RESULT.json').exists())
        self.assertTrue((self.f.state/'journal/owner.json').exists())
        self.assertFalse((self.f.state/'admission.json').exists());self.assertFalse((self.f.state/'h1.json').exists())
        self.assertFalse(any('--run' in argv for argv,_,_ in self.f.calls))
    def test_startup_failure_prevents_write_and_keeps_private_bytes(self):
        self.f.fail=1;self.f.failure_output=b'SYNTHETIC-PRIVATE-STARTUP-ERROR\x00\xff'
        with self.assertRaises(RuntimeError):self.f.run()
        self.unchanged();self.assertEqual(len(self.f.calls),1);self.assertFalse((self.f.workspace/'h1-probe.txt').exists())
        failure=self.root/'continuation-0001.failure.bin';self.assertEqual(failure.read_bytes(),self.f.failure_output)
        self.assertEqual(failure.stat().st_mode&0o777,0o400)
        held=json.loads((self.root/'continuation-0001.HELD.json').read_bytes())
        self.assertEqual(held['phase'],'startup');self.assertTrue(held['privateFailure']['complete'])
        self.assertNotIn('SYNTHETIC-PRIVATE-STARTUP-ERROR',json.dumps(held))
        with self.assertRaises(ValueError):self.f.run()
        self.assertEqual(len(self.f.calls),1)
    def test_durable_case_and_run_attempt_exist_before_dispatch(self):
        call=self.f.call
        def checked(argv,body,pass_fds):
            self.assertTrue((self.root/'continuation-0001.attempt.json').exists())
            self.assertTrue((self.root/f'continuation-0001.case-{len(self.f.calls)+1:02d}.attempt.json').exists())
            return call(argv,body,pass_fds)
        self.f.call=checked;self.f.run()
    def test_missing_grant_refuses(self):self.grant_path.unlink();self.refused()
    def test_ordinary_user_cannot_issue_a_production_grant(self):
        if os.getuid()==0:self.skipTest('fixture needs unprivileged owner')
        with self.assertRaises(ValueError):self.original_root_reader(self.grant_path)
        self.assertEqual(self.f.calls,[])
    def test_grant_symlink_refuses(self):
        target=self.base/'grant';self.grant_path.rename(target);self.grant_path.symlink_to(target);self.refused()
    def test_grant_hardlink_refuses(self):os.link(self.grant_path,self.base/'alias');self.refused()
    def test_grant_writable_mode_refuses(self):self.grant_path.chmod(0o640);self.refused()
    def test_grant_oversized_refuses(self):
        self.grant_path.chmod(0o600);self.grant_path.write_bytes(b'x'*65537);self.grant_path.chmod(0o440);self.refused()
    def test_wrong_version_refuses(self):self.grant['version']='wrong';self.save_grant();self.refused()
    def test_wrong_id_refuses(self):self.grant['id']='0002';self.save_grant();self.refused()
    def test_model_authority_refuses(self):self.grant['authority']='model';self.save_grant();self.refused()
    def test_unknown_grant_field_refuses(self):self.grant['extra']=True;self.save_grant();self.refused()
    def test_wrong_descriptor_digest_refuses(self):self.grant['descriptorSha256']='0'*64;self.save_grant();self.refused()
    def test_wrong_runtime_refuses(self):self.grant['runtime']={};self.save_grant();self.refused()
    def test_capture_permission_missing_refuses(self):self.grant['retainPrivateFailure']=False;self.save_grant();self.refused()
    def test_changed_limits_refuses(self):self.grant['limits']['dispatches']=14;self.save_grant();self.refused()
    def test_float_limits_refuse(self):self.grant['limits']['dispatches']=13.0;self.save_grant();self.refused()
    def test_missing_journal_never_recreated_before_grant(self):
        journal=self.f.state/'journal';journal.rmdir();self.grant_path.unlink();self.refused()
        self.assertFalse(journal.exists())
    def test_wrong_boot_refuses(self):self.grant['host']['bootId']='different';self.save_grant();self.refused()
    def test_wrong_device_refuses(self):self.grant['host']['workspaceDevice']=9;self.save_grant();self.refused()
    def test_aliased_devices_refuse(self):self.host['workspaceDevice']=7;self.grant['host']['workspaceDevice']=7;self.save_grant();self.refused()
    def test_wrong_uuid_refuses(self):self.grant['host']['workspaceUUID']=self.descriptor['stateUUID'];self.save_grant();self.refused()
    def test_bad_generation_refuses(self):self.grant['host']['generation']='/tmp/not-a-system';self.save_grant();self.refused()
    def test_unbound_unit_refuses(self):self.grant['host']['unitSha256']='';self.save_grant();self.refused()
    def test_wrong_stored_unit_digest_refuses(self):self.grant['host']['unitSha256']='c'*64;self.save_grant();self.refused()
    def test_unbound_reconciliation_refuses(self):self.grant['host']['reconciliationSha256']='';self.save_grant();self.refused()
    def test_successful_original_result_refuses(self):(self.root/'RESULT.json').write_text('{}');self.refused()
    def test_unexpected_entry_refuses(self):(self.root/'retain-me').write_text('unknown');self.refused()
    def test_partial_attempt_refuses(self):(self.root/'continuation-0001.attempt.json').write_text('{}');self.refused()
    def test_successful_attempt_never_replays(self):
        self.f.run();count=len(self.f.calls)
        with self.assertRaises(ValueError):self.f.run()
        self.assertEqual(len(self.f.calls),count);self.unchanged()
    def test_journal_owner_never_replaced(self):
        p=self.f.state/'journal/owner.json';p.write_text('retain')
        self.refused();self.assertEqual(p.read_text(),'retain')
    def test_workspace_never_cleared(self):
        p=self.f.workspace/'unrelated';p.write_text('retain');self.refused();self.assertEqual(p.read_text(),'retain')
    def test_old_held_tampering_refuses(self):
        p=self.root/'HELD.json';p.chmod(0o600);p.write_text('{}');p.chmod(0o400);self.refused()
    def test_old_marker_tampering_refuses(self):
        p=self.root/'credential-marker.json';p.chmod(0o600);p.write_text('{}');p.chmod(0o400);self.refused()
    def test_transport_partial_bytes_are_private_and_incomplete(self):
        def broken(*args):
            e=TimeoutError('SYNTHETIC-PRIVATE-EXCEPTION');e.h1_private_output=b'SYNTHETIC-PARTIAL';raise e
        self.f.call=broken
        with self.assertRaises(RuntimeError):self.f.run()
        self.assertEqual((self.root/'continuation-0001.failure.bin').read_bytes(),b'SYNTHETIC-PARTIAL')
        held=json.loads((self.root/'continuation-0001.HELD.json').read_bytes())
        self.assertFalse(held['privateFailure']['complete']);self.assertNotIn('SYNTHETIC-PRIVATE',json.dumps(held));self.unchanged()
    def test_private_persistence_failure_holds_without_replay(self):
        self.f.fail=1
        with patch.object(h1,'private_failure',side_effect=OSError('fixture disk full')):
            with self.assertRaises(RuntimeError):self.f.run()
        held=json.loads((self.root/'continuation-0001.HELD.json').read_bytes())
        self.assertEqual(held['privateFailure']['persistence'],'failed-preserve-attempt-no-retry')
        with self.assertRaises(ValueError):self.f.run()
        self.assertEqual(len(self.f.calls),1)
    def test_result_persistence_failure_holds_original_data(self):
        exclusive=h1.exclusive
        def fail(path,value):
            if path.name=='continuation-0001.RESULT.json':raise OSError('fixture disk full')
            return exclusive(path,value)
        with patch.object(h1,'exclusive',side_effect=fail):
            with self.assertRaises(RuntimeError):self.f.run()
        self.unchanged();self.assertTrue((self.root/'continuation-0001.HELD.json').exists())
        held=json.loads((self.root/'continuation-0001.HELD.json').read_bytes())
        self.assertEqual(held['phase'],'receipt');self.assertEqual(held['privateFailure']['case'],'unsealed-report')
        self.assertEqual(held['privateFailure']['scope'],'last-captured-helper-output-not-cause-proof')
    def test_record_metadata_race_refuses(self):
        from types import SimpleNamespace
        before=self.grant_path.stat()
        after=SimpleNamespace(st_size=before.st_size,st_mtime_ns=before.st_mtime_ns,st_ctime_ns=before.st_ctime_ns+1)
        with patch.object(h1.os,'fstat',side_effect=[before,after]):
            with self.assertRaises(ValueError):h1.read_record(self.grant_path,os.getuid(),0o440)
        self.assertEqual(self.f.calls,[])
    def test_wrong_record_group_refuses(self):
        with self.assertRaises(ValueError):h1.read_record(self.grant_path,os.getuid(),0o440,os.getgid()+1)
    def test_case_attempt_failure_prevents_dispatch(self):
        original=h1.exclusive
        def fail(path,value):
            if '.case-' in path.name:raise OSError('fixture persistence failure')
            return original(path,value)
        with patch.object(h1,'exclusive',side_effect=fail):
            with self.assertRaises(RuntimeError):self.f.run()
        self.assertEqual(self.f.calls,[]);self.assertTrue((self.root/'continuation-0001.attempt.json').exists());self.unchanged()
    def test_malformed_reply_bytes_are_preserved_not_published(self):
        self.f.call=lambda *args:(0,b'{SYNTHETIC-PRIVATE-MALFORMED')
        with self.assertRaises(RuntimeError):self.f.run()
        self.assertEqual((self.root/'continuation-0001.failure.bin').read_bytes(),b'{SYNTHETIC-PRIVATE-MALFORMED')
        self.assertNotIn('SYNTHETIC-PRIVATE', (self.root/'continuation-0001.HELD.json').read_text());self.unchanged()
    def test_native_capture_overflow_keeps_bounded_prefix_on_exception(self):
        with self.assertRaises(ValueError) as caught:
            h1.invoke([sys.executable,'-I','-c',"print('x'*131073)"])
        self.assertEqual(len(caught.exception.h1_private_output),131072)
    def test_attempt_persistence_failure_prevents_dispatch(self):
        with patch.object(h1,'exclusive',side_effect=OSError('fixture disk full')):
            with self.assertRaises(OSError):self.f.run()
        self.assertEqual(self.f.calls,[]);self.unchanged()


if __name__=='__main__':unittest.main()
