"""Regression coverage for the Makefile's host/device test runner."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class TestMakeTest(unittest.TestCase):
    def run_tests(self, runner, failing=False, device='host'):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'tests' / '.packages').mkdir(parents=True)
            (root / 'tests' / 'first.test.toit').touch()
            (root / 'tests' / 'with space_test.toit').touch()
            (root / 'tests' / '.packages' / 'ignored.test.toit').touch()
            (root / 'bin').mkdir()
            for tool in ('sh', 'find'):
                (root / 'bin' / tool).symlink_to(shutil.which(tool))
            stub = root / 'bin' / runner
            stub.write_text(
                '#!' + shutil.which('python3') + '\n'
                'import json, os, sys\n'
                'with open(os.environ["CALLS"], "a") as f:\n'
                '    f.write(json.dumps(sys.argv[1:]) + "\\n")\n'
                'sys.exit(1 if os.environ["FAIL"] == "1" and '
                'sys.argv[-1].endswith("first.test.toit") else 0)\n'
            )
            stub.chmod(0o755)
            env = dict(os.environ, PATH=str(root / 'bin'), DEVICE=device,
                       CALLS=str(root / 'calls'), FAIL=str(int(failing)))
            result = subprocess.run(
                [shutil.which('make'), '-f', str(Path(__file__).resolve().parents[1] / 'Makefile'),
                 '-o', 'install-tests', 'test'], cwd=root, env=env,
                capture_output=True, text=True,
            )
            calls = [json.loads(line) for line in (root / 'calls').read_text().splitlines()] if (root / 'calls').exists() else []
            return result, calls

    def test_host_runners_and_failure_propagation(self):
        for runner, prefix in [('jag', ['run', '--device', 'host']),
                               ('toit.run', []), ('toit', ['run'])]:
            for failing in (False, True):
                with self.subTest(runner=runner, failing=failing):
                    result, calls = self.run_tests(runner, failing)
                    self.assertEqual(result.returncode != 0, failing, result.stdout + result.stderr)
                    self.assertEqual(len(calls), 2)
                    self.assertEqual({call[-1] for call in calls},
                                     {'tests/first.test.toit', 'tests/with space_test.toit'})
                    for call in calls:
                        self.assertEqual(call[:-1], prefix)

    def test_device_requires_jag(self):
        for runner in ('toit.run', 'toit'):
            result, calls = self.run_tests(runner, device='my-device')
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('requires', result.stdout)
            self.assertEqual(calls, [])
        result, calls = self.run_tests('jag', device='my device')
        self.assertEqual(result.returncode, 0)
        self.assertTrue(all(call[:-1] == ['run', '--device', 'my device'] for call in calls))


if __name__ == '__main__':
    unittest.main()
