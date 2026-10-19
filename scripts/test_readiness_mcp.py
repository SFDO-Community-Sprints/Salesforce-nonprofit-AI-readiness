"""Mocked MCP boundary tests: no Salesforce access or private records required."""
import contextlib
import io
import json
from datetime import datetime
import unittest
from unittest.mock import patch

import readiness_mcp as mcp

SENTINEL = 'FICTIONAL-SECRET-private-donor@example.invalid'


def request(name='readiness_check', arguments=None):
    return {'jsonrpc': '2.0', 'id': 1, 'method': 'tools/call',
            'params': {'name': name, 'arguments': arguments if arguments is not None else {'scenario': 'pilot'}}}


class McpTests(unittest.TestCase):
    def setUp(self):
        self.staff_patch = patch.object(mcp, 'saved_staff_review', return_value=None)
        self.staff_patch.start()
        self.addCleanup(self.staff_patch.stop)

    def reject(self, req):
        stdout, stderr = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            result = mcp.dispatch(req)
        self.assertTrue(result['result']['isError'])
        for text in (json.dumps(result), stdout.getvalue(), stderr.getvalue()):
            self.assertNotIn(SENTINEL, text)
        return result

    def test_only_three_narrow_read_only_tools(self):
        result = mcp.dispatch({'jsonrpc': '2.0', 'id': 1, 'method': 'tools/list'})
        tools = result['result']['tools']
        self.assertEqual({t['name'] for t in tools}, {'org_identity', 'readiness_check', 'org_capabilities'})
        for tool in tools:
            self.assertTrue(tool['annotations']['readOnlyHint'])
            self.assertFalse(tool['inputSchema']['additionalProperties'])
        with patch.object(mcp, 'verify') as verify, patch.object(mcp, 'query') as query:
            for tool in ('query', 'write', 'delete', SENTINEL):
                self.reject(request(tool))
            verify.assert_not_called()
            query.assert_not_called()

    def test_bad_arguments_rejected_before_access(self):
        with patch.object(mcp, 'verify') as verify, patch.object(mcp, 'query') as query:
            for args in ([], SENTINEL, {'scenario': {'raw': SENTINEL}},
                         {'scenario': [SENTINEL]}, {'scenario': SENTINEL},
                         {'scenario': 'pilot', 'query': SENTINEL}, {'raw': SENTINEL}):
                self.reject(request(arguments=args))
            self.reject(request('org_identity', {'raw': SENTINEL}))
            self.reject(request('org_capabilities', {'raw': SENTINEL}))
            verify.assert_not_called()
            query.assert_not_called()

    def test_exception_and_state_failure_sanitized(self):
        for failing_stage in ('state', 'verify', 'query'):
            with patch.object(mcp, 'STATE') as state, patch.object(mcp, 'verify') as verify, patch.object(mcp, 'query') as query:
                state.read_text.return_value = json.dumps({'alias': 'demo'})
                target = {'state': state.read_text, 'verify': verify, 'query': query}[failing_stage]
                target.side_effect = RuntimeError(SENTINEL)
                self.reject(request())

    def test_success_is_structured_aggregate_without_raw_values(self):
        with patch.object(mcp, 'STATE') as state, patch.object(mcp, 'verify'), patch.object(mcp, 'query') as query:
            state.read_text.return_value = json.dumps({'alias': 'demo', 'secret': SENTINEL})
            query.side_effect = [[{'Id': '001000000000001AAA'}],
                                 [{'contacts': 10, 'email_present': 9, 'linked_contacts': 10}], []]
            result = mcp.dispatch(request())['result']
            self.assertFalse(result['isError'])
            self.assertEqual(json.loads(result['content'][0]['text']), result['structuredContent'])
            self.assertEqual(result['structuredContent']['metrics']['contacts'], 10)
            self.assertNotIn(SENTINEL, json.dumps(result))
            for call in query.call_args_list[1:]:
                selected = call.args[1].split(' FROM ')[0]
                self.assertNotIn('SELECT Email', selected)

    def test_organization_fixed_aggregate_scope(self):
        with patch.object(mcp, 'STATE') as state, patch.object(mcp, 'verify'), patch.object(mcp, 'query') as query:
            state.read_text.return_value = json.dumps({'alias': 'demo'})
            query.side_effect = [[{'contacts': 10, 'email_present': 9, 'linked_contacts': 8}],
                                 [{'repeated_count': 2}]]
            result = mcp.dispatch(request(arguments={'scenario': 'organization'}))['result']
            self.assertFalse(result['isError'])
            value = result['structuredContent']
            self.assertEqual(value['scope'], 'accessible_organization_records')
            self.assertEqual(value['source'], 'salesforce')
            datetime.fromisoformat(value['collected_at'])
            self.assertEqual(value['metrics']['linked_contacts'], 8)
            self.assertEqual(value['metrics']['repeated_email_rows'], 1)
            self.assertEqual(query.call_count, 2)
            queries = [call.args[1] for call in query.call_args_list]
            self.assertEqual(queries, [
                'SELECT COUNT(Id) contacts, COUNT(Email) email_present, COUNT(AccountId) linked_contacts FROM Contact',
                'SELECT COUNT(Id) repeated_count FROM Contact WHERE Email != null GROUP BY Email HAVING COUNT(Id) > 1'])
            self.assertNotIn(SENTINEL, json.dumps(result))

    def test_organization_cannot_bypass_suppression(self):
        with patch.object(mcp, 'STATE') as state, patch.object(mcp, 'verify'), patch.object(mcp, 'query') as query, patch.dict(mcp.os.environ, {'READINESS_SYNTHETIC_DEMO': '1'}):
            state.read_text.return_value = json.dumps({'alias': 'demo'})
            query.side_effect = [[{'contacts': 4, 'email_present': 4, 'linked_contacts': 4}], []]
            result = mcp.dispatch(request(arguments={'scenario': 'organization'}))['result']['structuredContent']
            self.assertTrue(result['privacy']['suppressed'])
            self.assertIsNone(result['metrics'])
            self.assertIsNone(result['data']['score'])
            self.assertEqual(result['evidence_mode'], 'live_aggregate')

    def test_capabilities_only_product_labels_and_suppressed_counts(self):
        with patch.object(mcp, 'STATE') as state, patch.object(mcp, 'verify'), patch.object(mcp, 'query') as query:
            state.read_text.return_value = json.dumps({'alias': 'demo'})
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
            with patch.object(mcp, 'STATE') as state, patch.object(mcp, 'verify'), patch.object(mcp, 'query') as query:
                state.read_text.return_value = json.dumps({'alias': 'demo'})
                query.side_effect = [[row], RuntimeError(SENTINEL), RuntimeError(SENTINEL), RuntimeError(SENTINEL), RuntimeError(SENTINEL)]
                result = mcp.dispatch(request('org_capabilities', {}))['result']['structuredContent']
                self.assertEqual(result['licenses'], [])
                self.assertEqual(result['sections']['user_licenses'], 'unavailable')
                self.assertNotIn(SENTINEL, json.dumps(result))

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
