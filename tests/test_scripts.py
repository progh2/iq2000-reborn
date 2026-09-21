"""ROM/루트 권한/실제 openMSX 없이 실행하는 회귀 테스트."""
import json
import os
from pathlib import Path
import pwd
import signal
import subprocess
import tempfile
import time
import unittest

REPO = Path(__file__).resolve().parents[1]


class ScriptsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='iq2000-test-')
        self.root = Path(self.tmp.name)
        self.cart = self.root / '팩 with spaces'
        self.cart.mkdir()
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.log = self.root / 'calls.jsonl'
        self.env = os.environ | {
            'PATH': str(self.bin) + ':' + os.environ['PATH'],
            'MSX_CART_ROOT': str(self.cart), 'MSX_POLL': '1',
            'MSX_RESTART_DELAY': '1', 'XDG_CACHE_HOME': str(self.root),
            'AUDIT_LOG': str(self.log), 'MOCK_STAY': '0',
        }
        self.mock('openmsx', '''#!/usr/bin/env python3
import json, os, sys, time
with open(os.environ['AUDIT_LOG'], 'a') as f:
    f.write(json.dumps({'args': sys.argv[1:], 'pid': os.getpid(), 'time': time.monotonic()}) + '\\n')
if os.environ.get('MOCK_STAY') == '1':
    time.sleep(60)
''')
        self.processes = []

    def tearDown(self):
        for p in self.processes:
            if p.poll() is None:
                p.terminate()
            try:
                p.communicate(timeout=6)
            except subprocess.TimeoutExpired:
                os.killpg(p.pid, signal.SIGKILL)
                p.communicate()
        self.tmp.cleanup()

    def mock(self, name, content):
        path = self.bin / name
        path.write_text(content)
        path.chmod(0o755)

    def run_script(self, name, *args):
        return subprocess.run([str(REPO / 'scripts' / name), *args], env=self.env,
                              capture_output=True, text=True, timeout=5)

    def watch(self):
        p = subprocess.Popen([str(REPO / 'scripts/cart-watch.sh')], env=self.env,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             text=True, start_new_session=True)
        self.processes.append(p)
        return p

    def calls(self):
        return [json.loads(x) for x in self.log.read_text().splitlines()] if self.log.exists() else []

    def await_calls(self, count):
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            if len(self.calls()) >= count:
                return self.calls()
            time.sleep(.05)
        self.fail(f'Expected {count} launches, got {self.calls()}')

    def test_find_empty_and_only_root(self):
        nested = self.cart / 'nested'
        nested.mkdir()
        (nested / 'ignored.rom').touch()
        self.assertEqual(self.run_script('cart-find.sh').returncode, 1)

    def test_find_spaces_uppercase_and_ambiguity(self):
        rom = self.cart / '마성 전설.MX1'
        rom.touch()
        result = self.run_script('cart-find.sh')
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), str(rom))
        (self.cart / 'second.rom').touch()
        result = self.run_script('cart-find.sh')
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stdout, '')

    def test_newline_filename_rejected(self):
        (self.cart / 'bad\nname.rom').touch()
        self.assertEqual(self.run_script('cart-find.sh').returncode, 2)

    def test_missing_root_rejected(self):
        self.env['MSX_CART_ROOT'] = str(self.root / 'missing')
        self.assertEqual(self.run_script('cart-find.sh').returncode, 2)

    def test_default_discovery_filters_non_usb(self):
        self.env.pop('MSX_CART_ROOT')
        self.env['FIND_CALLED'] = str(self.root / 'unexpected-search')
        self.mock('findmnt', '#!/bin/sh\nprintf "/media/backup /dev/sda1\\n"\n')
        self.mock('lsblk', '#!/bin/sh\necho sata\n')
        self.mock('find', '#!/bin/sh\ntouch "$FIND_CALLED"\nexit 99\n')
        self.assertEqual(self.run_script('cart-find.sh').returncode, 1)
        self.assertFalse(Path(self.env['FIND_CALLED']).exists())

    def test_default_usb_path_decoding_and_duplicate_mount(self):
        self.env.pop('MSX_CART_ROOT')
        self.env['FIXTURE_ROM'] = str(self.cart / 'game.ROM')
        Path(self.env['FIXTURE_ROM']).touch()
        self.mock('findmnt', '#!/bin/sh\nprintf "%s\\n" "/media/USB\\x20PACK /dev/sda1" "/run/media/USB /dev/sda1"\n')
        self.mock('lsblk', '#!/bin/sh\necho usb\n')
        self.mock('find', """#!/usr/bin/env python3
import os, sys
assert sys.argv[1] in ('/media/USB PACK', '/run/media/USB'), sys.argv
sys.stdout.write(os.environ['FIXTURE_ROM'] + chr(0))
""")
        result = self.run_script('cart-find.sh')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), self.env['FIXTURE_ROM'])

    def test_label_preserves_spaces_and_quotes(self):
        self.mock('findmnt', "#!/bin/sh\nprintf '%s\\n' \"Kid's\\x20Game\"\n")
        result = self.run_script('cart-label.sh', 'game.rom')
        self.assertEqual(result.stdout.strip(), "Kid's Game")

    def test_system_install_stages_user_unit_without_enabling(self):
        if os.geteuid() == 0:
            self.skipTest('installer intentionally rejects root')
        self.env['STAGED_UNIT'] = str(self.root / 'unit.service')
        self.mock('sudo', """#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
with open(os.environ['AUDIT_LOG'], 'a') as f:
    f.write(json.dumps({'args': args}) + '\\n')
if args[0] == 'install' and args[-1].endswith('openmsx-cart.service'):
    pathlib.Path(os.environ['STAGED_UNIT']).write_text(pathlib.Path(args[-2]).read_text())
""")
        result = self.run_script('install.sh', '--system')
        self.assertEqual(result.returncode, 0, result.stderr)
        unit = Path(self.env['STAGED_UNIT']).read_text()
        self.assertIn('ExecStart="' + str(REPO / 'scripts/cart-watch.sh') + '"', unit)
        self.assertIn('User=' + pwd.getpwuid(os.getuid()).pw_name + '\n', unit)
        self.assertFalse(any('enable' in c['args'] or 'start' in c['args'] for c in self.calls()))

    def test_missing_rom_never_launches(self):
        self.assertEqual(self.run_script('msx-run.sh', str(self.cart / 'missing.rom')).returncode, 2)
        self.assertEqual(self.calls(), [])

    def test_rom_passed_as_one_argument(self):
        rom = self.cart / '한글 game.rom'
        rom.touch()
        self.assertEqual(self.run_script('msx-run.sh', str(rom)).returncode, 0)
        self.assertEqual(self.calls()[0]['args'], ['-machine', 'Daewoo_CPC-300', '-cart', str(rom)])

    def test_invalid_poll_rejected(self):
        for value in ('0', '-1', 'abc', '301', '01'):
            self.env['MSX_POLL'] = value
            self.assertEqual(self.run_script('cart-watch.sh').returncode, 2)
        self.assertEqual(self.calls(), [])

    def test_exit_restarts_with_delay(self):
        p = self.watch()
        calls = self.await_calls(2)
        self.assertIsNone(p.poll())
        self.assertGreaterEqual(calls[1]['time'] - calls[0]['time'], .9)

    def test_insert_remove_and_shutdown(self):
        self.env['MOCK_STAY'] = '1'
        p = self.watch()
        self.await_calls(1)
        rom = self.cart / 'game.rom'
        rom.touch()
        self.assertIn(str(rom), self.await_calls(2)[1]['args'])
        rom.unlink()
        calls = self.await_calls(3)
        self.assertNotIn('-cart', calls[2]['args'])
        p.terminate()
        p.communicate(timeout=5)
        for call in calls:
            with self.assertRaises(ProcessLookupError):
                os.kill(call['pid'], 0)

    def test_duplicate_watcher_rejected(self):
        self.env['MOCK_STAY'] = '1'
        self.watch()
        self.await_calls(1)
        result = self.run_script('cart-watch.sh')
        self.assertEqual(result.returncode, 1)
        self.assertIn('이미 실행 중', result.stderr)


if __name__ == '__main__':
    unittest.main()
