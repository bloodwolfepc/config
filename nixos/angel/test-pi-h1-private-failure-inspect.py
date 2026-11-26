"""Offline fixtures only; no original file, privileged read or authentication."""
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
from unittest.mock import Mock,patch

SOURCE=Path(sys.argv.pop(1)) if len(sys.argv)>1 else Path(__file__).with_name('pi-h1-private-failure-inspect.py')
spec=importlib.util.spec_from_file_location('inspection_fixture',SOURCE);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

class Classifier(unittest.TestCase):
    def test_all_public_message_classes_are_closed_labels(self):
        for stage,label in m.STAGES.items():
            for error,code in m.ERRORS.items():
                with self.subTest(stage=label,errno=code):
                    result=m.classify(b'bwrap: '+stage+b': '+error+b'\n')
                    self.assertEqual(result['messageClasses'],[{'stage':label,'reportedErrno':code}])
                    self.assertTrue(result['deniedSyscallAndPolicyNotProven']);self.assertFalse(result['rawContentExported'])

    def test_unknown_sensitive_text_never_leaves_classifier(self):
        secret=b'INERT_PRIVATE_CONTENT_NOT_FOR_EXPORT\x1b]52;c;not-real\a\n'
        result=m.classify(secret);text=json.dumps(result)
        self.assertEqual(result['messageClasses'],[]);self.assertNotIn('INERT_PRIVATE',text)
        self.assertNotIn('not-real',text);self.assertEqual(result['sha256'],m.sha(secret))
        self.assertFalse(result['runtimeChanged']);self.assertTrue(result['untrustedMessages'])

    def test_generic_line_is_not_a_denied_operation(self):
        result=m.classify(m.GENERIC+b'\n')
        self.assertTrue(result['genericHelperHeldSeen']);self.assertEqual(result['messageClasses'],[])
        self.assertEqual(result['status'],'no-known-message')

    def test_partial_or_embellished_messages_stay_unknown(self):
        for body in [b'prefix bwrap: Creating new namespace failed: Operation not permitted',
                     b'bwrap: Creating new namespace failed: Operation not permitted SECRET',
                     b'bwrap: Creating new namespace failed: Operation not permit',b'\x00\xff\x1b']:
            with self.subTest(body=body):self.assertEqual(m.classify(body)['messageClasses'],[])

    def test_size_and_type_caps(self):
        for body in [b'a'*121,'not bytes',bytearray(b'no')]:
            with self.subTest(kind=type(body)),self.assertRaises(Exception):m.classify(body)


