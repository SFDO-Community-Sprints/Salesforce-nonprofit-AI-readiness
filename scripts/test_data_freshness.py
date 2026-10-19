from copy import deepcopy
import unittest
from data_freshness import evaluate


class FreshnessTests(unittest.TestCase):
    def setUp(self):
        self.snapshot = {'version': 'data-freshness-v1', 'as_of': '2026-10-19T00:00:00Z',
            'policy': {'version': 'example-v1', 'window_days': 90, 'minimum_recent_percent': 90, 'minimum_cohort': 5},
            'metrics': {'records': 10, 'recent_records': 9, 'window_days': 90, 'as_of': '2026-10-19T00:00:00Z'}}

    def test_boundary_replay_and_fail(self):
        result = evaluate(self.snapshot)
        self.assertEqual(result['freshness']['score'], '100.0')
        self.assertEqual(result, evaluate(deepcopy(self.snapshot)))
        self.snapshot['metrics']['recent_records'] = 8
        self.assertEqual(evaluate(self.snapshot)['freshness']['checks']['freshness'], 'fail')
        self.assertEqual(result['decision'], 'readiness_not_established')

    def test_unknown_and_suppression(self):
        for metrics in (None, {'records': 0, 'recent_records': 0, 'window_days': 90, 'as_of': self.snapshot['as_of']},
                        {'records': 4, 'recent_records': 4, 'window_days': 90, 'as_of': self.snapshot['as_of']}):
            self.snapshot['metrics'] = metrics
            result = evaluate(self.snapshot)
            self.assertIsNone(result['metrics'])
            self.assertEqual(result['freshness']['coverage'], '0.0')
            self.assertEqual(result['freshness']['checks']['freshness'], 'unknown')

    def test_reject_mismatched_or_unsafe_evidence(self):
        for key, value in [('window_days', 30), ('as_of', '2026-10-18T00:00:00Z'),
                           ('as_of', '2026-10-19'), ('recent_records', 11), ('records', True),
                           ('email', 'fictional@example.invalid')]:
            snapshot = deepcopy(self.snapshot)
            snapshot['metrics'][key] = value
            with self.assertRaises(ValueError):
                evaluate(snapshot)
        for key, value in [('minimum_cohort', 0), ('window_days', True), ('minimum_recent_percent', 101),
                           ('version', 'fictional@example.invalid')]:
            snapshot = deepcopy(self.snapshot)
            snapshot['policy'][key] = value
            with self.assertRaises(ValueError):
                evaluate(snapshot)
