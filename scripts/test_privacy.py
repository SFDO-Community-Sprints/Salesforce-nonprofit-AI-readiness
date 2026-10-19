"""Deterministic output-boundary tests; all sensitive examples are fictional."""
import json
import unittest

from privacy import build_data_result


class PrivacyTests(unittest.TestCase):
    def setUp(self):
        self.metrics = dict(contacts=10, email_present=9, linked_contacts=10, repeated_email_rows=0)
        self.sentinel = 'FICTIONAL-SENSITIVE-donor@example.invalid'

    def assert_rejected(self, value, **kwargs):
        with self.assertRaises(ValueError) as caught:
            build_data_result(value, **kwargs)
        self.assertEqual(str(caught.exception), 'Invalid aggregate metrics')
        self.assertNotIn(self.sentinel, str(caught.exception))

    def test_exact_schema_rejects_raw_unclassified_and_nested_data(self):
        for value in [None, [], self.sentinel,
                      {**self.metrics, 'Email': self.sentinel},
                      {**self.metrics, 'notes': {'secret': self.sentinel}},
                      {**self.metrics, 'unclassified': self.sentinel},
                      {**self.metrics, 'contacts': {'raw': self.sentinel}},
                      {key: value for key, value in self.metrics.items() if key != 'contacts'}]:
            with self.subTest(value=value):
                self.assert_rejected(value)

    def test_count_types_and_consistency(self):
        for key in self.metrics:
            for value in [None, True, False, -1, 1.0, '10', self.sentinel]:
                with self.subTest(key=key, value=value):
                    self.assert_rejected({**self.metrics, key: value})
        for overrides in [dict(email_present=11), dict(linked_contacts=11),
                          dict(repeated_email_rows=9), dict(email_present=0, repeated_email_rows=1)]:
            self.assert_rejected({**self.metrics, **overrides})
        for value in [None, 1, 'true', self.sentinel]:
            self.assert_rejected(self.metrics, synthetic=value)

    def test_real_small_cohorts_suppress_counts_and_derived_checks(self):
        for count in range(5):
            result = build_data_result(dict(contacts=count, email_present=count,
                                           linked_contacts=count, repeated_email_rows=0))
            self.assertIsNone(result['metrics'])
            self.assertIsNone(result['data']['score'])
            self.assertTrue(result['privacy']['suppressed'])
            self.assertEqual(set(result['data']['checks'].values()), {'unknown'})
            self.assertEqual(result['data']['coverage'], '0.0')

    def test_synthetic_small_cohort_and_normal_aggregates(self):
        small = dict(contacts=4, email_present=1, linked_contacts=4, repeated_email_rows=0)
        result = build_data_result(small, synthetic=True)
        self.assertEqual(result['metrics'], small)
        self.assertFalse(result['privacy']['suppressed'])
        self.assertEqual(result['evidence_mode'], 'synthetic_simulation')
        result = build_data_result(self.metrics)
        self.assertEqual(result['data']['score'], '100.0')
        self.assertEqual(result, build_data_result(dict(reversed(list(self.metrics.items())))))
        self.assertNotIn(self.sentinel, json.dumps(result))
        self.assertEqual(self.metrics['contacts'], 10)
        boundary = dict(contacts=5, email_present=5, linked_contacts=5, repeated_email_rows=0)
        self.assertFalse(build_data_result(boundary)['privacy']['suppressed'])


if __name__ == '__main__':
    unittest.main()
