"""Human action summaries are sanitized separately; dedicated MCP never reads staff evidence."""
import json
import subprocess
import unittest
from unittest.mock import patch

import readiness_mcp as mcp
from staff_readiness import KEY, evaluate, template

SENTINEL = 'FICTIONAL-sensitive-person@example.invalid'


def review_result(critical=False):
    snapshot = template()
    for item in snapshot['reviews']:
        item.update(answer='yes', reviewer_confirmed=True, evidence_ref='private_source_reference')
        item['actions'] = dict.fromkeys(item['actions'], 'yes')
    if critical:
        snapshot['reviews'][1]['critical_failures'] = [KEY['questions'][1]['critical_failures'][0]['id']]
    result = evaluate(snapshot)
    result['reviewed_at'] = '2026-10-19T12:00:00.000Z'
    return result


def response(review):
    return subprocess.CompletedProcess([], 0, json.dumps([{'isSuccess': True, 'outputValues': {
        'output': json.dumps({'staff_review': review, 'unapproved_raw': SENTINEL})}}]), '')


class StaffMcpTests(unittest.TestCase):
    def test_actual_review_recomputed_without_source_prose_or_refs(self):
        value = review_result()
        value['follow_up'] = [{'raw': SENTINEL}]
        value['limitation'] = SENTINEL
        with patch.object(mcp.subprocess, 'run', return_value=response(value)) as execute:
            actual = mcp.saved_staff_review({'alias': 'fictional'})
        self.assertEqual(actual['staff']['score'], '100.0')
        self.assertEqual(actual['follow_up'], [])
        self.assertNotIn(SENTINEL, json.dumps(actual))
        self.assertNotIn('private_source_reference', json.dumps(actual))
        args = execute.call_args.args[0]
        self.assertIn('/services/data/v67.0/actions/custom/apex/NonprofitAIReadiness', args)
        self.assertEqual(args[args.index('--body') + 1], '{"inputs":[{"scenario":"organization"}]}')

    def test_simulated_malformed_and_error_evidence_stays_unknown(self):
        values = [None]
        for fields in ({'evidence_mode': 'synthetic_simulation'}, {'version': 'unknown'},
                       {'reviewed_at': SENTINEL}, {'raw': SENTINEL},
                       {'critical_failures': [SENTINEL]}):
            value = review_result()
            value.update(fields)
            values.append(value)
        value = review_result()
        value['staff']['checks']['scope'] = SENTINEL
        values.append(value)
        for value in values:
            with self.subTest(value=value), patch.object(mcp.subprocess, 'run', return_value=response(value)):
                self.assertIsNone(mcp.saved_staff_review({'alias': 'fictional'}))
        with patch.object(mcp.subprocess, 'run', side_effect=RuntimeError(SENTINEL)):
            self.assertIsNone(mcp.saved_staff_review({'alias': 'fictional'}))

    def test_critical_review_drives_canonical_question_priority_and_decision(self):
        saved = review_result(critical=True)
        with patch.object(mcp.subprocess, 'run', return_value=response(saved)):
            sanitized = mcp.saved_staff_review({'alias': 'fictional'})
        self.assertEqual(sanitized['follow_up'][0]['priority'], 'Critical')
        self.assertEqual(sanitized['follow_up'][0]['question_id'], 'sensitive_data')
    def test_native_freshness_is_validated_and_sanitized(self):
        value = review_result(critical=True)
        value['freshness'] = {'scope': 'saved_review_reassessed_today', 'as_of': '2026-10-20',
                              'max_age_days': 90, 'checks': dict.fromkeys(value['staff']['checks'], 'current')}
        value['freshness']['checks']['sensitive_data'] = 'expired'
        with patch.object(mcp.subprocess, 'run', return_value=response(value)):
            actual = mcp.saved_staff_review({'alias': 'fictional'})
        self.assertEqual(actual['freshness'], value['freshness'])
        self.assertEqual(actual['staff']['checks']['sensitive_data'], 'fail')
        self.assertNotIn('private_source_reference', json.dumps(actual))
        for field, unsafe in [('as_of', '2026-02-30'), ('max_age_days', True),
                              ('scope', SENTINEL), ('observed_on', SENTINEL)]:
            broken = json.loads(json.dumps(value))
            broken['freshness'][field] = unsafe
            with self.subTest(field=field), patch.object(mcp.subprocess, 'run', return_value=response(broken)):
                self.assertIsNone(mcp.saved_staff_review({'alias': 'fictional'}))
        value['freshness']['checks']['scope'] = 'expired'
        with patch.object(mcp.subprocess, 'run', return_value=response(value)):
            self.assertIsNone(mcp.saved_staff_review({'alias': 'fictional'}), 'Expired evidence cannot retain a pass')
        value['staff']['checks']['scope'] = 'unknown'
        value['decision'] = 'blocked_by_observed_critical_failure'
        with patch.object(mcp.subprocess, 'run', return_value=response(value)):
            self.assertEqual(mcp.saved_staff_review({'alias': 'fictional'})['staff']['checks']['scope'], 'unknown')

    def test_dedicated_mcp_never_requests_human_staff_outcomes(self):
        from test_readiness_mcp import native_response
        with patch.object(mcp, 'load_connection', return_value={'alias': 'dedicated'}), patch.object(mcp.subprocess, 'run', return_value=native_response()), patch.object(mcp, 'saved_staff_review') as staff:
            result = mcp.tool_call('readiness_check', {'scenario': 'organization'})
        staff.assert_not_called()
        self.assertNotIn('staff_review', result)
        self.assertEqual(result['decision'], 'readiness_not_established')


if __name__ == '__main__':
    unittest.main()