class Protocol(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);root=Path(self.tmp.name)
        self.root=root/'observer';self.root.mkdir(mode=0o700);self.probe=root/'probe';self.probe.mkdir(mode=0o700)
        self.failure=self.probe/'continuation-0001.failure.bin'
        self.body=b'INERT_PRIVATE_VALUE_NOT_FOR_EXPORT'+b'X'*87
        self.body=self.body[:120].ljust(120,b'X');self.failure.write_bytes(self.body)
        self.owner=b'{"synthetic":"existing-observer-owner"}\n';(self.root/'owner.json').write_bytes(self.owner)
        held={'privateFailure':{'bytes':120,'sha256':m.sha(self.body),'case':'startup-marker','complete':True}}
        self.held=json.dumps(held).encode();(self.probe/'continuation-0001.HELD.json').write_bytes(self.held)
        for key,value in [('ROOT',self.root),('PROBE',self.probe),('FAILURE',self.failure),('OWNER_SHA',m.sha(self.owner)),
                          ('HELD_SHA',m.sha(self.held)),('FAILURE_SHA',m.sha(self.body))]:
            p=patch.object(m,key,value);p.start();self.addCleanup(p.stop)
        self.reads=[]
        def read(path,uid,maximum,private):
            self.reads.append(path)
            if path==self.failure:self.assertTrue((self.root/(m.PREFIX+'attempt.json')).exists())
            body=path.read_bytes();self.assertLessEqual(len(body),maximum);return body
        self.a=types.SimpleNamespace(file_bytes=read)
        def write(path,value):
            with path.open('x') as stream:json.dump(value,stream)
            path.chmod(0o400)
        self.c=types.SimpleNamespace(write=write)
        self.host_patch=patch.object(m,'host',return_value={'fixture':'failed-quiescent-unit'});self.host=self.host_patch.start();self.addCleanup(self.host_patch.stop)
        for name in ['private_directory','failed_file']:
            p=patch.object(m,name);p.start();self.addCleanup(p.stop)

    def inspect(self):return m.inspect(self.a,self.c,'a'*64)

    def test_attempt_precedes_read_and_only_labels_are_exported(self):
        result=self.inspect();self.assertEqual(result['status'],'no-known-message')
        self.assertEqual(self.reads.count(self.failure),1);self.assertEqual(self.failure.read_bytes(),self.body)
        self.assertEqual((self.root/'owner.json').read_bytes(),self.owner)
        receipt=(self.root/(m.PREFIX+'done.json')).read_text();self.assertNotIn('INERT_PRIVATE',receipt)
        self.assertFalse(json.loads(receipt)['rawExportAuthorized']);self.assertFalse(json.loads(receipt)['runtimeAuthority'])

    def test_consumed_inspection_never_reopens_content(self):
        self.inspect()
        with self.assertRaises(Exception):self.inspect()
        self.assertEqual(self.reads.count(self.failure),1)

    def test_partial_attempt_is_not_replayed(self):
        (self.root/(m.PREFIX+'attempt.json')).write_text('{}')
        with self.assertRaises(Exception):self.inspect()
        self.assertNotIn(self.failure,self.reads)

    def test_owner_drift_refuses_before_content(self):
        (self.root/'owner.json').write_text('{"changed":true}')
        with self.assertRaises(Exception):self.inspect()
        self.assertNotIn(self.failure,self.reads);self.assertFalse((self.root/(m.PREFIX+'attempt.json')).exists())

    def test_held_drift_refuses_before_content(self):
        (self.probe/'continuation-0001.HELD.json').write_text('{}')
        with self.assertRaises(Exception):self.inspect()
        self.assertNotIn(self.failure,self.reads)

    def test_hash_drift_after_consumption_is_held_not_disclosed(self):
        self.failure.write_bytes(b'OTHER_PRIVATE_VALUE'.ljust(120,b'X'))
        with self.assertRaises(Exception):self.inspect()
        self.assertTrue((self.root/(m.PREFIX+'HELD.json')).exists())
        self.assertFalse((self.root/(m.PREFIX+'done.json')).exists())
        self.assertNotIn('OTHER_PRIVATE',(self.root/(m.PREFIX+'HELD.json')).read_text())
        with self.assertRaises(Exception):self.inspect()
        self.assertEqual(self.reads.count(self.failure),1)

    def test_post_inspection_host_uncertainty_is_held(self):
        self.host.side_effect=[{},RuntimeError('INERT_PRIVATE_DO_NOT_LOG')]
        with self.assertRaises(Exception):self.inspect()
        self.assertTrue((self.root/(m.PREFIX+'HELD.json')).exists())
        self.assertNotIn('INERT_PRIVATE',(self.root/(m.PREFIX+'HELD.json')).read_text())

    def test_host_drift_cannot_open_content_or_consume_read_attempt(self):
        self.host.side_effect=RuntimeError('drift')
        with self.assertRaises(Exception):self.inspect()
        self.assertNotIn(self.failure,self.reads);self.assertFalse((self.root/(m.PREFIX+'attempt.json')).exists())

    def test_default_no_performs_no_private_reads(self):
        for answer in ['','\n','n\n','yes\n']:
            with self.subTest(answer=answer),patch.object(m,'load',return_value=(self.a,self.c)),\
                 patch.object(m.sys,'argv',['inspect','a'*64]),patch.object(m.sys,'stdin',io.StringIO(answer)),\
                 patch.object(m.sys,'stderr',io.StringIO()) as output:
                self.assertEqual(m.main(),3);self.assertIn('\n\n<y/N> ',output.getvalue())
        self.assertEqual(self.reads,[]);self.assertEqual(list(self.root.iterdir()),[self.root/'owner.json'])

    def test_nonroot_or_nonterminal_never_loads_library(self):
        for uid,tty,sudo in [(1000,True,'1000'),(0,False,'1000'),(0,True,'999')]:
            with self.subTest(uid=uid,tty=tty,sudo=sudo),patch.object(m.os,'geteuid',return_value=uid),\
                 patch.object(m.sys.stdin,'isatty',return_value=tty),patch.dict(m.os.environ,{'SUDO_UID':sudo}):
                with self.assertRaises(Exception):m.load('a'*64)
        self.assertEqual(self.reads,[])

    def test_production_fixed_file_guard_checks_each_authority_attribute(self):
        # Invoke the actual production function saved from source in a separate module.
        spec=importlib.util.spec_from_file_location('file_guard_only',SOURCE);real=importlib.util.module_from_spec(spec);spec.loader.exec_module(real)
        values={'st_mode':stat.S_IFREG|0o400,'st_uid':987,'st_gid':977,'st_nlink':1,'st_size':120,'st_dev':1792}
        path=Mock();path.lstat.return_value=types.SimpleNamespace(**values);real.failed_file(path,120)
        for key,value in [('st_mode',stat.S_IFLNK|0o400),('st_mode',stat.S_IFREG|0o600),('st_uid',1000),
                          ('st_gid',0),('st_nlink',2),('st_size',121),('st_dev',1793)]:
            path.lstat.return_value=types.SimpleNamespace(**(values|{key:value}))
            with self.subTest(key=key,value=value),self.assertRaises(Exception):real.failed_file(path,120)

if __name__=='__main__':unittest.main()
