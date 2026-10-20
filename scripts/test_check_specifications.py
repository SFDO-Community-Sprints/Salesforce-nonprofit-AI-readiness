"""Keep the documented check catalog aligned with executable demo definitions."""
import json
import unittest

from demo import SPECIFICATION_VERSION, CRITICAL, PROFILE, ROOT, STAFF, TECH, THRESHOLDS, VERSION, data_checks
from privacy import MINIMUM_COHORT, build_data_result
from staff_readiness import KEY


SPEC = json.loads((ROOT / 'references/check-specifications.json').read_text())


class CheckSpecificationTests(unittest.TestCase):
    def test_native_resource_and_shared_snapshot_version_match_catalog(self):
        source = ROOT / 'references/check-specifications.json'
        resource = ROOT / 'force-app/main/default/staticresources/CheckSpecifications.resource'
        self.assertEqual(resource.read_bytes(), source.read_bytes())
        self.assertEqual(SPECIFICATION_VERSION, SPEC['version'])
        result = build_data_result(dict(contacts=10, email_present=10, linked_contacts=10, repeated_email_rows=0))
        self.assertEqual(result['specification_version'], SPEC['version'])
        self.assertEqual(result['profile_overrides'], {})

    def test_catalog_covers_rubric_exactly_with_stable_categories_and_gates(self):
        self.assertEqual(SPEC['rubric_version'], VERSION)
        checks = SPEC['checks']
        ids = [check['id'] for check in checks]
        expected = [key for category in PROFILE['categories'].values() for key in category['checks']]
        self.assertEqual(ids, expected)
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual({c['id'] for c in checks if c['critical_gate']}, CRITICAL)
        for check in checks:
            self.assertIn(check['id'], PROFILE['categories'][check['category']]['checks'])
            for field in ('applicability', 'severity', 'required_evidence', 'measurement', 'pass_criteria'):
                self.assertTrue(check[field], (check['id'], field))
            version = check['query_or_test_version']
            self.assertTrue(version['version'])
            for source in version['implementation'] + version['tests']:
                self.assertTrue((ROOT / source.split(':')[0]).is_file(), source)

    def test_data_thresholds_and_acceptance_agree_with_scorer(self):
        data = [c for c in SPEC['checks'] if c['category'] == 'data']
        for check in data:
            self.assertEqual(check['measurement']['threshold_value'], THRESHOLDS[check['measurement']['threshold_ref']])
        # At and across each acceptance boundary, including denominator changes.
        cases = [
            ({'contacts': 10, 'email_present': 9, 'linked_contacts': 10, 'repeated_email_rows': 0}, {'sufficient_data': 'pass', 'email_completeness': 'pass', 'account_linkage': 'pass', 'duplicate_indicator': 'pass'}),
            ({'contacts': 9, 'email_present': 8, 'linked_contacts': 8, 'repeated_email_rows': 1}, {'sufficient_data': 'fail', 'email_completeness': 'fail', 'account_linkage': 'fail', 'duplicate_indicator': 'fail'}),
        ]
        for metrics, expected in cases:
            self.assertEqual(data_checks(metrics), expected)
        self.assertEqual(SPEC['priority_rules'], PROFILE['priority'])
        for key, value in SPEC['data_priority_thresholds'].items():
            self.assertEqual(value, THRESHOLDS[key])

    def test_staff_actions_and_critical_markers_match_answer_key(self):
        staff = {c['id']: c for c in SPEC['checks'] if c['category'] == 'staff'}
        self.assertEqual(set(staff), set(STAFF))
        for question in KEY['questions']:
            measurement = staff[question['id']]['measurement']
            self.assertEqual(measurement['answer_key_version'], KEY['version'])
            self.assertEqual(measurement['required_action_ids'], [a['id'] for a in question['required_actions']])
            self.assertEqual(measurement['critical_failure_ids'], [a['id'] for a in question['critical_failures']])

    def test_live_controls_and_erasure_never_claim_completion(self):
        controls = [c for c in SPEC['checks'] if c['category'] == 'technical']
        self.assertEqual({c['id'] for c in controls}, set(TECH))
        for check in controls:
            self.assertEqual(check['measurement']['live_status'], 'unknown')
            self.assertEqual(check['measurement']['execution'], 'required_not_executed')
        self.assertFalse(SPEC['separate_privacy_erasure']['scored'])
        self.assertEqual(SPEC['separate_privacy_erasure']['decision'], 'not_assessed')
        self.assertNotIn('privacy', PROFILE['categories'])
        self.assertEqual(SPEC['privacy_precondition']['minimum_privacy_cohort'], MINIMUM_COHORT)
        metrics = dict(contacts=MINIMUM_COHORT - 1, email_present=MINIMUM_COHORT - 1,
                       linked_contacts=MINIMUM_COHORT - 1, repeated_email_rows=0)
        self.assertEqual(set(build_data_result(metrics)['data']['checks'].values()), {'unknown'})


if __name__ == '__main__':
    unittest.main()
