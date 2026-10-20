import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import check_agentforce_action as action


TEXT = 'Data quality: 25%. Checks passed: 1 of 4. Checks completed: 4 of 4 (100%). Measured Contact count: 94'


def payload():
    return [{'actionName': 'Nonprofit_Readiness', 'isSuccess': True, 'errors': None,
             'outputValues': {'sessionId': 'fictional-session',
                              'agentResponse': json.dumps({'type': 'Text', 'value': TEXT})}}]


class PublishedActionTests(unittest.TestCase):
    def test_precise_response_and_measurement_checks(self):
        self.assertEqual(action.parse_response(payload())['response'], TEXT)
        self.assertTrue(all(action.response_checks(TEXT, []).values()))
        self.assertFalse(action.response_checks(TEXT.replace('25%', '50%'), [])['expected_demo_measurements'])
        self.assertFalse(action.response_checks(TEXT.replace('4 of 4', '3 of 4'), [])['expected_check_summary'])
        self.assertFalse(action.response_checks(TEXT, ['Contact count'])['seeded_personal_values_absent'])

    def test_unknown_failed_and_nontext_response_shapes_rejected(self):
        bad = [None, {}, [], [{'errors': ['FICTIONAL-CREDENTIAL']}]]
        for change in ({'isSuccess': False}, {'actionName': 'AnotherAction'}, {'errors': ['FICTIONAL-CREDENTIAL']},
                       {'outputValues': {'agentResponse': '{}'}},
                       {'outputValues': {'sessionId': 'fake', 'agentResponse': '{"type":"Other","value":"fake"}'}}):
            value = payload()
            value[0].update(change)
            bad.append(value)
        for value in bad:
            with self.subTest(value=value), self.assertRaises(ValueError) as error:
                action.parse_response(value)
            self.assertNotIn('FICTIONAL-CREDENTIAL', str(error.exception))

    def test_body_cleanup_success_failure_and_no_cli_error_disclosure(self):
        for fails in (False, True):
            paths = []
            def mocked_command(arguments, **kwargs):
                self.assertEqual(arguments[4], action.URL)
                self.assertNotIn('--json', arguments)
                path = Path(arguments[arguments.index('--body') + 1][1:])
                paths.append(path)
                self.assertEqual(json.loads(path.read_text()), {'inputs': [{'userMessage': 'fixed fictional prompt'}]})
                if fails:
                    raise subprocess.TimeoutExpired('sf', 1, stderr='FICTIONAL-CREDENTIAL')
                return subprocess.CompletedProcess(arguments, 0, json.dumps(payload()), '')
            with patch.object(action.subprocess, 'run', side_effect=mocked_command):
                if fails:
                    with self.assertRaises(RuntimeError) as error:
                        action.invoke('fictional-org', 'fixed fictional prompt')
                    self.assertNotIn('FICTIONAL-CREDENTIAL', str(error.exception))
                else:
                    self.assertEqual(action.invoke('fictional-org', 'fixed fictional prompt')['response'], TEXT)
            self.assertTrue(paths)
            self.assertTrue(all(not path.exists() for path in paths))

    def test_run_never_marks_refusals_or_trace_verified(self):
        with tempfile.TemporaryDirectory() as directory:
            result = action.run({'alias': 'fictional'}, lambda alias, prompt: {'response': TEXT, 'session_id': 'fake'},
                                lambda state: None, Path(directory) / 'result.json')
        self.assertEqual(result['cases'][0]['status'], 'pass')
        self.assertEqual(result['decision'], 'requires_manual_review')
        self.assertFalse(result['action_trace_verified'])
        self.assertTrue(all(case['status'] == 'requires_manual_review' for case in result['cases'][1:]))

    def test_repeated_rounds_are_counted_without_promoting_manual_checks(self):
        calls = []
        def execute(alias, prompt):
            calls.append(prompt)
            return {'response': TEXT, 'session_id': 'fictional-session-' + str(len(calls))}
        with tempfile.TemporaryDirectory() as directory:
            result = action.run({'alias': 'fictional'}, execute, lambda state: None,
                                Path(directory) / 'result.json', rounds=2)
        self.assertEqual(len(calls), 10)
        self.assertEqual(result['completed_rounds'], 2)
        self.assertEqual(result['expected_cases'], 10)
        self.assertEqual(result['summary'], {'completed_cases': 10, 'automated_passes': 2,
                                            'failed_cases': 0, 'manual_review_cases': 8})
        self.assertEqual([case['round'] for case in result['cases']], [1]*5 + [2]*5)
        self.assertEqual(result['decision'], 'requires_manual_review')
        self.assertFalse(result['action_trace_verified'])

    def test_invalid_rounds_rejected_before_access_and_partial_run_fails(self):
        execute = unittest.mock.Mock()
        validate = unittest.mock.Mock()
        for rounds in (0, 6, True, 1.0, '2'):
            with self.assertRaises(ValueError):
                action.run({'alias': 'fictional'}, execute, validate, rounds=rounds)
        execute.assert_not_called()
        validate.assert_not_called()
        execute.side_effect = [{'response': TEXT, 'session_id': 'fake'}, RuntimeError('FICTIONAL-CREDENTIAL')]
        with tempfile.TemporaryDirectory() as directory:
            result = action.run({'alias': 'fictional'}, execute, lambda state: None,
                                Path(directory) / 'result.json', rounds=2)
        self.assertEqual(result['completed_rounds'], 0)
        self.assertEqual(result['summary']['completed_cases'], 1)
        self.assertEqual(result['decision'], 'fail')
        self.assertNotIn('FICTIONAL-CREDENTIAL', json.dumps(result))

    def test_saved_staff_summary_must_be_reported_when_present(self):
        summary = 'Staff exercises: 0.0%. Checks passed: 0 of 7. Checks completed: 0.0% coverage. Scope: your saved exercises only; whole-team readiness is not established.'
        with tempfile.TemporaryDirectory() as directory:
            for text, expected in ((TEXT, 'fail'), (TEXT+' '+summary, 'pass')):
                result = action.run({'alias': 'fictional'}, lambda alias, prompt: {'response': text, 'session_id': 'fake'},
                    lambda state: None, Path(directory) / 'result.json', expected_staff_summary=summary)
                self.assertEqual(result['cases'][0]['status'], expected)


if __name__ == '__main__':
    unittest.main()
