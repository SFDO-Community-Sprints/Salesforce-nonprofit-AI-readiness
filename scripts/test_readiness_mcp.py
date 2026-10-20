"""Dedicated MCP role: fixed aggregate action, no administrator fallback or staff surface."""
import contextlib
import io
import json
import subprocess
from datetime import datetime
import unittest
from unittest.mock import patch

import readiness_mcp as mcp
from privacy import build_data_result

SENTINEL = 'FICTIONAL-SECRET-private-donor@example.invalid'
METRICS = dict(contacts=10, email_present=9, linked_contacts=8, repeated_email_rows=1)


def request(name='readiness_check', arguments=None):
    return {'jsonrpc': '2.0', 'id': 1, 'method': 'tools/call',
            'params': {'name': name, 'arguments': arguments if arguments is not None else {'scenario': 'pilot'}}}


def native_response(metrics=METRICS):
    value = build_data_result(metrics)
    value['decision'] = 'readiness_not_established'
    return subprocess.CompletedProcess([], 0, json.dumps([{'isSuccess': True, 'outputValues': {
        'output': json.dumps(value)}}]), '')


class McpTests(unittest.TestCase):
    def setUp(self):
        self.connection = patch.object(mcp, 'load_connection', return_value={'alias': 'dedicated'}).start()
        self.addCleanup(patch.stopall)

    def reject(self, req):
        stdout, stderr = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            result = mcp.dispatch(req)
        self.assertTrue(result['result']['isError'])
        for text in (json.dumps(result), stdout.getvalue(), stderr.getvalue()):
            self.assertNotIn(SENTINEL, text)
        return result

    def test_only_three_narrow_read_only_tools(self):
        tools = mcp.dispatch({'jsonrpc': '2.0', 'id': 1, 'method': 'tools/list'})['result']['tools']
        self.assertEqual({t['name'] for t in tools}, {'org_identity', 'readiness_check', 'org_capabilities'})
        for tool in tools:
            self.assertTrue(tool['annotations']['readOnlyHint'])
            self.assertFalse(tool['inputSchema']['additionalProperties'])
        for name in ('query', 'write', 'delete', SENTINEL):
            self.reject(request(name))
        self.connection.assert_not_called()

    def test_bad_arguments_rejected_before_access(self):
        for args in ([], SENTINEL, {'scenario': {'raw': SENTINEL}}, {'scenario': [SENTINEL]},
                     {'scenario': SENTINEL}, {'scenario': 'pilot', 'query': SENTINEL}, {'raw': SENTINEL}):
            self.reject(request(arguments=args))
        self.reject(request('org_identity', {'raw': SENTINEL}))
        self.reject(request('org_capabilities', {'raw': SENTINEL}))
        self.connection.assert_not_called()

    def test_missing_binding_and_native_failures_are_sanitized(self):
        self.connection.side_effect = RuntimeError(SENTINEL)
        with patch.object(mcp.subprocess, 'run') as run:
            self.reject(request())
            run.assert_not_called()
        self.connection.side_effect = None
        for value in (subprocess.CompletedProcess([], 1, SENTINEL, SENTINEL),
                      subprocess.CompletedProcess([], 0, SENTINEL, ''),
                      subprocess.CompletedProcess([], 0, '[]', '')):
            with patch.object(mcp.subprocess, 'run', return_value=value):
                self.reject(request())

    def test_assessment_uses_only_dedicated_fixed_action_and_recomputes_output(self):
        with patch.object(mcp.subprocess, 'run', return_value=native_response()) as run, patch.object(mcp, 'query') as query:
            result = mcp.dispatch(request(arguments={'scenario': 'organization'}))['result']
        self.assertFalse(result['isError'])
        value = result['structuredContent']
        self.assertEqual(value['metrics'], METRICS)
        self.assertEqual(json.loads(result['content'][0]['text']), value)
        self.assertEqual(value['scope'], 'sharing_scoped_organization_records')
        self.assertNotIn('staff_review', value)
        datetime.fromisoformat(value['collected_at'])
        args = run.call_args.args[0]
        self.assertIn('/services/data/v67.0/actions/custom/apex/ReadinessMCP', args)
        self.assertEqual(args[args.index('--target-org') + 1], 'dedicated')
        self.assertEqual(json.loads(args[args.index('--body') + 1]), {'inputs': [{'scenario': 'organization'}]})
        query.assert_not_called()

    def test_suppression_cannot_be_overridden_and_staff_is_rejected(self):
        with patch.object(mcp.subprocess, 'run', return_value=native_response(dict(contacts=4,email_present=4,linked_contacts=4,repeated_email_rows=0))):
            value = mcp.dispatch(request())['result']['structuredContent']
        self.assertIsNone(value['metrics'])
        self.assertIsNone(value['data']['score'])
        self.assertTrue(value['privacy']['suppressed'])
        response = native_response()
        outer = json.loads(response.stdout)
        native = json.loads(outer[0]['outputValues']['output'])
        native['staff_review'] = {'raw': SENTINEL}
        outer[0]['outputValues']['output'] = json.dumps(native)
        response.stdout = json.dumps(outer)
        with patch.object(mcp.subprocess, 'run', return_value=response):
            self.reject(request())

    def test_capabilities_only_product_labels_and_suppressed_counts(self):
        with patch.object(mcp, 'query') as query:
            query.side_effect = [[{'Name': 'Salesforce', 'TotalLicenses': 10, 'UsedLicenses': 2},
                                  {'Name': 'Einstein Unlimited', 'TotalLicenses': -1, 'UsedLicenses': 1}],
                                 [{'MasterLabel': 'Einstein Service', 'TotalLicenses': 20, 'UsedLicenses': 10}],
                                 [{'visible_records': 2}], [{'visible_records': 10}], RuntimeError(SENTINEL)]
            result = mcp.dispatch(request('org_capabilities', {}))['result']
            self.assertFalse(result['isError'])
            value = result['structuredContent']
            self.assertEqual(value['licenses'][0]['assigned'], 2)
            self.assertEqual(value['licenses'][0]['remaining'], 8)
            self.assertIsNone(value['licenses'][1]['total'])
            self.assertIsNone(value['licenses'][1]['remaining'])
            self.assertEqual(value['licenses'][1]['assigned'], 1)
            self.assertEqual(value['licenses'][2]['remaining'], 10)
            self.assertIsNone(value['capabilities'][0]['visibleRecords'])
            self.assertEqual(value['capabilities'][1]['visibleRecords'], 10)
            self.assertEqual(value['capabilities'][2]['availability'], 'unknown')
            self.assertTrue(all(v['usage'] == 'not_verified' for v in value['capabilities']))
            self.assertNotIn(SENTINEL, json.dumps(result))
            self.assertEqual(query.call_count, 5)

    def test_license_filter_explains_ai_relevance(self):
        included = ['Salesforce', 'Agentforce Employee', 'Einstein', 'Copilot', 'Prompt Builder',
                    'Data Cloud', 'Customer Data Platform', 'Digital Agent Fundraising']
        excluded = ['Chatter Free', 'Identity', 'Customer Portal', 'Health Cloud',
                    'Financial Services Cloud', 'CodeBuilder', 'Salesforce Platform']
        for name in included:
            self.assertIsInstance(mcp.license_relevance(name), str, name)
        for name in excluded:
            self.assertIsNone(mcp.license_relevance(name), name)
        self.assertIn('does not prove the feature is enabled', mcp.license_relevance('Digital Agent Fundraising'))
        with patch.object(mcp, 'query') as query:
            query.side_effect = [[{'Name': name, 'TotalLicenses': 10, 'UsedLicenses': 1}
                                  for name in included + excluded], [], [], [], []]
            result = mcp.org_capabilities({'alias': 'demo'})
            self.assertEqual([row['name'] for row in result['licenses']], included)
            self.assertTrue(all('relevance' in row for row in result['licenses']))

    def test_capabilities_reject_raw_fields_and_sanitize_section_errors(self):
        for row in ({'Name': SENTINEL, 'TotalLicenses': 10, 'UsedLicenses': 5},
                    {'Name': 'Salesforce', 'TotalLicenses': True, 'UsedLicenses': 0},
                    {'Name': 'Salesforce', 'TotalLicenses': 10, 'UsedLicenses': 5, 'Email': SENTINEL}):
            with patch.object(mcp, 'query') as query:
                query.side_effect = [[row], RuntimeError(SENTINEL), RuntimeError(SENTINEL), RuntimeError(SENTINEL), RuntimeError(SENTINEL)]
                result = mcp.dispatch(request('org_capabilities', {}))['result']['structuredContent']
                self.assertEqual(result['licenses'], [])
                self.assertEqual(result['sections']['user_licenses'], 'unavailable')
                self.assertNotIn(SENTINEL, json.dumps(result))

    def test_live_demo_records_inaccessible_cohorts_as_unknown(self):
        import run_demo
        import tempfile
        from pathlib import Path
        denied = {'result': {'isError': True}}
        # Denied cohorts are not evidence that the suppression exercise passed.
        with tempfile.TemporaryDirectory() as directory, patch.object(run_demo, 'exchange', side_effect=[[denied,denied],[denied]*5]), patch('builtins.print'):
            from shutil import copytree
            copytree(run_demo.ROOT/'demo',Path(directory)/'demo')
            with patch.object(run_demo, 'ROOT', Path(directory)):
                run_demo.main(True)
            report = json.loads((Path(directory)/'.local/mcp-demo-results.json').read_text())
        self.assertTrue(all(item['status'] == 'unknown' for item in report['live_mcp'].values()))
        self.assertEqual(report['privacy_checks']['small_cohort_suppression'], 'not_exercised')

    def test_malformed_protocol_and_input_stream(self):
        for value in (None, [], {'jsonrpc': '1.0', 'method': 'tools/list'},
                      {'jsonrpc': '2.0', 'method': {SENTINEL: 1}}):
            result = mcp.dispatch(value)
            self.assertEqual(result['error']['code'], -32600)
            self.assertNotIn(SENTINEL, json.dumps(result))
        stdout, stderr = io.StringIO(), io.StringIO()
        with patch.object(mcp.sys, 'stdin', io.StringIO('{'+SENTINEL+'\n')), contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            mcp.main()
        self.assertEqual(json.loads(stdout.getvalue())['error']['code'], -32700)
        self.assertNotIn(SENTINEL, stdout.getvalue() + stderr.getvalue())


if __name__ == '__main__':
    unittest.main()
