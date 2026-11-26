"""Synthetic bytes and fake terminal/authority only; no private file or real TTY."""
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

SOURCE=Path(sys.argv.pop(1)) if len(sys.argv)>1 else Path(__file__).with_name('pi-h1-private-failure-display.py')
spec=importlib.util.spec_from_file_location('local_disclosure_fixture',SOURCE);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

class Terminal(unittest.TestCase):
    def test_control_bytes_unicode_and_invalid_utf8_are_escaped(self):
        body=(b'INERT_PRIVATE\x1b]52;c;fake\a\n\xff'+ 'bidi\u202e'.encode()).ljust(120,b'X')
        result=m.escaped(body);self.assertTrue(result.isascii())
        self.assertFalse(any(ord(ch)<32 for ch in result));self.assertNotIn('\x1b',result)
        self.assertIn('\\u001b',result);self.assertIn('\\u202e',result)

    def test_actual_sink_is_only_dev_tty_not_stdout_or_stderr(self):
        chunks=[]
        def write(fd,data):self.assertEqual(fd,55);chunks.append(data[:5]);return min(5,len(data))
        with patch.object(m.os,'open',return_value=55) as opened,patch.object(m.os,'close') as closed,\
             patch.object(m.os,'isatty',return_value=True),patch.object(m.os,'fstat',return_value=types.SimpleNamespace(st_mode=stat.S_IFCHR)),\
             patch.object(m.os,'write',side_effect=write),patch.object(m.sys,'stdout',io.StringIO()) as stdout,patch.object(m.sys,'stderr',io.StringIO()) as stderr:
            m.terminal_display(b'INERT_PRIVATE_TERMINAL_FIXTURE'.ljust(120,b'X'))
        opened.assert_called_once_with('/dev/tty',os.O_WRONLY|os.O_NOCTTY);closed.assert_called_once_with(55)
        self.assertEqual(stdout.getvalue(),'');self.assertEqual(stderr.getvalue(),'')
        self.assertIn(b'PRIVATE TERMINAL ONLY',b''.join(chunks));self.assertIn(b'INERT_PRIVATE_TERMINAL_FIXTURE',b''.join(chunks))

    def test_nonterminal_sink_refuses_without_write(self):
        with patch.object(m.os,'open',return_value=55),patch.object(m.os,'close') as closed,\
             patch.object(m.os,'isatty',return_value=False),patch.object(m.os,'fstat',return_value=types.SimpleNamespace(st_mode=stat.S_IFREG)),\
             patch.object(m.os,'write') as wrote:
            with self.assertRaises(Exception):m.terminal_display(b'X'*120)
        wrote.assert_not_called();closed.assert_called_once_with(55)

    def test_exact_type_and_length_only(self):
        for body in [b'X'*119,b'X'*121,'X'*120,bytearray(b'X'*120)]:
            with self.subTest(kind=type(body)),self.assertRaises(Exception):m.escaped(body)

