"""Optional failure seeds are scratch-only, additive, and repeat-safe."""
import contextlib
import io
import json
from pathlib import Path
import unittest
from unittest.mock import patch

import seed_failure_demo as seed


class FailureSeedTests(unittest.TestCase):
    def test_verify_before_any_seed_access(self):
        with patch.object(seed, 'verify', side_effect=RuntimeError('wrong org')), patch.object(seed, 'query') as query, patch.object(seed, 'sf') as sf:
            with self.assertRaises(RuntimeError):
                seed.seed({'alias': 'demo'})
            query.assert_not_called()
            sf.assert_not_called()

    def test_repeated_seed_is_noop(self):
        with patch.object(seed, 'verify'), patch.object(seed, 'query', return_value=[{'LastName': name} for name in seed.NAMES]), patch.object(seed, 'sf') as sf, contextlib.redirect_stdout(io.StringIO()):
            seed.seed({'alias': 'demo'})
            sf.assert_not_called()

    def test_incomplete_or_duplicate_seed_rejected(self):
        for rows in ([{'LastName': next(iter(seed.NAMES))}], [{'LastName': next(iter(seed.NAMES))}] * 60):
            with patch.object(seed, 'verify'), patch.object(seed, 'query', return_value=rows), patch.object(seed, 'sf') as sf:
                with self.assertRaises(RuntimeError):
                    seed.seed({'alias': 'demo'})
                sf.assert_not_called()

    def test_seed_imports_only_fixed_fictional_contacts(self):
        def inspect_import(*args):
            self.assertEqual(args[:3], ('data', 'import', 'tree'))
            records = json.loads(Path(args[args.index('--files') + 1]).read_text())['records']
            self.assertEqual(len(records), 60)
            self.assertEqual({row['LastName'] for row in records}, seed.NAMES)
            self.assertTrue(all('AccountId' not in row for row in records))
            self.assertEqual(sum('Email' in row for row in records), 10)
            self.assertEqual({row['Email'] for row in records if 'Email' in row}, {'synthetic-failure-demo@example.invalid'})
        with patch.object(seed, 'verify'), patch.object(seed, 'query', return_value=[]), patch.object(seed, 'sf', side_effect=inspect_import) as sf, contextlib.redirect_stdout(io.StringIO()):
            seed.seed({'alias': 'demo'})
            sf.assert_called_once()


if __name__ == '__main__':
    unittest.main()
