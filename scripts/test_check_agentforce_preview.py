import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock

import check_agentforce_preview as preview


def trace():
    evidence = {'metrics': {'contacts': 94}, 'data': {'score': 25}}
    return {'detail': [{'action': 'assess_organization', 'input': '{"scenario":"organization"}',
                        'output': json.dumps({'__action_execution_status__': 'success',
                                              'output': json.dumps(evidence)})}]}


class PreviewTests(unittest.TestCase):
    def test_end_runs_after_send_failure_and_errors_are_sanitized(self):
        def execute(*args):
            if args[2] == 'start':
                return {'sessionId': 'fictional-session'}
            if args[2] == 'send':
                raise RuntimeError('FICTIONAL-CREDENTIAL-DO-NOT-ECHO')
            if args[1] == 'trace':
                return trace()
            return {}
        execute = Mock(side_effect=execute)
        with tempfile.TemporaryDirectory() as directory:
            result = preview.run({'alias': 'fictional'}, execute, lambda state: None, Path(directory) / 'result.json')
        self.assertTrue(result['session_ended'])
        self.assertEqual(result['decision'], 'fail')
        self.assertNotIn('FICTIONAL-CREDENTIAL', json.dumps(result))
        self.assertTrue(any(call.args[:3] == ('agent', 'preview', 'end') for call in execute.call_args_list))

    def test_measurement_mismatch_and_personal_values_fail(self):
        self.assertTrue(all(preview.check_response('Data score 25.0%; Contacts: 94', ['hidden']).values()))
        self.assertFalse(preview.check_response('Data score 50%; Contacts: 94', [])['expected_demo_measurements'])
        self.assertFalse(preview.check_response('Data score 25%; Contacts: 95', [])['expected_demo_measurements'])
        self.assertFalse(preview.check_response('SECRET-PERSON', ['secret-person'])['seeded_personal_values_absent'])

    def test_only_successful_fixed_action_with_actual_measurements_accepted(self):
        self.assertTrue(preview.check_actions(trace()))
        self.assertFalse(preview.check_actions({'detail': []}))
        for key, value in [('action', 'export_contacts'), ('input', '{"scenario":"pilot"}'), ('output', '{}')]:
            result = trace()
            result['detail'][0][key] = value
            self.assertFalse(preview.check_actions(result))


if __name__ == '__main__':
    unittest.main()