class Protocol(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.root=Path(self.tmp.name)
        self.body=b'INERT_PRIVATE_LOCAL_DISPLAY'.ljust(120,b'X');self.failure=self.root/'private.bin';self.failure.write_bytes(self.body)
        self.owner=self.root/'owner.json';self.owner.write_bytes(b'{"fixture":"original-owner"}')
        self.held=self.root/'continuation-0001.HELD.json';self.held.write_bytes(b'{"fixture":"consumed-hold"}')
        self.prior=self.root/'failure-inspection-0001.done.json';self.prior.write_bytes(b'{"fixture":"prior-completed-inspection"}')
        self.p=types.SimpleNamespace(ROOT=self.root,PROBE=self.root,FAILURE=self.failure,FAILURE_SHA=m.sha(self.body),
            OWNER_SHA=m.sha(self.owner.read_bytes()),HELD_SHA=m.sha(self.held.read_bytes()),private_directory=Mock(),host=Mock(),failed_file=Mock())
        self.prior_patch=patch.object(m,'PRIOR_DONE_SHA',m.sha(self.prior.read_bytes()));self.prior_patch.start();self.addCleanup(self.prior_patch.stop)
        self.reads=[]
        def read(path,uid,maximum,private):
            if path==self.failure:self.assertTrue((self.root/(m.PREFIX+'attempt.json')).exists())
            self.reads.append(path);body=path.read_bytes();self.assertLessEqual(len(body),maximum);return body
        def write(path,value):
            with path.open('x') as f:json.dump(value,f)
            path.chmod(0o400)
        self.a=types.SimpleNamespace(file_bytes=read);self.c=types.SimpleNamespace(write=write)
        self.display=Mock()

    def disclose(self):return m.disclose(self.a,self.c,self.p,'a'*64,self.display)

    def test_separate_disclosure_preserves_completed_inspection_and_saves_metadata_only(self):
        prior=self.prior.read_bytes();owner=self.owner.read_bytes();held=self.held.read_bytes();result=self.disclose()
        self.display.assert_called_once_with(self.body);self.assertEqual(self.prior.read_bytes(),prior)
        self.assertEqual(self.owner.read_bytes(),owner);self.assertEqual(self.held.read_bytes(),held)
        self.assertNotIn('INERT_PRIVATE',json.dumps(result));self.assertFalse(result['rawSavedOrSentToAgent'])
        self.assertFalse(result['runtimeChanged']);self.assertEqual(result['qualification'],'not-granted')
        receipt=(self.root/(m.PREFIX+'done.json')).read_text();self.assertNotIn('INERT_PRIVATE',receipt)
        self.assertEqual(json.loads(receipt)['authority'],'one-terminal-only-escaped-disclosure')

    def test_disclosure_not_replayed(self):
        self.disclose()
        with self.assertRaises(Exception):self.disclose()
        self.assertEqual(self.reads.count(self.failure),1);self.display.assert_called_once()

    def test_prior_inspection_not_adopted_if_missing_or_changed(self):
        self.prior.write_bytes(b'changed')
        with self.assertRaises(Exception):self.disclose()
        self.display.assert_not_called();self.assertNotIn(self.failure,self.reads)
        self.assertFalse((self.root/(m.PREFIX+'attempt.json')).exists())

    def test_wrong_content_hash_is_held_before_display(self):
        self.failure.write_bytes(b'X'*120)
        with self.assertRaises(Exception):self.disclose()
        self.display.assert_not_called();self.assertTrue((self.root/(m.PREFIX+'HELD.json')).exists())
        with self.assertRaises(Exception):self.disclose()
        self.assertEqual(self.reads.count(self.failure),1)

    def test_partial_terminal_failure_is_consumed_without_saving_exception_or_bytes(self):
        self.display.side_effect=RuntimeError('INERT_PRIVATE_ERROR_DO_NOT_SAVE')
        with self.assertRaises(Exception):self.disclose()
        text=(self.root/(m.PREFIX+'HELD.json')).read_text();self.assertNotIn('INERT_PRIVATE',text)
        self.assertTrue(json.loads(text)['displayMayBePartial'])
        with self.assertRaises(Exception):self.disclose()
        self.display.assert_called_once()

    def test_post_display_host_uncertainty_does_not_claim_completion(self):
        self.p.host.side_effect=[None,RuntimeError('unknown')]
        with self.assertRaises(Exception):self.disclose()
        self.assertFalse((self.root/(m.PREFIX+'done.json')).exists());self.assertTrue((self.root/(m.PREFIX+'HELD.json')).exists())

    def test_default_no_does_not_open_content_or_terminal(self):
        self.p.FAILURE_SHA='a'*64
        for answer in ['', '\n','n\n','yes\n']:
            with self.subTest(answer=answer),patch.object(m,'load',return_value=(self.a,self.c,self.p)),\
                 patch.object(m.sys,'argv',['display','a'*64]),patch.object(m.sys,'stdin',io.StringIO(answer)),\
                 patch.object(m.sys,'stderr',io.StringIO()) as out:
                self.assertEqual(m.main(),3);self.assertIn('\n\n<y/N> ',out.getvalue())
        self.assertEqual(self.reads,[]);self.display.assert_not_called()

    def test_nonroot_nonterminal_guard_precedes_immutable_imports(self):
        for uid,tty,sudo in [(1000,True,'1000'),(0,False,'1000'),(0,True,'999')]:
            with self.subTest(uid=uid,tty=tty,sudo=sudo),patch.object(m.os,'geteuid',return_value=uid),\
                 patch.object(m.sys.stdin,'isatty',return_value=tty),patch.dict(m.os.environ,{'SUDO_UID':sudo}):
                with self.assertRaises(Exception):m.load('a'*64)
        self.assertEqual(self.reads,[])

if __name__=='__main__':unittest.main()
