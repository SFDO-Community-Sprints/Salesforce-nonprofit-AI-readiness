import unittest
from unittest.mock import patch
from collect_data_freshness import collect


class CollectionTests(unittest.TestCase):
    def setUp(self):
        self.policy = {'version': 'example-v1', 'window_days': 90,
                       'minimum_recent_percent': 90, 'minimum_cohort': 5}
        self.stamp = '2026-10-19T00:00:00Z'

    @patch('collect_data_freshness.verify')
    @patch('collect_data_freshness.query')
    def test_fixed_queries_and_scope(self, query, verify):
        query.side_effect = [[{'records': 10}], [{'recent_records': 9}]]
        result = collect({'alias': 'bound'}, self.policy, self.stamp)
        verify.assert_called_once_with({'alias': 'bound'})
        self.assertEqual(query.call_args_list[1].args, ('bound',
            'SELECT COUNT(Id) recent_records FROM Contact WHERE LastActivityDate >= 2026-07-21 AND LastActivityDate <= 2026-10-19'))
        self.assertEqual(result['freshness']['checks']['freshness'], 'pass')
        self.assertEqual(result['scope'], 'accessible_organization_contacts')
        self.assertEqual(result['decision'], 'readiness_not_established')

    @patch('collect_data_freshness.verify')
    @patch('collect_data_freshness.query')
    def test_reject_before_access(self, query, verify):
        for stamp in ('2026-10-19T01:00:00Z', '2100-01-01T00:00:00Z', 'invalid'):
            with self.assertRaises(ValueError):
                collect({'alias': 'bound'}, self.policy, stamp)
        with self.assertRaises(ValueError):
            collect({'alias': 'bound'}, dict(self.policy, window_days='90 OR Name != null'), self.stamp)
        query.assert_not_called()
        verify.assert_not_called()

    @patch('collect_data_freshness.verify')
    @patch('collect_data_freshness.query')
    def test_suppression_and_invalid_output(self, query, verify):
        query.side_effect = [[{'records': 4}], [{'recent_records': 4}]]
        self.assertIsNone(collect({'alias': 'bound'}, self.policy, self.stamp)['metrics'])
        query.side_effect = [[{'records': 10, 'Email': 'fictional@example.invalid'}], [{'recent_records': 9}]]
        with self.assertRaises(ValueError):
            collect({'alias': 'bound'}, self.policy, self.stamp)
        verify.side_effect = RuntimeError('Wrong org')
        query.reset_mock()
        with self.assertRaises(RuntimeError):
            collect({'alias': 'wrong'}, self.policy, self.stamp)
        query.assert_not_called()
