"""Own saved staff evidence crosses MCP only as recomputed canonical summaries."""
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
        with patch.object(mcp, 'STATE') as state, patch.object(mcp, 'verify'), patch.object(mcp, 'query') as query, patch.object(mcp, 'saved_staff_review', return_value=sanitized):
            state.read_text.return_value = '{"alias":"fictional"}'
            query.side_effect = [[{'contacts': 10, 'email_present': 10, 'linked_contacts': 10}], []]
            result = mcp.tool_call('readiness_check', {'scenario': 'organization'})
        self.assertEqual(result['decision'], 'not_ready')
        self.assertEqual(result['priorities'][0]['key'], 'staff_sensitive_data')
        self.assertEqual(result['priorities'][0]['priority'], 'Critical')
        self.assertNotIn('staff', [item['key'] for item in result['priorities']])
        self.assertEqual([item['key'] for item in result['priorities']], ['staff_sensitive_data', 'controls', 'privacy'])
        self.assertEqual([item['priority'] for item in result['priorities']], ['Critical', 'High', 'High'])
        self.assertNotIn(SENTINEL, json.dumps(result))
        self.assertIn('Technical safeguards remain unknown', result['technical_and_staff'])

    def test_saved_review_not_applied_to_demo_groups(self):
        with patch.object(mcp, 'STATE') as state, patch.object(mcp, 'verify'), patch.object(mcp, 'query') as query, patch.object(mcp, 'saved_staff_review') as staff:
            state.read_text.return_value = '{"alias":"fictional"}'
            query.side_effect = [[{'Id': '001000000000001AAA'}], [{'contacts': 10, 'email_present': 10, 'linked_contacts': 10}], []]
            result = mcp.tool_call('readiness_check', {'scenario': 'pilot'})
        staff.assert_not_called()
        self.assertNotIn('staff_review', result)


if __name__ == '__main__':
    unittest.main()
