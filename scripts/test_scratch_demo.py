"""Checks for safeguards that must not depend on a Salesforce connection."""
import unittest
from unittest.mock import patch

import scratch_demo as live
from demo import data_checks


class DemoSafetyTests(unittest.TestCase):
    def test_wrong_org_is_rejected_before_hub_query(self):
        with patch.object(live, 'query', return_value=[{'Id':'other','IsSandbox':True}]) as query:
            with self.assertRaises(RuntimeError):
                live.verify({'alias':'demo','org_id':'expected','hub':'hub'})
            self.assertEqual(query.call_count, 1)

    def test_sandbox_without_active_scratch_provenance_is_rejected(self):
        with patch.object(live, 'query', side_effect=[[{'Id':'expected','IsSandbox':True}], []]):
            with self.assertRaises(RuntimeError):
                live.verify({'alias':'demo','org_id':'expected','hub':'hub'})

    def test_repeat_install_does_not_reassign_existing_permission(self):
        with patch.object(live, 'verify'), patch.object(live, 'sf') as command, patch.object(live, 'query', return_value=[{'Id':'assigned'}]):
            command.side_effect = [dict(success=True, details={'runTestResult':{'numTestsRun':10}}), {'username':'demo@example.invalid'}]
            with patch('builtins.print'):
                live.deploy({'alias':'demo'})
            self.assertEqual(command.call_count, 2)

    def test_unlinked_contacts_fail_relationship_check(self):
        result = data_checks({'contacts':10,'email_present':10,'linked_contacts':9,'repeated_email_rows':0})
        self.assertEqual(result['account_linkage'], 'fail')


if __name__ == '__main__':
    unittest.main()
