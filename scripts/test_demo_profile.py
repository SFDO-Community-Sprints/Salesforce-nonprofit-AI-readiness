"""The versioned profile drives scoring without changing established demo results."""
from copy import deepcopy
import unittest
from unittest.mock import patch

import demo


class ProfileTests(unittest.TestCase):
    def test_reject_invalid_profile_thresholds_and_gates(self):
        for mutate in (
            lambda p: p['thresholds'].update(email_completeness_pass_percent=101),
            lambda p: p['thresholds'].update(minimum_contacts=True),
            lambda p: p['thresholds'].update(minimum_privacy_cohort=11),
            lambda p: p['critical_gates'].append('unclassified_gate'),
            lambda p: p['categories']['data']['checks'].append('scope'),
        ):
            profile = deepcopy(demo.PROFILE)
            mutate(profile)
            with self.assertRaisesRegex(ValueError, 'Invalid readiness profile'):
                demo.validate_profile(profile)

    def test_numeric_profile_thresholds_drive_data_score(self):
        metrics = {'contacts': 10, 'email_present': 8, 'linked_contacts': 10, 'repeated_email_rows': 0}
        self.assertEqual(demo.data_checks(metrics)['email_completeness'], 'fail')
        thresholds = dict(demo.THRESHOLDS, email_completeness_pass_percent=80)
        with patch.object(demo, 'THRESHOLDS', thresholds):
            self.assertEqual(demo.data_checks(metrics)['email_completeness'], 'pass')

    def test_numeric_profile_thresholds_drive_priorities(self):
        metrics = {'contacts': 10, 'email_present': 4, 'linked_contacts': 10, 'repeated_email_rows': 0}
        def email_priority():
            return next(item['priority'] for item in demo.recommendations(metrics)
                        if item['key'] == 'email_completeness')
        self.assertEqual(email_priority(), 'High')
        with patch.object(demo, 'THRESHOLDS', dict(demo.THRESHOLDS, email_high_below_percent=40)):
            self.assertEqual(email_priority(), 'Medium')

    def test_profile_critical_gates_drive_known_failure(self):
        metrics = {'contacts': 10, 'email_present': 10, 'linked_contacts': 10, 'repeated_email_rows': 0}
        technical = dict.fromkeys(demo.TECH, 'pass')
        technical['export_block'] = 'fail'
        self.assertEqual(demo.recommendations(metrics, technical)[0]['priority'], 'Critical')
        with patch.object(demo, 'CRITICAL', demo.CRITICAL - {'export_block'}):
            self.assertEqual(demo.recommendations(metrics, technical)[0]['priority'], 'High')


if __name__ == '__main__':
    unittest.main()
