"""Corrections stay within the fictional seed and always restore after errors."""
import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import check_data_improvement as exercise


def contacts():
    return [{'Id': f'003{number:012d}', 'LastName': f'{exercise.PREFIX}{number:02d}',
             'Email': 'synthetic-failure-demo@example.invalid' if number <= 10 else None,
             'AccountId': None} for number in range(1, 61)]

BASELINE = {'metrics': {'contacts': 94, 'email_present': 39, 'linked_contacts': 34, 'repeated_email_rows': 10}, 'score': '25.0'}
IMPROVED = {'metrics': {'contacts': 94, 'email_present': 89, 'linked_contacts': 94, 'repeated_email_rows': 1}, 'score': '75.0'}
STATE = {'alias': 'demo', 'org_id': 'scratch'}


class ImprovementTests(unittest.TestCase):
    def test_drift_rejected_before_writes(self):
        rows = contacts()
        rows[0]['Email'] = 'other@example.invalid'
        with patch.object(exercise, 'verify'), patch.object(exercise, 'query', return_value=rows), patch.object(exercise, 'patch_contacts') as update, tempfile.TemporaryDirectory() as directory, patch.object(exercise, 'RECOVERY', Path(directory) / 'recovery.json'):
            with self.assertRaisesRegex(RuntimeError, 'drift'):
                exercise.run(STATE)
            update.assert_not_called()

    def execute(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        recovery = Path(directory.name) / 'recovery.json'
        report = Path(directory.name) / 'report.json'
        query_results = [contacts(), [{'Id': '001000000000001'}], [{'n': 0}], contacts()]
        return directory, recovery, report, query_results

    def test_score_improves_and_restores(self):
        directory, recovery, report, results = self.execute()
        def update(state, records):
            self.assertTrue(recovery.exists(), 'Recovery must precede any write')
        with patch.object(exercise, 'verify'), patch.object(exercise, 'query', side_effect=results), patch.object(exercise, 'snapshot', side_effect=[BASELINE, IMPROVED, BASELINE]), patch.object(exercise, 'patch_contacts', side_effect=update) as update_mock, patch.object(exercise, 'RECOVERY', recovery), patch.object(exercise, 'REPORT', report), contextlib.redirect_stdout(io.StringIO()):
            result = exercise.run(STATE)
            self.assertEqual(result['improved']['score'], '75.0')
            self.assertEqual(update_mock.call_count, 2)
            self.assertEqual(json.loads(recovery.read_text())['status'], 'restored')
            self.assertTrue(report.exists())

    def test_failed_improvement_still_restores(self):
        directory, recovery, report, results = self.execute()
        with patch.object(exercise, 'verify'), patch.object(exercise, 'query', side_effect=results), patch.object(exercise, 'snapshot', side_effect=[BASELINE, BASELINE, BASELINE]), patch.object(exercise, 'patch_contacts') as update, patch.object(exercise, 'RECOVERY', recovery), patch.object(exercise, 'REPORT', report):
            with self.assertRaisesRegex(RuntimeError, 'score increase'):
                exercise.run(STATE)
            self.assertEqual(update.call_count, 2)
            self.assertEqual(json.loads(recovery.read_text())['status'], 'restored')
            self.assertFalse(report.exists())

    def test_failed_restoration_keeps_recovery_and_is_loud(self):
        directory, recovery, report, results = self.execute()
        with patch.object(exercise, 'verify'), patch.object(exercise, 'query', side_effect=results), patch.object(exercise, 'snapshot', side_effect=[BASELINE, IMPROVED]), patch.object(exercise, 'patch_contacts', side_effect=[None, RuntimeError('failed')]), patch.object(exercise, 'RECOVERY', recovery), patch.object(exercise, 'REPORT', report):
            with self.assertRaisesRegex(RuntimeError, 'RESTORATION NOT CONFIRMED'):
                exercise.run(STATE)
            self.assertEqual(json.loads(recovery.read_text())['status'], 'pending')
            self.assertFalse(report.exists())

    def test_recovery_cannot_write_other_org_or_records(self):
        with patch.object(exercise, 'verify'), patch.object(exercise, 'patch_contacts') as update:
            with self.assertRaisesRegex(RuntimeError, 'another scratch'):
                exercise.restore(STATE, {'org_id': 'other', 'status': 'pending', 'originals': [], 'baseline': BASELINE})
            with patch.object(exercise, 'query', return_value=contacts()):
                with self.assertRaisesRegex(RuntimeError, 'payload'):
                    exercise.restore(STATE, {'org_id': 'scratch', 'status': 'pending', 'originals': [], 'baseline': BASELINE})
            update.assert_not_called()

    def test_rebound_recovery_identifier_rejected(self):
        originals = [{'attributes': {'type': 'Contact'}, 'Id': row['Id'], 'Email': row['Email'], 'AccountId': None} for row in contacts()]
        originals[0]['Id'] = '003999999999999'
        with patch.object(exercise, 'verify'), patch.object(exercise, 'query', return_value=contacts()), patch.object(exercise, 'patch_contacts') as update:
            with self.assertRaisesRegex(RuntimeError, 'payload'):
                exercise.restore(STATE, {'org_id': 'scratch', 'status': 'pending', 'originals': originals, 'baseline': BASELINE})
            update.assert_not_called()

    def test_atomic_transport_requires_every_record_success(self):
        from types import SimpleNamespace
        def command(args, **kwargs):
            self.assertIn('/services/data/v67.0/composite/sobjects', args)
            payload = json.loads(Path(args[args.index('--body') + 1][1:]).read_text())
            self.assertTrue(payload['allOrNone'])
            return SimpleNamespace(returncode=0, stdout=json.dumps([{'success': False}]))
        with patch.object(exercise.subprocess, 'run', side_effect=command):
            with self.assertRaisesRegex(RuntimeError, 'did not confirm'):
                exercise.patch_contacts(STATE, [{'Id': '003000000000001'}])


if __name__ == '__main__':
    unittest.main()
